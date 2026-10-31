# Un fil de discussion dans une boîte : les messages qui partagent la même clé de fil
# (threadId Gmail, ou premier Message-ID des References en IMAP).
class Conversation < ApplicationRecord
  acts_as_tenant :account
  belongs_to :mailbox
  belongs_to :assignee, class_name: "User", optional: true
  has_many :messages, -> { order(:sent_at, :id) }, dependent: :nullify
  has_many :notes, -> { order(:created_at) }, dependent: :delete_all
  has_many :states, class_name: "ConversationState", dependent: :delete_all

  scope :recent, -> { order(last_message_at: :desc, id: :desc) }
  scope :accessible_by, ->(user) { where(mailbox: Mailbox.accessible_by(user)) }
  scope :inbox, -> { where(in_inbox: true) }
  scope :assigned_to, ->(user) { where(assignee: user) }

  # Les fils d'une pile (imbox, feed, paper_trail) pour une personne : ceux des expéditeurs qu'elle y a
  # rangés. Un fil ouvert par la boîte elle-même va dans la réception.
  scope :in_bucket_for, ->(user, bucket = "imbox") {
    accepted = where(<<~SQL.squish, user.id, bucket)
      EXISTS (SELECT 1 FROM screenings WHERE screenings.user_id = ? AND screenings.address = conversations.sender_address
        AND screenings.decision = 'accepted' AND screenings.bucket = ?)
    SQL
    bucket == "imbox" ? where(sender_address: nil).or(accepted) : accepted
  }
  # Reply Later / Set Aside : les fils qu'une personne a mis dans cette pile, ou ceux qu'elle n'a mis dans aucune.
  scope :in_stack_for, ->(user, stack) {
    column = ConversationState::COLUMNS.fetch(stack) { raise ArgumentError, "pile : reply_later ou set_aside" }
    where(id: ConversationState.where(user: user).where.not(column => nil).select(:conversation_id))
  }
  scope :outside_stacks_for, ->(user) {
    where.not(id: ConversationState.where(user: user).where("reply_later_at IS NOT NULL OR set_aside_at IS NOT NULL").select(:conversation_id))
      .not_archived_for(user)
  }

  # Archivés par cette personne, et sans message arrivé depuis.
  ARCHIVED_SQL = <<~SQL.squish
    EXISTS (SELECT 1 FROM conversation_states WHERE conversation_states.conversation_id = conversations.id
      AND conversation_states.user_id = ? AND conversation_states.archived_at IS NOT NULL
      AND (conversations.last_message_at IS NULL OR conversation_states.archived_at >= conversations.last_message_at))
  SQL
  scope :archived_for, ->(user) { where(ARCHIVED_SQL, user.id) }
  scope :not_archived_for, ->(user) { where("NOT #{ARCHIVED_SQL}", user.id) }

  # Screener : un fil qui attend la décision de la personne.
  scope :screening_pending_for, ->(user) {
    where(<<~SQL.squish, user.id)
      conversations.sender_address IS NOT NULL AND NOT EXISTS (SELECT 1 FROM screenings WHERE screenings.user_id = ?
        AND screenings.address = conversations.sender_address)
    SQL
  }

  # Ajoute les colonnes « screening » (accepted, blocked, pending, ou nil pour un fil ouvert par la boîte)
  # et « bucket » (la pile d'un expéditeur accepté ; imbox pour un fil ouvert par la boîte).
  scope :with_screening_for, ->(user) {
    select("conversations.*", sanitize_sql_array([ <<~SQL.squish, user.id, user.id ]))
      CASE WHEN conversations.sender_address IS NULL THEN NULL ELSE COALESCE((SELECT screenings.decision FROM screenings
        WHERE screenings.user_id = ? AND screenings.address = conversations.sender_address), 'pending') END AS screening,
      CASE WHEN conversations.sender_address IS NULL THEN 'imbox' ELSE (SELECT screenings.bucket FROM screenings
        WHERE screenings.user_id = ? AND screenings.address = conversations.sender_address
        AND screenings.decision = 'accepted') END AS bucket
    SQL
  }

  # Ajoute la colonne « unread » : reste-t-il un message que cette personne n'a pas lu ?
  scope :with_unread_for, ->(user) {
    select(sanitize_sql_array([ <<~SQL.squish, user.id ]))
      conversations.*, EXISTS (
        SELECT 1 FROM messages WHERE messages.conversation_id = conversations.id
        AND NOT EXISTS (SELECT 1 FROM readings WHERE readings.message_id = messages.id AND readings.user_id = ?)
      ) AS unread
    SQL
  }

  scope :unread_for, ->(user) {
    where(<<~SQL.squish, user.id)
      EXISTS (SELECT 1 FROM messages WHERE messages.conversation_id = conversations.id
        AND NOT EXISTS (SELECT 1 FROM readings WHERE readings.message_id = messages.id AND readings.user_id = ?))
    SQL
  }

  # Le Screener d'une personne : un fil par expéditeur en attente (le plus récent), avec le nombre
  # de ses fils (colonne « sender_conversations_count »), les plus récents d'abord.
  def self.screener_for(user, limit: 200)
    latest = accessible_by(user).screening_pending_for(user)
      .select("DISTINCT ON (conversations.sender_address) conversations.*",
        "count(*) OVER (PARTITION BY conversations.sender_address) AS sender_conversations_count")
      .order("conversations.sender_address", last_message_at: :desc, id: :desc)
    from(latest, :conversations).includes(:mailbox, :states).order(last_message_at: :desc, id: :desc).limit(limit)
  end

  # Recalcule les fils d'une boîte après une synchro : un INSERT … ON CONFLICT et deux requêtes,
  # quel que soit le nombre de messages. Puis le Screener accepte d'office les expéditeurs connus
  # (voir Screening.accept_known_senders!) ; `since` limite ce travail aux messages récents.
  def self.rebuild_for(mailbox, since: nil)
    key = "COALESCE(messages.thread_key, 'uid:' || messages.provider_uid)"
    inbound = sanitize_sql_array([ "messages.from_address IS NOT NULL AND lower(messages.from_address) <> ?", mailbox.address.downcase ])
    connection.execute(sanitize_sql_array([ <<~SQL, mailbox.id ]))
      INSERT INTO conversations (account_id, mailbox_id, thread_key, subject, last_sender, snippet,
        last_message_at, messages_count, in_inbox, sender_address, sender_name, root_message_id, created_at, updated_at)
      SELECT messages.account_id, messages.mailbox_id, #{key},
        (array_agg(messages.subject ORDER BY messages.sent_at NULLS LAST, messages.id))[1],
        (array_agg(COALESCE(NULLIF(messages.from_name, ''), messages.from_address) ORDER BY messages.sent_at DESC NULLS LAST, messages.id DESC))[1],
        (array_agg(messages.snippet ORDER BY messages.sent_at DESC NULLS LAST, messages.id DESC))[1],
        max(messages.sent_at), count(*),
        bool_or(messages.labels @> '["INBOX"]' OR COALESCE(mail_folders.name = 'INBOX', false)),
        (array_agg(lower(messages.from_address) ORDER BY messages.sent_at NULLS LAST, messages.id) FILTER (WHERE #{inbound}))[1],
        (array_agg(NULLIF(messages.from_name, '') ORDER BY messages.sent_at NULLS LAST, messages.id) FILTER (WHERE #{inbound}))[1],
        (array_agg(messages.message_id_header ORDER BY messages.sent_at NULLS LAST, messages.id) FILTER (WHERE messages.message_id_header IS NOT NULL))[1],
        now(), now()
      FROM messages LEFT JOIN mail_folders ON mail_folders.id = messages.mail_folder_id
      WHERE messages.mailbox_id = ?
      GROUP BY messages.account_id, messages.mailbox_id, #{key}
      ON CONFLICT (mailbox_id, thread_key) DO UPDATE SET
        subject = EXCLUDED.subject, last_sender = EXCLUDED.last_sender, snippet = EXCLUDED.snippet,
        last_message_at = EXCLUDED.last_message_at, messages_count = EXCLUDED.messages_count,
        in_inbox = EXCLUDED.in_inbox, sender_address = EXCLUDED.sender_address, sender_name = EXCLUDED.sender_name,
        root_message_id = EXCLUDED.root_message_id, updated_at = now()
      WHERE (conversations.last_message_at, conversations.messages_count, conversations.in_inbox, conversations.sender_address, conversations.root_message_id)
        IS DISTINCT FROM (EXCLUDED.last_message_at, EXCLUDED.messages_count, EXCLUDED.in_inbox, EXCLUDED.sender_address, EXCLUDED.root_message_id)
    SQL
    connection.execute(sanitize_sql_array([ <<~SQL, mailbox.id ]))
      UPDATE messages SET conversation_id = conversations.id
      FROM conversations
      WHERE messages.mailbox_id = ? AND conversations.mailbox_id = messages.mailbox_id
        AND conversations.thread_key = #{key}
        AND messages.conversation_id IS DISTINCT FROM conversations.id
    SQL
    where(mailbox: mailbox).where.not(id: Message.where(mailbox: mailbox).where.not(conversation_id: nil).select(:conversation_id)).delete_all
    Screening.accept_known_senders!(mailbox, since: since)
  end

  # Un même email reçu dans plusieurs boîtes (envoyé à communication@ et à michael@) donne un fil par boîte :
  # des « jumeaux », reliés par le Message-ID de leur premier message. La réception unifiée et la recherche n'en
  # montrent qu'un, le plus récent ; lu, archivé ou mis dans une pile, l'un entraîne les autres.
  TWIN_KEY = "COALESCE(conversations.root_message_id, conversations.id::text)"

  # Garde un seul fil par email parmi ceux du périmètre.
  def self.one_per_email
    representatives = all.unscope(:select, :order, :includes, :limit)
      .select("DISTINCT ON (#{TWIN_KEY}) conversations.id")
      .reorder(Arel.sql("#{TWIN_KEY}, conversations.last_message_at DESC NULLS LAST, conversations.id DESC"))
    where(id: representatives)
  end

  # Charge en une requête les jumeaux des fils d'une liste (avec leur colonne « unread »), pour afficher
  # toutes les boîtes où l'email est arrivé.
  def self.load_twins(conversations, user)
    keys = conversations.filter_map(&:root_message_id).uniq
    twins = keys.empty? ? [] : accessible_by(user).with_unread_for(user).where(root_message_id: keys).includes(:mailbox).order(:id).to_a
    by_key = twins.group_by(&:root_message_id)
    conversations.each { |conversation| conversation.twins = (by_key[conversation.root_message_id] || []).reject { |twin| twin.id == conversation.id } }
  end

  attr_writer :twins

  # Charge en une requête les pièces jointes des fils d'une liste, pour les puces sous l'aperçu : celles des
  # messages, sans les images du corps, comme Message#listed_attachments.
  # Chaque pièce est un couple [identifiant du message, pièce].
  def self.load_attachments(conversations)
    rows = Message.where(conversation_id: conversations.map(&:id))
      .joins("CROSS JOIN LATERAL jsonb_array_elements(messages.attachments) AS attachment")
      .order(:sent_at, :id)
      .pluck(:conversation_id, :id, Arel.sql("attachment"), Arel.sql("strpos(lower(COALESCE(messages.body_html, '')), 'cid:') > 0"))
      .reject { |_, _, attachment, body_has_images| Message.body_image?(attachment, body_has_images: body_has_images) }
    by_conversation = rows.group_by(&:first)
    conversations.each do |conversation|
      conversation.listed_attachments = (by_conversation[conversation.id] || []).map { |_, message_id, attachment| [ message_id, attachment ] }
    end
  end

  attr_writer :listed_attachments

  def listed_attachments = @listed_attachments || []

  # Les autres fils du même email, dans les boîtes que cette personne voit.
  def twins_for(user)
    @twins ||= root_message_id ? Conversation.accessible_by(user).where(root_message_id: root_message_id).where.not(id: id).includes(:mailbox).order(:id).to_a : []
  end

  def with_twins_for(user) = [ self, *twins_for(user) ]

  # Les boîtes où l'email est arrivé : la sienne, puis celles des jumeaux chargés.
  def mailboxes_with_twins = [ mailbox, *Array(@twins).map(&:mailbox) ].uniq

  # Non lu, ici ou dans un jumeau chargé par load_twins.
  def unread_anywhere? = (has_attribute?(:unread) && self[:unread]) || Array(@twins).any? { |twin| twin.has_attribute?(:unread) && twin[:unread] }

  def title = subject.presence || "(sans objet)"

  def sender_display = sender_name.presence || sender_address

  # accepted, blocked, pending, ou nil pour un fil ouvert par la boîte elle-même.
  def screening_for(user)
    return self[:screening] if has_attribute?(:screening)
    return unless sender_address

    screening_record_for(user)&.decision || "pending"
  end

  # Les piles où cette personne a mis le fil : [] , ["reply_later"], ["set_aside"] ou les deux.
  def stacks_for(user)
    state = states.find { |s| s.user_id == user.id }
    ConversationState::COLUMNS.filter_map { |stack, column| stack if state&.public_send(column) }
  end

  # Archive le fil et ses jumeaux pour cette personne (ou les remet dans sa réception), et le reporte chez le fournisseur.
  def archive_for!(user, on: true)
    with_twins_for(user).each do |conversation|
      ConversationState.archive!(conversation, user, on: on)
      conversation.states.reset
      ProviderArchiveJob.perform_later(conversation, archive: on) if conversation.mailbox.gmail?
    end
  end

  # Met le fil et ses jumeaux dans une pile personnelle (on: true), ou les en retire.
  def put_in_stack_for!(user, stack, on: true)
    with_twins_for(user).each { |conversation| ConversationState.put!(conversation, user, stack, on: on) }
    states.reset
  end

  def archived_for?(user) = states.find { |s| s.user_id == user.id }&.archived?(self) || false

  # Tout le monde a archivé le fil : on peut aussi le sortir de la réception chez le fournisseur.
  def archived_by_everyone?
    people = mailbox.users_with_access.pluck(:id)
    people.any? && ConversationState.where(conversation: self, user_id: people).to_a.count { |state| state.archived?(self) } == people.size
  end

  # imbox, feed ou paper_trail ; nil tant que l'expéditeur n'est pas accepté.
  def bucket_for(user)
    return self[:bucket] if has_attribute?(:bucket)
    return "imbox" unless sender_address

    screening = screening_record_for(user)
    screening.bucket if screening&.decision == "accepted"
  end

  def mark_read_by!(user) = Reading.mark!(user, messages)

  def mark_unread_by!(user)
    with_twins_for(user).each do |conversation|
      Reading.where(user: user, message_id: conversation.messages.reorder(sent_at: :desc, id: :desc).limit(1).select(:id)).delete_all
    end
  end

  private

  def screening_record_for(user)
    @screening_records ||= {}
    @screening_records.fetch(user.id) { @screening_records[user.id] = Screening.find_by(user: user, address: sender_address) }
  end
end
