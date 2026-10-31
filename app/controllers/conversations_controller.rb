class ConversationsController < ApplicationController
  include AccountScoped
  PER_PAGE = 50

  before_action :set_conversation, only: %i[show unread assign stack archive]

  # Boîte de réception unifiée : les fils de toutes les boîtes auxquelles on a accès.
  # Une pile façon Hey : la réception (par défaut), ?box=feed ou ?box=paper_trail ;
  # ou une pile personnelle, ?stack=reply_later ou ?stack=set_aside ; ou mes fils archivés, ?archived=1.
  def index
    @archived = params[:archived] == "1"
    @stack = params[:stack].presence_in(ConversationState::STACKS)
    @box = params[:box].presence_in(Screening::BUCKETS) || "imbox"
    @mailboxes = Mailbox.accessible_by(Current.user).by_display_name
    @mailbox = @mailboxes.find(params[:mailbox_id]) if params[:mailbox_id].present?
    scope = filtered_conversations
    if pins_assigned?
      mine = scope.assigned_to(Current.user)
      @assigned = one_per_email(mine).recent.limit(PER_PAGE).to_a if params[:before].blank?
      scope = scope.where("#{Conversation::TWIN_KEY} NOT IN (#{mine.unscope(:select, :includes).select(Arel.sql(Conversation::TWIN_KEY)).to_sql})")
    end
    @conversations = page(one_per_email(scope))
    listed = @conversations + Array(@assigned)
    Conversation.load_twins(listed, Current.user) unless @mailbox
    Conversation.load_attachments(listed)
    @stack_counts = ConversationState::STACKS.index_with { |stack| Conversation.accessible_by(Current.user).in_stack_for(Current.user, stack).one_per_email.count } unless @stack || @archived
  end

  def show
    @messages = @conversation.messages.includes(:readings)
    @people = @conversation.mailbox.users_with_access.order(:name).to_a
    @notes = @conversation.notes.includes(:user)
    @screening = @conversation.screening_for(Current.user)
    @bucket = @conversation.bucket_for(Current.user)
    @stacks = @conversation.stacks_for(Current.user)
    @archived = @conversation.archived_for?(Current.user)
    @twins = @conversation.twins_for(Current.user)
    if current_account.agent_enabled?
      @agent = Agent.for(Current.user)
      @agent_chat = AgentChat.where(user: Current.user, conversation: @conversation).recent.first
    end
    @conversation.mark_read_by!(Current.user)
    AccessLog.record!(Current.user, @conversation, via: "web")
  end

  def unread
    @conversation.mark_unread_by!(Current.user)
    redirect_to conversations_path, notice: "Fil marqué comme non lu."
  end

  # Qui s'occupe de ce fil : une personne qui a accès à la boîte, ou personne.
  def assign
    assignee = @conversation.mailbox.users_with_access.find_by(id: params[:assignee_id])
    @conversation.update!(assignee: assignee)
    notice = assignee ? "#{assignee.display_name} s'occupe de ce fil." : "Plus personne n'est assigné à ce fil."
    redirect_to conversation_path(@conversation), notice: notice
  end

  # Met le fil dans « Répondre plus tard » ou « Mis de côté » (on=1), ou l'en retire, pour moi seulement.
  def stack
    stack = params.require(:stack)
    on = params[:on] == "1"
    @conversation.put_in_stack_for!(Current.user, stack, on: on)
    flourish(stack) if on
    label = ConversationState::STACK_LABELS.fetch(stack)
    redirect_back_or_to conversation_path(@conversation), notice: on ? "Fil ajouté à « #{label} »." : "Fil retiré de « #{label} »."
  rescue ArgumentError
    redirect_back_or_to conversation_path(@conversation), alert: "Pile inconnue."
  end

  # Archiver (on=1) : j'en ai fini, le fil quitte ma réception jusqu'au prochain message. on=0 l'y remet.
  def archive
    on = params[:on] != "0"
    @conversation.archive_for!(Current.user, on: on)
    flourish(on ? "archive" : "unarchive")
    if on
      flash[:undo] = [ @conversation.id ]
      return redirect_to(focus_reply_path, notice: "Fil archivé : il reviendra au prochain message.") if params[:focus].present?
      bucket = @conversation.bucket_for(Current.user)
      redirect_to conversations_path(box: (bucket unless bucket.in?([ nil, "imbox" ]))), notice: "Fil archivé : il reviendra au prochain message."
    else
      redirect_to conversation_path(@conversation), notice: "Fil remis dans la réception."
    end
  end

  # Singulier, pluriel.
  BULK_NOTICES = {
    "archive" => [ "archivé", "archivés" ], "unarchive" => [ "remis dans la réception" ] * 2,
    "read" => [ "marqué comme lu", "marqués comme lus" ], "unread" => [ "marqué comme non lu", "marqués comme non lus" ],
    "reply_later" => [ "ajouté à « Répondre plus tard »", "ajoutés à « Répondre plus tard »" ], "set_aside" => [ "mis de côté" ] * 2
  }.freeze

  # Actions groupées sur les fils cochés dans une liste, pour moi seulement.
  def bulk
    operation = params[:operation].presence_in(BULK_NOTICES.keys)
    conversations = Conversation.accessible_by(Current.user).where(id: Array(params[:ids])).to_a
    return redirect_back_or_to(account_root_path, alert: "Coche au moins un fil.") if operation.nil? || conversations.empty?

    case operation
    when "archive", "unarchive" then conversations.each { |c| c.archive_for!(Current.user, on: operation == "archive") }
    when "read" then Reading.mark!(Current.user, Message.where(conversation_id: conversations.map(&:id)))
    when "unread" then conversations.each { |c| c.mark_unread_by!(Current.user) }
    else conversations.each { |c| c.put_in_stack_for!(Current.user, operation) }
    end
    flash[:undo] = conversations.map(&:id) if operation == "archive"
    flourish(operation, count: conversations.size) if operation.in?(%w[archive unarchive reply_later set_aside])
    redirect_back_or_to account_root_path, notice: "#{conversations.size} #{conversations.many? ? "fils" : "fil"} #{BULK_NOTICES.fetch(operation)[conversations.many? ? 1 : 0]}."
  end

  # « Tout marquer comme lu » : utile après l'import de milliers de vieux messages.
  # Depuis le Feed ou le Paper Trail, seulement les fils de cette pile.
  def mark_all_read
    mailboxes = Mailbox.accessible_by(Current.user)
    mailboxes = mailboxes.where(id: params[:mailbox_id]) if params[:mailbox_id].present?
    messages = Message.where(mailbox: mailboxes)
    box = params[:box].presence_in(Screening::BUCKETS - [ "imbox" ])
    messages = messages.where(conversation_id: Conversation.in_bucket_for(Current.user, box).select(:id)) if box
    Reading.mark!(Current.user, messages)
    redirect_to conversations_path(box: box, mailbox_id: params[:mailbox_id].presence), notice: "Tout est marqué comme lu."
  end

  private

  def set_conversation
    @conversation = Conversation.accessible_by(Current.user).find(params[:id])
  end

  def filtered_conversations
    scope = Conversation.accessible_by(Current.user).with_unread_for(Current.user).includes(:mailbox, :assignee)
    if @archived
      scope = scope.archived_for(Current.user)
      scope = scope.where(mailbox: @mailbox) if @mailbox
    elsif @stack
      scope = scope.in_stack_for(Current.user, @stack)
      scope = scope.where(mailbox: @mailbox) if @mailbox
    else
      scope = scope.in_bucket_for(Current.user, @box).outside_stacks_for(Current.user).inbox
      scope = scope.where(mailbox: @mailbox) if @mailbox
    end
    scope = scope.assigned_to(Current.user) if params[:mine] == "1"
    scope = scope.unread_for(Current.user) if params[:unread] == "1"
    scope
  end

  def one_per_email(scope) = @mailbox ? scope : scope.one_per_email

  # Dans la réception, les fils qu'on m'a assignés restent en tête, même anciens, tant que je ne les ai pas
  # archivés : sinon ils disparaissent sous le courrier du jour et on les croit perdus.
  def pins_assigned?
    @box == "imbox" && !@stack && !@archived && params[:mine] != "1" && params[:unread] != "1"
  end

  # Pagination par date : ?before=<horodatage du dernier fil affiché>.
  def page(scope)
    scope = scope.where(last_message_at: ...Time.zone.parse(params[:before])) if params[:before].present?
    scope.recent.limit(PER_PAGE).to_a
  end
end
