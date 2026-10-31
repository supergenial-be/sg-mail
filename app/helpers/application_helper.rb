module ApplicationHelper
  # Couleurs des avatars et des pastilles de boîte : toujours la même pour un même nom.
  TINTS = %w[#7b4fc9 #b0603a #2f7d6d #5b5781 #a06a26 #3d6a8c #8c4a6b #4c7a57].freeze

  # Chaque espace a sa couleur (voir application.css) ; la page la reprend pour ses accents.
  SPACES = { "imbox" => "imbox", "feed" => "feed", "paper_trail" => "trail", "reply_later" => "later", "set_aside" => "aside" }.freeze

  # « À trier (3) » : le nombre d'expéditeurs qui attendent une décision dans le Screener.
  def screener_label
    count = Conversation.accessible_by(Current.user).screening_pending_for(Current.user).distinct.count(:sender_address)
    count.zero? ? "À trier" : "À trier (#{count})"
  end

  # Les fils non lus de ma réception : la pastille sur l'icône de l'app installée.
  def imbox_unread_count
    Conversation.accessible_by(Current.user).in_bucket_for(Current.user, "imbox").inbox.not_archived_for(Current.user).unread_for(Current.user).count
  end

  # Lien de navigation, marqué comme page courante quand on y est. Avec space:, une pastille de sa couleur.
  # current: force l'état courant quand l'adresse seule ne suffit pas à le dire.
  def nav_link(label, path, shortcut: nil, space: nil, current: current_page?(path))
    content = space ? safe_join([ tag.span(class: "dot", aria: { hidden: true }), label ]) : label
    link_to content, path, aria: { current: ("page" if current) }, data: { shortcut: shortcut },
      style: ("--c: var(--#{space})" if space)
  end

  # La pastille de couleur d'un client (un rond vide s'il n'en a pas, pour garder les noms alignés).
  def account_dot(account)
    palette = account.color_palette
    tag.span(class: [ "client-dot", ("none" unless palette) ], style: ("--client: #{palette[:dot]}" if palette), aria: { hidden: true })
  end

  # Les boîtes auxquelles j'ai accès, sous « Réception » dans la barre latérale.
  def sidebar_mailboxes
    @sidebar_mailboxes ||= Mailbox.accessible_by(Current.user).by_display_name.to_a
  end

  # La réception d'une seule boîte est affichée (pas une pile, pas les archives).
  def imbox_mailbox_page?(mailbox = nil)
    controller_name == "conversations" && action_name == "index" && !@stack && !@archived && @box == "imbox" &&
      (mailbox ? @mailbox == mailbox : @mailbox.nil?)
  end

  # Les fils non lus de ma réception, boîte par boîte.
  def imbox_unread_counts_by_mailbox
    @imbox_unread_counts_by_mailbox ||= Conversation.accessible_by(Current.user).in_bucket_for(Current.user, "imbox").inbox
      .not_archived_for(Current.user).unread_for(Current.user).group(:mailbox_id).count
  end

  # Une boîte sous « Réception » : son libellé (ou son adresse) et, s'il y en a, ses fils non lus.
  def mailbox_nav_link(mailbox)
    count = imbox_unread_counts_by_mailbox[mailbox.id].to_i
    content = safe_join([ tag.span(mailbox.display_name, class: "label"), (tag.span(count, class: "count", title: "#{count} non lu#{"s" if count > 1}") if count.positive?) ])
    link_to content, account_root_path(mailbox_id: mailbox.id), class: "sub", title: mailbox.address,
      aria: { current: ("page" if imbox_mailbox_page?(mailbox)) }
  end

  # Une page de liste (fils, Screener, recherche) : sur téléphone, « Écrire » y flotte en bas, à portée de pouce.
  def list_page?
    (controller_name.in?(%w[conversations screenings]) && action_name == "index") || (controller_name == "searches" && action_name == "show")
  end

  # L'espace de la page affichée, pour sa couleur : la pile ou la boîte de la liste, le Screener, sinon la réception.
  def current_space
    return "screener" if controller_name == "screenings"
    return "later" if controller_name == "focus_replies"
    return "imbox" unless controller_name == "conversations"

    key = @stack || (action_name == "show" ? @bucket : @box)
    SPACES.fetch(key.to_s, "imbox")
  end

  # Sous le titre d'un espace : à quoi il sert.
  SPACE_TAGLINES = {
    "imbox" => "Les gens qui comptent, et rien d'autre.",
    "feed" => "Lettres d'info et lectures, à parcourir quand tu as le temps.",
    "paper_trail" => "Reçus, confirmations et notifications : gardés ici, sans encombrer ta réception.",
    "reply_later" => "Les fils que tu as gardés pour y répondre. Ils quittent cette pile quand tu y réponds.",
    "set_aside" => "Les fils que tu gardes sous la main pour t'y référer.",
    "archived" => "Les fils que tu as archivés. Chacun revient dans ta réception au prochain message."
  }.freeze

  # Quand un espace est vide : une petite récompense plutôt qu'un « Rien ici ».
  SPACE_EMPTY_LINES = {
    "imbox" => "Ta réception est vide. Belle journée.",
    "feed" => "Plus rien à lire. Va voir dehors.",
    "paper_trail" => "Aucun reçu, aucune notification.",
    "reply_later" => "Aucune promesse en attente.",
    "set_aside" => "Rien de côté pour l'instant.",
    "archived" => "Rien d'archivé pour l'instant."
  }.freeze

  def space_tagline(key) = SPACE_TAGLINES.fetch(key.to_s, SPACE_TAGLINES["imbox"])
  def space_empty_line(key) = SPACE_EMPTY_LINES.fetch(key.to_s, "Rien ici.")

  def tint_for(text)
    TINTS[text.to_s.downcase.sum % TINTS.size]
  end

  # La date d'un fil dans une liste, au plus court : l'heure aujourd'hui, « hier », le jour cette année, sinon la date.
  def list_time(time)
    return unless time

    time = time.in_time_zone
    today = Time.zone.today
    label = if time.to_date == today then l(time, format: "%-Hh%M")
    elsif time.to_date == today.yesterday then "hier"
    elsif time.year == today.year then l(time, format: "%-d %b")
    else l(time.to_date, format: "%d/%m/%Y")
    end
    tag.time(label, datetime: time.iso8601, title: l(time, format: :long))
  end

  # Un rond aux initiales, à la couleur du nom.
  def avatar(name, size: nil)
    initials = name.to_s.scan(/[[:alpha:]]+/).first(2).map { |word| word[0] }.join.upcase
    tag.span(initials.presence || "?", class: [ "avatar", size ], style: "--av: #{tint_for(name)}", aria: { hidden: true })
  end

  # L'agent de la personne : son image si elle en a choisi une, sinon son initiale dans sa couleur.
  def agent_avatar(agent, size: nil)
    if agent.persisted? && agent.avatar.attached? && agent.avatar.blob.persisted?
      return image_tag(avatar_agent_path(v: agent.avatar.blob.checksum), alt: "", class: [ "agent-avatar", "photo", size ],
        style: "--agent: var(--#{agent.color})", aria: { hidden: true })
    end

    tag.span(agent.initial, class: [ "agent-avatar", size ], style: "--agent: var(--#{agent.color})", aria: { hidden: true })
  end

  AGENT_FIELD_LABELS = {
    "title" => "Titre", "body" => "Texte", "subject" => "Objet", "to" => "À", "cc" => "Cc", "bcc" => "Cci", "kind" => "Type",
    "due_on" => "Échéance", "assignee_id" => "Pour", "conversation_id" => "Fil", "status" => "Statut", "address" => "Adresse",
    "decision" => "Décision", "box" => "Pile", "reply_later" => "Répondre plus tard", "set_aside" => "Mettre de côté",
    "archived" => "Archiver"
  }.freeze

  # Ce que l'agent veut faire, en clair : libellés en français, une personne ou un fil plutôt qu'un numéro.
  def agent_action_fields(action)
    # Un outil connecté : ses champs tels quels, l'outil seul sait ce qu'ils veulent dire.
    if AgentToolbox.remote?(action.tool_name)
      return action.input.filter_map do |key, value|
        next if value.nil? || value == ""

        [ key.to_s.humanize, value.is_a?(String) ? value : value.to_json ]
      end
    end

    return AgentAttachmentTools.fields(Current.user, action.input) if AgentAttachmentTools.handles?(action.tool_name)

    action.input.filter_map do |key, value|
      next if value.nil? || value == "" || !AGENT_FIELD_LABELS.key?(key)

      shown = case key
      when "assignee_id" then Current.account.users.find_by(id: value)&.display_name || value
      when "conversation_id" then Conversation.accessible_by(Current.user).find_by(id: value)&.title || "##{value}"
      when "reply_later", "set_aside", "archived" then value ? "oui" : "non"
      else Array(value).join(", ")
      end
      [ AGENT_FIELD_LABELS.fetch(key), shown.to_s ]
    end
  end

  # La boîte d'un fil, avec une pastille de sa couleur (tirée de l'adresse : elle ne change pas avec le libellé).
  def mailbox_chip(mailbox)
    tag.span(mailbox.display_name, class: "mailbox-chip", style: "--mb: #{tint_for(mailbox.address)}",
      title: (mailbox.address if mailbox.label))
  end

  # Les options d'un menu de boîtes : leur libellé (ou leur adresse).
  def mailbox_options(mailboxes, with_address: false)
    mailboxes.map { |mailbox| [ with_address ? mailbox.display_name_with_address : mailbox.display_name, mailbox.id ] }
  end
end
