require "test_helper"

class IntegrationsTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  # Un serveur MCP distant, comme My Semisto : whoami, une lecture et une écriture.
  class FakeServer
    attr_accessor :pending, :expired
    attr_reader :calls

    def initialize
      @calls = []
    end

    def connect(**)
      raise MCP::Client::OAuth::Flow::AuthorizationPendingError.new("pending", authorization_url: URI("https://my.semisto.test/authorize?state=s1")) if pending
      raise MCP::Client::OAuth::Flow::AuthorizationError, "invalid_grant" if expired
    end

    def instructions = "My Semisto: projects, to-dos and messages."

    def tools
      [ MCP::Client::Tool.new(name: "whoami", description: "Who am I", input_schema: { "type" => "object" }, annotations: { "readOnlyHint" => true }),
        MCP::Client::Tool.new(name: "search", description: "Search projects", input_schema: { "type" => "object", "properties" => { "q" => { "type" => "string" } } },
          annotations: { "readOnlyHint" => true }),
        MCP::Client::Tool.new(name: "api_write", description: "Create a to-do", input_schema: { "type" => "object" }, annotations: nil) ]
    end

    def call_tool(name:, arguments:)
      @calls << [ name, arguments ]
      text = case name
      when "whoami" then "Michael Hulet <m.hulet@semisto.org>, hubs: Semisto"
      when "api_write" then arguments["path"] == "/direct_uploads" ? { signed_id: "sig1", upload_url: "https://files.semisto.test/up?a=1&b=2", headers: { "Content-MD5" => "x" } }.to_json : "api_write ok"
      else "#{name} ok"
      end
      { "result" => { "content" => [ { "type" => "text", "text" => text } ], "isError" => false } }
    end
  end

  setup do
    @semisto = accounts(:semisto)
    @server = FakeServer.new
    @original = [ RemoteMcp.client_factory, RemoteMcp.finisher, AgentRun.client ]
    RemoteMcp.client_factory = ->(_connection, _provider) { @server }
    RemoteMcp.finisher = ->(connection, _provider, params) { connection.save_tokens("access_token" => "at-#{params["code"]}") }
    @calls = []
    @replies = []
    AgentRun.client = ->(**params) { @calls << params; @replies.shift || text_reply("…") }
  end

  teardown { RemoteMcp.client_factory, RemoteMcp.finisher, AgentRun.client = @original }

  test "an admin declares a tool, members cannot" do
    sign_in_as users(:mohammad)
    post integrations_path(account_id: @semisto.id), params: { integration: { name: "My Semisto", mcp_url: "https://my.semisto.test/mcp" } }
    assert_equal 0, with_account(@semisto) { Integration.count }

    sign_in_as users(:michael)
    post integrations_path(account_id: @semisto.id), params: { integration: { name: "Claudy", mcp_url: "http://claudy.test/mcp" } }
    assert_response :unprocessable_entity
    post integrations_path(account_id: @semisto.id), params: { integration: { name: "My Semisto", mcp_url: "https://my.semisto.test/mcp" } }
    assert_equal "mysemisto", with_account(@semisto) { Integration.sole.slug }

    sign_in_as users(:mohammad)
    get integrations_path(account_id: @semisto.id)
    assert_select "table.integrations th", /My Semisto/
    assert_select "button", text: "Connecter mon compte"
  end

  test "each member connects their own account, which may differ from their SG Mail address" do
    integration = create_integration
    https!
    sign_in_as users(:michael)
    @server.pending = true
    post integration_connection_path(integration, account_id: @semisto.id)
    assert_redirected_to "https://my.semisto.test/authorize?state=s1"
    connection = with_account(@semisto) { IntegrationConnection.sole }
    assert_equal "https://www.example.com/integrations/callback", connection.redirect_uri
    assert_not connection.connected?

    @server.pending = false
    get integration_callback_path(code: "c1", state: "s1")
    assert_redirected_to integrations_path(account_id: @semisto.id)
    assert_match "connecté en tant que m.hulet@semisto.org", flash[:notice]
    connection.reload
    assert connection.connected?
    assert_equal "at-c1", connection.tokens["access_token"]
    assert_equal %w[whoami search api_write], connection.tools_list.map { |t| t["name"] }
    assert_not_includes IntegrationConnection.connection.select_value("SELECT oauth FROM integration_connections"), "at-c1", "jetons chiffrés"

    get integration_callback_path(code: "c2", state: "s1")
    assert_match "expirée", flash[:alert]

    delete integration_connection_path(integration, account_id: @semisto.id)
    assert_equal 0, with_account(@semisto) { IntegrationConnection.count }
  end

  test "the agent reads in a connected tool at once and waits for confirmation before writing there" do
    connect(users(:michael))
    @semisto.update!(agent_enabled: true)
    @replies << tool_reply("toolu_1", "mysemisto__search", { "q" => "Verger" })
    @replies << tool_reply("toolu_2", "mysemisto__api_write", { "path" => "/recordings", "title" => "Rappeler Anne" })
    @replies << text_reply("C'est fait.")
    sign_in_as users(:michael)

    perform_enqueued_jobs { post agent_chats_path(account_id: @semisto.id), params: { text: "Crée une to-do dans My Semisto" } }
    names = @calls.first[:tools].map { |tool| tool[:name] }
    assert_includes names, "mysemisto__search"
    assert_includes names, "add_note"
    assert_includes @calls.first[:system_].last[:text], "signed in as m.hulet@semisto.org"
    assert_equal [ "search", { "q" => "Verger" } ], @server.calls.last

    chat = with_account(@semisto) { AgentChat.sole }
    write = with_account(@semisto) { chat.agent_actions.last }
    assert_equal [ "pending", true ], [ write.status, write.writes ]
    get agent_chat_path(chat, account_id: @semisto.id)
    assert_select ".agent-action.pending", text: /My Semisto : api write/
    assert_select ".agent-action.pending", text: /Rappeler Anne/

    perform_enqueued_jobs { patch agent_chat_agent_action_path(chat, write, account_id: @semisto.id), params: { decision: "confirm" } }
    assert_equal [ "api_write", { "path" => "/recordings", "title" => "Rappeler Anne" } ], @server.calls.last
    assert_equal "idle", chat.reload.status
  end

  test "a new discussion lists the tools: connected ones with the account, the others to connect" do
    connect(users(:michael))
    with_account(@semisto) { Integration.create!(name: "Claudy", mcp_url: "https://claudy.test/mcp") }
    @semisto.update!(agent_enabled: true)
    conversation = with_account(@semisto) do
      mailbox = Mailbox.create!(provider: "gmail", address: "admin@semisto.org")
      mailbox.grant!(users(:michael), "read")
      mailbox.messages.create!(provider_uid: "x", thread_key: "tx", subject: "Hello", from_address: "a@example.org", sent_at: 1.hour.ago, labels: %w[INBOX])
      Conversation.rebuild_for(mailbox)
      Conversation.sole
    end
    sign_in_as users(:michael)
    get conversation_path(conversation, account_id: @semisto.id)
    assert_select "#agent .agent-tools li", 3
    assert_select "#agent .agent-tools li", text: /My Semisto\s*· connecté en tant que m.hulet@semisto.org/
    assert_select "#agent .agent-tools li a[href=?]", integrations_path(account_id: @semisto.id), text: "à connecter"
  end

  test "a revoked account is reported to the agent and shown as disconnected" do
    connection = connect(users(:michael))
    @server.expired = true
    result = with_account(@semisto) { AgentToolbox.new(users(:michael)).call("mysemisto__search", { "q" => "x" }) }
    assert result["error"]
    assert_match "reconnect", result["text"]
    assert_not with_account(@semisto) { connection.reload.connected? }

    @semisto.update!(agent_enabled: true)
    sign_in_as users(:michael)
    perform_enqueued_jobs { post agent_chats_path(account_id: @semisto.id), params: { text: "Bonjour" } }
    assert_not_includes @calls.last[:tools].map { |tool| tool[:name] }, "mysemisto__search"
    assert_includes @calls.last[:system_].last[:text], "My Semisto: not connected"
  end

  test "a tool that refuses SG Mail says why" do
    integration = create_integration
    https!
    sign_in_as users(:michael)
    @server.expired = true
    post integration_connection_path(integration, account_id: @semisto.id)
    assert_redirected_to integrations_path(account_id: @semisto.id)
    assert_equal "My Semisto n'a pas accepté la connexion (invalid_grant).", flash[:alert]
  end

  test "the agent reads an attachment and, once confirmed, uploads it where a connected tool said" do
    pdf = "%PDF-1.4 facture 202611 total 450,00 EUR"
    message = with_account(@semisto) do
      mailbox = Mailbox.create!(provider: "gmail", address: "admin@semisto.org")
      mailbox.grant!(users(:michael), "send")
      message = mailbox.messages.create!(provider_uid: "f", thread_key: "tf", subject: "Facture", from_address: "amelie@example.org",
        sent_at: 1.day.ago, has_attachments: true, attachments: [ { "index" => 0, "filename" => "facture_202611.pdf", "content_type" => "application/pdf", "size" => pdf.bytesize } ])
      message.attachment_files.attach(io: StringIO.new(pdf), filename: "facture_202611.pdf", content_type: "application/pdf", metadata: { "index" => 0 })
      Conversation.rebuild_for(mailbox)
      message
    end
    connect(users(:michael))
    @semisto.update!(agent_enabled: true)
    sent = []
    original_sender = AgentAttachmentTools.sender
    AgentAttachmentTools.sender = ->(*args) { sent << args; [ 204, "" ] }
    @replies << tool_reply("toolu_1", "read_attachment", { "message_id" => message.id, "index" => 0 })
    @replies << tool_reply("toolu_2", "upload_attachment", { "message_id" => message.id, "index" => 0, "url" => "https://evil.test/x" })
    @replies << tool_reply("toolu_3", "mysemisto__api_write", { "path" => "/direct_uploads", "filename" => "facture_202611.pdf" })
    @replies << tool_reply("toolu_4", "upload_attachment", { "message_id" => message.id, "index" => 0,
      "url" => "https://files.semisto.test/up?a=1&b=2", "headers" => { "Content-MD5" => "x" } })
    @replies << text_reply("Dépense créée.")
    sign_in_as users(:michael)

    perform_enqueued_jobs { post agent_chats_path(account_id: @semisto.id), params: { text: "Crée la dépense de cette facture" } }
    result = @calls.second[:messages].last[:content].sole
    assert_equal "document", result["content"].last["type"]
    assert_equal pdf, Base64.decode64(result["content"].last.dig("source", "data"))
    assert_includes result["content"].first["text"], Digest::MD5.base64digest(pdf)
    assert_not with_account(@semisto) { AgentMessage.where("content::text LIKE ?", "%#{Base64.strict_encode64(pdf)}%").exists? }, "fichier jamais recopié"

    chat = with_account(@semisto) { AgentChat.sole }
    refused = with_account(@semisto) { chat.agent_actions.last }
    get agent_chat_path(chat, account_id: @semisto.id)
    assert_select ".agent-action.pending dd", "facture_202611.pdf"
    perform_enqueued_jobs { patch agent_chat_agent_action_path(chat, refused, account_id: @semisto.id), params: { decision: "confirm" } }
    assert_match "not given by one of the person's connected tools", refused.reload.result_text
    assert_empty sent

    with_account(@semisto) { chat.agent_actions.pending.each { |action| perform_enqueued_jobs { patch agent_chat_agent_action_path(chat, action, account_id: @semisto.id), params: { decision: "confirm" } } } }
    upload = with_account(@semisto) { chat.agent_actions.pending.sole }
    perform_enqueued_jobs { patch agent_chat_agent_action_path(chat, upload, account_id: @semisto.id), params: { decision: "confirm" } }
    assert_equal [ [ "PUT", "https://files.semisto.test/up?a=1&b=2", { "Content-MD5" => "x" }, pdf ] ], sent
    assert_equal "done", upload.reload.status
  ensure
    AgentAttachmentTools.sender = original_sender if original_sender
  end

  test "a connection belongs to one person: others do not get its tools" do
    connect(users(:michael))
    names = with_account(@semisto) { AgentToolbox.new(users(:mohammad)).definitions.map { |tool| tool[:name] } }
    assert_not_includes names, "mysemisto__search"
  end

  private

  def create_integration
    with_account(@semisto) { Integration.create!(name: "My Semisto", mcp_url: "https://my.semisto.test/mcp") }
  end

  def connect(user)
    integration = create_integration
    with_account(@semisto) do
      connection = integration.connections.create!(user: user, oauth: { "redirect_uri" => "https://sg.test/integrations/callback" })
      RemoteMcp.new(connection).refresh!
      connection
    end
  end

  def text_reply(text)
    { "content" => [ { "type" => "text", "text" => text } ], "stop_reason" => "end_turn", "usage" => { "input_tokens" => 1000, "output_tokens" => 100 } }
  end

  def tool_reply(id, name, input)
    { "content" => [ { "type" => "tool_use", "id" => id, "name" => name, "input" => input } ],
      "stop_reason" => "tool_use", "usage" => { "input_tokens" => 1000, "output_tokens" => 50 } }
  end
end
