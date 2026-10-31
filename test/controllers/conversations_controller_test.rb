require "test_helper"

class ConversationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @semisto = accounts(:semisto)
    with_account(@semisto) do
      @shared = Mailbox.create!(provider: "gmail", address: "formations@semisto.org")
      @shared.grant!(users(:michael), "manage")
      @shared.grant!(users(:mohammad), "send")
      @first = @shared.messages.create!(provider_uid: "a", thread_key: "t1", sent_at: 2.days.ago, subject: "Inscription", from_name: "Anne", labels: %w[INBOX], body_text: "Bonjour")
      @second = @shared.messages.create!(provider_uid: "b", thread_key: "t1", sent_at: 1.day.ago, subject: "Re: Inscription", from_name: "Mohammad", labels: %w[SENT])
      @archived = @shared.messages.create!(provider_uid: "c", thread_key: "t2", sent_at: 1.day.ago, subject: "Ancien", labels: [])
      Conversation.rebuild_for(@shared)
      @conversation = @first.reload.conversation
    end
  end

  def path(**params) = conversations_path(account_id: @semisto.id, **params)

  test "the unified inbox shows inbox threads, unread in bold" do
    sign_in_as users(:mohammad)
    with_restricted_database_role do
      get account_root_path(account_id: @semisto.id)
      assert_response :success
      assert_select "tr.unread a", "Inscription"
      assert_select "a", { text: "Ancien", count: 0 }

      get path(mailbox_id: @shared.id)
      assert_select "tr.unread a", "Inscription"
      assert_select "a", { text: "Ancien", count: 0 }
    end
  end

  test "opening a thread marks it read for me only, and shows who read each message" do
    sign_in_as users(:mohammad)
    with_restricted_database_role do
      get conversation_path(@conversation, account_id: @semisto.id)
      assert_response :success
      assert_select "p.read-by", text: /Lu par Mohammad · pas encore par Michael/, count: 2

      get path
      assert_select "tr.unread", count: 0
    end

    sign_in_as users(:michael)
    get path
    assert_select "tr.unread a", "Inscription"
  end

  test "mark as unread, then unread filter" do
    sign_in_as users(:mohammad)
    get conversation_path(@conversation, account_id: @semisto.id)
    get path(unread: 1)
    assert_select "a", { text: "Inscription", count: 0 }

    post unread_conversation_path(@conversation, account_id: @semisto.id)
    get path(unread: 1)
    assert_select "tr.unread a", "Inscription"
  end

  test "mark everything as read" do
    sign_in_as users(:mohammad)
    post mark_all_read_conversations_path(account_id: @semisto.id)
    get path(mailbox_id: @shared.id)
    assert_select "tr.unread", count: 0
  end

  test "threads of a mailbox one cannot access stay hidden" do
    with_account(@semisto) { @shared.accesses.where(user: users(:mohammad)).delete_all }
    sign_in_as users(:mohammad)
    get path
    assert_select "a", { text: "Inscription", count: 0 }
    get conversation_path(@conversation, account_id: @semisto.id)
    assert_response :not_found
  end

  test "the sidebar lists each mailbox under Réception, with its unread count" do
    with_account(@semisto) do
      personal = Mailbox.create!(provider: "imap", address: "mohammad@semisto.org")
      personal.grant!(users(:mohammad), "manage")
      hidden = Mailbox.create!(provider: "imap", address: "secret@semisto.org")
      hidden.grant!(users(:michael), "manage")
    end
    sign_in_as users(:mohammad)

    get account_root_path(account_id: @semisto.id)
    assert_select "nav.spaces a[aria-current=page]", text: "Réception"
    assert_select ".sub-spaces a.sub", count: 2
    assert_select ".sub-spaces a.sub[href=?]", account_root_path(account_id: @semisto.id, mailbox_id: @shared.id) do
      assert_select ".label", "formations@semisto.org"
      assert_select ".count", "1"
    end
    assert_select ".sub-spaces a.sub", { text: /mohammad@semisto.org/ } do
      assert_select ".count", count: 0
    end
    assert_select ".sub-spaces a", { text: /secret@/, count: 0 }

    get account_root_path(account_id: @semisto.id, mailbox_id: @shared.id)
    assert_select "nav.spaces a[aria-current=page]", count: 1
    assert_select ".sub-spaces a.sub[aria-current=page] .label", "formations@semisto.org"
  end

  test "with a single mailbox, no sub-items under Réception" do
    sign_in_as users(:mohammad)
    get path
    assert_select ".sub-spaces", count: 0
  end

  test "a thread shows its attachments as chips, without the images of the body, two at most then +N" do
    with_account(@semisto) do
      @second.update!(body_html: %(<p><img src="cid:logo@sg"></p>), attachments: [
        { "index" => 0, "filename" => "logo.png", "content_type" => "image/png", "content_id" => "logo@sg" },
        { "index" => 1, "filename" => "programme.pdf", "content_type" => "application/pdf" },
        { "index" => 2, "filename" => "photo.jpg", "content_type" => "image/jpeg", "size" => 2_000_000, "inline" => false },
        { "index" => 4, "filename" => "instagram.jpg", "content_type" => "image/jpeg", "content_id" => "quoted@sg", "inline" => true },
        { "index" => 3, "filename" => "budget.xlsx", "content_type" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }
      ])
    end
    sign_in_as users(:mohammad)
    with_restricted_database_role do
      get path
      assert_response :success
      assert_select "td.files a.file-chip", 2
      assert_select "td.files a.file-chip[data-family=pdf][data-viewer-kind=pdf][data-viewer-group=?]", @conversation.id.to_s, text: /programme\.pdf/
      assert_select "td.files a.file-chip[data-viewer-kind=image]", text: /photo\.jpg/
      assert_select "td.files .file-more", "+1"
      assert_select "td.files", text: /logo\.png|instagram\.jpg/, count: 0
      assert_select "dialog.viewer", 1
    end
  end

  test "the list shows short dates, filters behind a button and a floating compose button" do
    sign_in_as users(:mohammad)
    get path
    assert_select "td.date time", "hier"
    assert_select ".filter-bar:not(.open) button.filter-toggle[aria-expanded=false]", text: /Filtrer/
    assert_select "a.compose-button.floating", text: /Écrire/

    get path(unread: 1)
    assert_select ".filter-bar.open .filter-count", "1"

    get conversation_path(@conversation, account_id: @semisto.id)
    assert_select "a.compose-button:not(.floating)"
  end
end
