require "test_helper"

# Glisser du doigt, palette ⌘K, « Répondre à la suite » et « Nouveaux messages / Déjà vu ».
class InboxFlowTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @semisto = accounts(:semisto)
    with_account(@semisto) do
      @shared = Mailbox.create!(provider: "gmail", address: "formations@semisto.org")
      @shared.grant!(users(:michael), "manage")
      @shared.messages.create!(provider_uid: "a", thread_key: "t1", from_address: "anne@example.org", from_name: "Anne",
        to_addresses: [ "formations@semisto.org" ], subject: "Inscription", body_text: "Reste-t-il une place ?",
        sent_at: 2.days.ago, labels: %w[INBOX])
      @shared.messages.create!(provider_uid: "b", thread_key: "t2", from_address: "paul@example.org", from_name: "Paul",
        to_addresses: [ "formations@semisto.org" ], subject: "Facture", body_text: "Voici la facture.",
        sent_at: 1.day.ago, labels: %w[INBOX])
      Conversation.rebuild_for(@shared)
      @inscription = Conversation.find_by!(thread_key: "t1")
      @facture = Conversation.find_by!(thread_key: "t2")
      @question = @inscription.messages.first
    end
    sign_in_as users(:michael)
  end

  test "rows of the inbox can be swiped, rows of the archive cannot" do
    get account_root_path(account_id: @semisto.id)
    assert_select "tr[data-controller=swipe][data-swipe-archive-url-value='#{archive_conversation_path(@inscription, account_id: @semisto.id)}']"
    assert_select "tr[data-swipe-later-url-value='#{stack_conversation_path(@inscription, account_id: @semisto.id)}']"

    get conversations_path(account_id: @semisto.id, stack: "reply_later")
    assert_select "tr[data-controller=swipe]", count: 0 # rien dans la pile

    patch archive_conversation_path(@inscription, account_id: @semisto.id), params: { on: "1" }
    get conversations_path(account_id: @semisto.id, archived: 1)
    assert_select "table a", "Inscription"
    assert_select "tr[data-controller=swipe]", count: 0
  end

  test "on a phone, spaces and mailboxes sit behind the menu button, and Filtrer beside the space title" do
    get account_root_path(account_id: @semisto.id)
    assert_select "aside.sidebar[data-controller=toggle] button.menu-toggle[aria-controls=spaces-menu][aria-expanded=false]"
    assert_select "#spaces-menu.drawer nav.spaces a", "Feed"
    assert_select ".drawer-backdrop[data-action=\"click->toggle#close\"]"
    assert_select ".space-top .space-head h1", "Réception"
    assert_select ".space-top .filter-bar button.filter-toggle"
  end

  test "the palette is on every page of an account, with its extra entries" do
    get account_root_path(account_id: @semisto.id)
    assert_select "dialog.palette input[data-palette-target=input]"
    assert_select "[data-controller=palette][data-palette-search-url-value='#{search_path(account_id: @semisto.id)}']"
    assert_select "dialog.palette a[data-palette-target=extra]", "Répondre à la suite"
  end

  test "the inbox shows what is new first, then what I have already seen" do
    memberships(:michael_semisto).update_columns(imbox_seen_at: 3.days.ago)
    get conversation_path(@facture, account_id: @semisto.id) # lu
    get account_root_path(account_id: @semisto.id)
    assert_select "h2.list-section", 2
    assert_select "h2.list-section:not(.seen)", "Nouveaux messages"
    assert_select "h2.list-section:not(.seen) + table a", "Inscription"
    assert_select "h2.list-section.seen + table a", "Facture"

    get conversation_path(@inscription, account_id: @semisto.id)
    get account_root_path(account_id: @semisto.id)
    assert_select "h2.list-section", 0
    assert_select "p.list-section-note", "Rien de nouveau depuis ta dernière visite."
    assert_select "table.conversations a", "Inscription"
  end

  test "unread threads I already saw in a previous visit are no longer new" do
    # Visite précédente il y a 36 heures : Anne (il y a 2 jours) était déjà là, Paul (il y a 1 jour) est arrivé après.
    memberships(:michael_semisto).update_columns(imbox_seen_at: 3.days.ago, imbox_visited_at: 36.hours.ago)
    get account_root_path(account_id: @semisto.id)
    assert_select "h2.list-section:not(.seen) + table a", "Facture"
    assert_select "h2.list-section.seen + table a", "Inscription"

    # Pendant la même visite, rien ne bouge ; à la visite suivante, Paul est déjà vu à son tour.
    get account_root_path(account_id: @semisto.id)
    assert_select "h2.list-section:not(.seen) + table a", "Facture"
    travel 1.hour do
      get account_root_path(account_id: @semisto.id)
      assert_select "h2.list-section", 0
      assert_select "p.list-section-note", "Rien de nouveau depuis ta dernière visite."
    end
  end

  test "reply one after the other, from the reply later stack" do
    patch stack_conversation_path(@inscription, account_id: @semisto.id), params: { stack: "reply_later", on: "1" }
    patch stack_conversation_path(@facture, account_id: @semisto.id), params: { stack: "reply_later", on: "1" }

    get conversations_path(account_id: @semisto.id, stack: "reply_later")
    assert_select "a.focus-start-link[href='#{focus_reply_path(account_id: @semisto.id)}']"

    get focus_reply_path(account_id: @semisto.id)
    assert_response :success
    assert_select "section.focus-reply", 2
    assert_select "section.focus-reply:first-of-type h2 a", "Inscription" # le plus ancien d'abord
    assert_select "section.focus-reply .focus-body", /Reste-t-il une place/
    assert_select "input[name='draft[to_list]'][value='anne@example.org']"

    assert_enqueued_with(job: SendDraftJob) do
      post drafts_path(account_id: @semisto.id), params: { focus: "1", send: "Envoyer", draft: {
        kind: "reply", mailbox_id: @shared.id, to_list: "anne@example.org", subject: "Re: Inscription",
        body: "Oui, il en reste une.", source_message_id: @question.id } }
    end
    assert_redirected_to focus_reply_path(account_id: @semisto.id)
    follow_redirect!
    assert_select "section.focus-reply", 1
    assert_select "section.focus-reply h2 a", "Facture"

    patch stack_conversation_path(@facture, account_id: @semisto.id), params: { stack: "reply_later", on: "0" }
    get focus_reply_path(account_id: @semisto.id)
    assert_select ".empty .empty-line", "Plus rien à répondre."
  end

  test "archiving from the focus page stays on it" do
    patch stack_conversation_path(@inscription, account_id: @semisto.id), params: { stack: "reply_later", on: "1" }
    patch archive_conversation_path(@inscription, account_id: @semisto.id), params: { on: "1", focus: "1" }
    assert_redirected_to focus_reply_path(account_id: @semisto.id)
  end
end
