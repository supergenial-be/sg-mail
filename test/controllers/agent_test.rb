require "test_helper"

class AgentTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @semisto = accounts(:semisto)
    with_account(@semisto) do
      @mailbox = Mailbox.create!(provider: "gmail", address: "formations@semisto.org")
      @mailbox.grant!(users(:michael), "send")
      @mailbox.grant!(users(:mohammad), "send")
      @message = @mailbox.messages.create!(provider_uid: "a", thread_key: "t1", subject: "Inscription",
        from_address: "anne@example.org", sent_at: 1.day.ago, body_text: "Bonjour, reste-t-il une place ?", labels: %w[INBOX])
      Conversation.rebuild_for(@mailbox)
      @conversation = @message.reload.conversation
    end
    @calls = []
    @replies = []
    @original_client = AgentRun.client
    AgentRun.client = ->(**params) { @calls << params; @replies.shift || text_reply("…") }
  end

  teardown { AgentRun.client = @original_client }

  test "the agent is off until an admin turns it on for the client" do
    sign_in_as users(:michael)
    get conversation_path(@conversation, account_id: @semisto.id)
    assert_select "#agent", 0
    get agent_chats_path(account_id: @semisto.id)
    assert_redirected_to agent_settings_path(account_id: @semisto.id)

    sign_in_as users(:mohammad)
    patch agent_settings_path(account_id: @semisto.id), params: { account: { agent_enabled: "1" } }
    assert_not @semisto.reload.agent_enabled?

    sign_in_as users(:michael)
    patch agent_settings_path(account_id: @semisto.id), params: { account: { agent_enabled: "1", agent_monthly_budget: "35" } }
    assert @semisto.reload.agent_enabled?
    assert_equal 3500, @semisto.agent_monthly_budget_cents
    get conversation_path(@conversation, account_id: @semisto.id)
    assert_select "#agent h2", "Plume"
  end

  test "each person names and colours their own agent" do
    sign_in_as users(:michael)
    patch agent_path(account_id: @semisto.id), params: { agent: { name: "Sève", color: "feed", style: "warm", instructions: "Signe « Michael »." } }
    agent = Agent.find_by!(user: users(:michael))
    assert_equal %w[Sève feed warm], [ agent.name, agent.color, agent.style ]
    assert_includes AgentPrompt.persona(agent), "Signe « Michael »."

    patch agent_path(account_id: @semisto.id), params: { agent: { name: "", color: "pink" } }
    assert_response :unprocessable_entity
    assert_equal "Plume", Agent.for(users(:mohammad)).name
  end

  test "each person can give their agent an image, only served to them" do
    enable_agent
    sign_in_as users(:michael)
    svg = Rack::Test::UploadedFile.new(StringIO.new(+'<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>'), "image/svg+xml", original_filename: "a.svg")
    patch agent_path(account_id: @semisto.id), params: { agent: { name: "Plume", avatar: svg } }
    assert_response :unprocessable_entity

    patch agent_path(account_id: @semisto.id), params: { agent: { name: "Plume", avatar: fixture_file_upload("pixel.png", "image/png") } }
    agent = Agent.find_by!(user: users(:michael))
    assert agent.avatar.attached?
    get agent_settings_path(account_id: @semisto.id)
    assert_select "img.agent-avatar.photo[src^=?]", avatar_agent_path(account_id: @semisto.id)
    get conversation_path(@conversation, account_id: @semisto.id)
    assert_select "#agent img.agent-avatar.photo"

    get avatar_agent_path(account_id: @semisto.id)
    assert_equal [ "image/png", "nosniff" ], [ response.media_type, response.headers["X-Content-Type-Options"] ]
    sign_in_as users(:mohammad)
    get avatar_agent_path(account_id: @semisto.id)
    assert_response :not_found

    sign_in_as users(:michael)
    patch agent_path(account_id: @semisto.id), params: { agent: { name: "Plume", remove_avatar: "1" } }
    assert_not agent.reload.avatar.attached?
    get agent_settings_path(account_id: @semisto.id)
    assert_select "span.agent-avatar", "P"
  end

  test "reads run at once, writes wait for confirmation, then the agent carries on" do
    enable_agent
    @replies << tool_reply("toolu_1", "get_conversation", { "id" => @conversation.id })
    @replies << tool_reply("toolu_2", "add_note", { "conversation_id" => @conversation.id, "body" => "Répondre à Anne" })
    @replies << text_reply("C'est noté, **la note est ajoutée**.\n\n- <b>Anne</b> attend")
    sign_in_as users(:michael)

    perform_enqueued_jobs do
      post agent_chats_path(account_id: @semisto.id), params: { conversation_id: @conversation.id, prompt: "Que suggères-tu ?" }
    end
    assert_redirected_to conversation_path(@conversation, account_id: @semisto.id, anchor: "agent")
    chat = with_account(@semisto) { AgentChat.sole }
    assert chat.waiting?
    read, write = with_account(@semisto) { chat.agent_actions.to_a }
    assert_equal [ "done", false ], [ read.status, read.writes ]
    assert_includes read.result_text, "reste-t-il une place"
    assert_equal [ "pending", true ], [ write.status, write.writes ]
    assert_equal 0, with_account(@semisto) { Note.count }
    assert_includes @calls.first[:system_].last[:text], "##{@conversation.id}"
    assert_not_includes @calls.first[:tools].map { |tool| tool[:name] }, "send_draft"

    get conversation_path(@conversation, account_id: @semisto.id)
    assert_select "#agent .agent-action.pending", text: /Ajouter une note interne/
    assert_select ".agent-dock[data-controller=agent-drawer] button.agent-launcher.waiting[data-shortcut='.']"
    assert_select "aside#agent.agent-drawer .agent-drawer-body .agent-transcript"

    perform_enqueued_jobs do
      patch agent_chat_agent_action_path(chat, write, account_id: @semisto.id), params: { decision: "confirm", from_conversation: "1" }
    end
    assert_equal "Répondre à Anne", with_account(@semisto) { Note.sole.body }
    assert_equal "idle", chat.reload.status
    results = @calls.last[:messages].select { |message| message[:role] == "user" }.drop(1).map { |message| message[:content].sole }
    assert_equal [ "toolu_1", "toolu_2" ], results.map { |block| block["tool_use_id"] }
    assert results.none? { |block| block["is_error"] }
    replayed = @calls.last[:messages].select { |message| message[:role] == "assistant" }.flat_map { |message| message[:content] }
    assert_equal [ %w[text type], %w[id input name type] ], replayed.map(&:keys).map(&:sort).uniq

    get agent_chat_path(chat, account_id: @semisto.id)
    assert_select ".bubble.agent", text: /la note est ajoutée/
    assert_select ".bubble.agent strong", "la note est ajoutée"
    assert_select ".bubble.agent li", "<b>Anne</b> attend"
    assert_select "details.agent-action.done:not([open])", text: /Ajouter une note interne/
    assert with_account(@semisto) { AccessLog.exists?(conversation: @conversation, via: "agent") }
  end

  test "a declined action never runs and the agent is told" do
    enable_agent
    @replies << tool_reply("toolu_1", "add_note", { "conversation_id" => @conversation.id, "body" => "Complet" })
    @replies << text_reply("D'accord, je n'ajoute rien.")
    sign_in_as users(:michael)
    perform_enqueued_jobs { post agent_chats_path(account_id: @semisto.id), params: { text: "Note que c'est complet" } }
    chat = with_account(@semisto) { AgentChat.sole }
    action = with_account(@semisto) { chat.agent_actions.sole }

    perform_enqueued_jobs { patch agent_chat_agent_action_path(chat, action, account_id: @semisto.id), params: { decision: "reject" } }
    assert_redirected_to agent_chat_path(chat, account_id: @semisto.id)
    assert_equal 0, with_account(@semisto) { Note.count }
    assert @calls.last[:messages].last[:content].sole["is_error"]
    assert_equal "rejected", with_account(@semisto) { action.reload.status }
  end

  test "the agent stops at the client's monthly budget" do
    enable_agent(budget_cents: 1)
    with_account(@semisto) do
      chat = AgentChat.create!(user: users(:mohammad))
      chat.agent_messages.create!(role: "assistant", content: [], cost_micros: 20_000)
    end
    sign_in_as users(:michael)
    perform_enqueued_jobs { post agent_chats_path(account_id: @semisto.id), params: { text: "Bonjour" } }
    assert_empty @calls
    chat = with_account(@semisto) { AgentChat.find_by!(user: users(:michael)) }
    assert_includes with_account(@semisto) { chat.agent_messages.last.text }, "plafond mensuel"
  end

  test "a failed call leaves the chat usable" do
    enable_agent
    AgentRun.client = ->(**) { raise Timeout::Error }
    sign_in_as users(:michael)
    perform_enqueued_jobs { post agent_chats_path(account_id: @semisto.id), params: { text: "Bonjour" } }
    chat = with_account(@semisto) { AgentChat.sole }
    assert_equal "failed", chat.status

    error = Anthropic::Errors::BadRequestError.new(url: URI("https://api.anthropic.com/v1/messages"), status: 400, headers: {}, request: nil, response: nil,
      body: { type: "error", error: { type: "invalid_request_error", message: "Your credit balance is too low." } })
    assert_includes AgentRun.failure_message(error), "credit balance is too low"

    AgentRun.client = ->(**params) { @calls << params; text_reply("Me revoilà.") }
    perform_enqueued_jobs { post agent_chat_agent_messages_path(chat, account_id: @semisto.id), params: { text: "Tu es là ?" } }
    assert_equal "idle", chat.reload.status
  end

  test "chats stay private to their author" do
    enable_agent
    chat = with_account(@semisto) { AgentChat.create!(user: users(:michael), title: "Privé") }
    sign_in_as users(:mohammad)
    get agent_chat_path(chat, account_id: @semisto.id)
    assert_response :not_found
  end

  test "chats are erased after 90 days without activity" do
    with_account(@semisto) do
      old = AgentChat.create!(user: users(:michael), updated_at: 91.days.ago)
      AgentChat.create!(user: users(:michael))
      PurgeAgentChatsJob.perform_now
      assert_not AgentChat.exists?(old.id)
      assert_equal 1, AgentChat.count
    end
  end

  private

  def enable_agent(budget_cents: 2000)
    @semisto.update!(agent_enabled: true, agent_monthly_budget_cents: budget_cents)
  end

  def text_reply(text)
    { "content" => [ { "type" => "text", "text" => text } ], "stop_reason" => "end_turn", "usage" => { "input_tokens" => 1000, "output_tokens" => 100 } }
  end

  # Comme une vraie réponse : des champs en lecture seule que l'API refuse qu'on lui renvoie.
  def tool_reply(id, name, input)
    { "content" => [ { "type" => "text", "text" => "Je regarde.", "citations" => nil },
                     { "type" => "tool_use", "id" => id, "name" => name, "input" => input, "caller_" => { "type" => "direct" } } ],
      "stop_reason" => "tool_use", "usage" => { "input_tokens" => 1000, "output_tokens" => 50 } }
  end
end
