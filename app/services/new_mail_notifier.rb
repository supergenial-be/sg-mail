# Après une synchro : prévient sur leurs appareils les personnes qui ont accès à la boîte, pour les messages
# arrivés dans leur réception. Rien pour le Feed, le Paper Trail, le Screener ni les messages envoyés depuis
# la boîte ; rien non plus pour un fil déjà lu. Au-delà de quelques messages, une seule notification les résume.
class NewMailNotifier
  # Un message importé avec du retard (première synchro, rattrapage) ne sonne pas.
  FRESHNESS = 1.day
  GROUP_ABOVE = 3

  def initialize(mailbox, since:)
    @mailbox = mailbox
    @since = since
  end

  def call
    messages = fresh_messages.to_a
    return if messages.empty?

    mailbox.users_with_access.joins(:push_subscriptions).distinct.find_each do |user|
      notify(user, messages_for(user, messages))
    end
  end

  private

  attr_reader :mailbox, :since

  def fresh_messages
    mailbox.messages.where(created_at: since..).where(sent_at: FRESHNESS.ago..).where.not(conversation_id: nil)
      .where.not("LOWER(messages.from_address) = ?", mailbox.address.downcase)
      .includes(:conversation).order(:sent_at)
  end

  def messages_for(user, messages)
    imbox = Conversation.where(id: messages.map(&:conversation_id)).in_bucket_for(user, "imbox").pluck(:id).to_set
    read = Reading.where(user: user, message_id: messages.map(&:id)).pluck(:message_id).to_set
    messages.select { |message| imbox.include?(message.conversation_id) && !read.include?(message.id) && !copy_already_arrived?(user, message) }
  end

  def notify(user, messages)
    return if messages.empty?

    notification = messages.size > GROUP_ABOVE ? grouped(messages) : nil
    deliveries = notification ? [ notification ] : messages.map { |message| single(message) }
    badge = Conversation.accessible_by(user).in_bucket_for(user, "imbox").not_archived_for(user).unread_for(user).count
    user.push_subscriptions.each do |subscription|
      deliveries.each { |delivery| break unless subscription.deliver(**delivery, badge: badge) }
    end
  end

  # Le même email envoyé à deux boîtes : la notification de la première copie suffit.
  def copy_already_arrived?(user, message)
    message.message_id_header.present? &&
      Message.where(message_id_header: message.message_id_header, mailbox_id: Mailbox.accessible_by(user).select(:id))
        .where.not(mailbox_id: mailbox.id).where(created_at: ...message.created_at).exists?
  end

  # L'expéditeur et l'objet seulement : le début du message n'apparaît pas sur l'écran verrouillé.
  def single(message)
    { title: plain(message.from_display), body: plain(message.conversation.title),
      url: routes.conversation_path(message.conversation, account_id: mailbox.account_id), tag: "conversation-#{message.conversation.root_message_id || message.conversation_id}" }
  end

  def grouped(messages)
    senders = messages.map { |message| plain(message.from_display) }.uniq
    { title: "#{messages.size} nouveaux messages", body: "De #{senders.first(4).to_sentence}#{" et d'autres" if senders.size > 4}",
      url: routes.account_root_path(account_id: mailbox.account_id), tag: "mailbox-#{mailbox.id}" }
  end

  def plain(text) = MessageParser.decode_entities(text).squish

  def routes = Rails.application.routes.url_helpers
end
