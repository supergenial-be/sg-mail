require "test_helper"

class NewMailNotifierTest < ActiveSupport::TestCase
  setup do
    ActsAsTenant.current_tenant = accounts(:semisto)
    @mailbox = Mailbox.create!(provider: "imap", address: "formations@semisto.org")
    @mailbox.grant!(users(:michael), "manage")
    @mailbox.grant!(users(:mohammad), "send")
    @michael = users(:michael)
    @phone = @michael.push_subscriptions.create!(endpoint: "https://push.example/1", p256dh: "key", auth: "secret", name: "iPhone")
    Screening.decide!(@michael, "anne@example.org", "accepted", bucket: "imbox")
    Screening.decide!(@michael, "news@example.org", "accepted", bucket: "feed")
    @sent = []
    PushSubscription.transport = ->(**options) { @sent << options.merge(payload: JSON.parse(options[:message])) }
    @since = 1.minute.ago
  end

  teardown { PushSubscription.transport = ->(**options) { WebPush.payload_send(**options) } }

  def receive(uid, from:, subject:, sent_at: Time.current)
    @mailbox.messages.create!(provider_uid: uid, thread_key: uid, from_address: from, from_name: from.split("@").first.capitalize,
      subject: subject, snippet: "Bonjour…", sent_at: sent_at)
  end

  test "rings for new mail in the inbox only, with the thread link and the unread count" do
    receive("1", from: "anne@example.org", subject: "Inscription")
    receive("2", from: "news@example.org", subject: "Lettre d'info")
    receive("3", from: "inconnu@example.org", subject: "Partenariat")
    ours = receive("4", from: "formations@semisto.org", subject: "Envoyé par nous")
    receive("5", from: "anne@example.org", subject: "Vieux message", sent_at: 3.days.ago)
    Conversation.rebuild_for(@mailbox)
    Reading.mark!(@michael, Message.where(id: ours.id))

    NewMailNotifier.new(@mailbox, since: @since).call

    assert_equal 1, @sent.size
    payload = @sent.first[:payload]
    assert_equal "Anne", payload["title"]
    assert_equal "Inscription", payload["body"]
    conversation = @mailbox.conversations.find_by!(subject: "Inscription")
    assert_equal "/#{@mailbox.account_id}/conversations/#{conversation.id}", payload["url"]
    assert_equal 2, payload["badge"]
    assert_equal "https://push.example/1", @sent.first[:endpoint]
    assert @phone.reload.last_used_at
  end

  test "groups many messages in one notification and skips what was already read" do
    5.times { |i| receive("n#{i}", from: "anne@example.org", subject: "Message #{i}") }
    Conversation.rebuild_for(@mailbox)
    NewMailNotifier.new(@mailbox, since: @since).call
    assert_equal [ "5 nouveaux messages" ], @sent.map { |sent| sent[:payload]["title"] }

    @sent.clear
    Reading.mark!(@michael, @mailbox.messages)
    NewMailNotifier.new(@mailbox, since: @since).call
    assert_empty @sent
  end

  test "rings once for an email sent to two of my mailboxes" do
    personal = Mailbox.create!(provider: "imap", address: "michael@semisto.org")
    personal.grant!(@michael, "manage")
    first = personal.messages.create!(provider_uid: "p1", thread_key: "p1", message_id_header: "same@example.org",
      from_address: "anne@example.org", subject: "Inscription", sent_at: Time.current)
    first.update_columns(created_at: 30.seconds.ago)
    Conversation.rebuild_for(personal)
    @mailbox.messages.create!(provider_uid: "1", thread_key: "1", message_id_header: "same@example.org",
      from_address: "anne@example.org", subject: "Inscription", sent_at: Time.current)
    Conversation.rebuild_for(@mailbox)

    NewMailNotifier.new(@mailbox, since: @since).call
    assert_empty @sent
  end

  test "forgets a device the push service no longer knows" do
    receive("1", from: "anne@example.org", subject: "Inscription")
    Conversation.rebuild_for(@mailbox)
    response = Struct.new(:body).new("Gone")
    PushSubscription.transport = ->(**) { raise WebPush::ExpiredSubscription.new(response, "push.example") }

    NewMailNotifier.new(@mailbox, since: @since).call

    assert_not PushSubscription.exists?(@phone.id)
  end

  test "shows only the sender and the subject, without HTML entities" do
    receive("1", from: "anne@example.org", subject: "GREENWEEKS&nbsp;jsq -60%")
    @mailbox.messages.update_all(snippet: "&nbsp;&nbsp;&nbsp;Bonjour")
    Conversation.rebuild_for(@mailbox)

    NewMailNotifier.new(@mailbox, since: @since).call

    payload = @sent.first[:payload]
    assert_equal "Anne", payload["title"]
    assert_equal "GREENWEEKS jsq -60%", payload["body"]
  end
end
