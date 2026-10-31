# Les outils de l'agent : ceux du serveur MCP de SG Mail, appelés en direct, et ceux des outils du client que
# la personne a connectés (My Semisto, Claudy…), préfixés par l'outil (« mysemisto__search »), toujours en son nom.
# Une lecture s'exécute tout de suite ; une écriture attend sa confirmation (décision A3). L'envoi d'un email
# n'en fait pas partie : l'agent prépare un brouillon, la personne l'envoie elle-même depuis SG Mail.
class AgentToolbox
  EXCLUDED = [ SgMailMcp::SendDraft ].freeze
  TOOLS = (SgMailMcp::TOOLS - EXCLUDED).index_by(&:name_value).freeze
  SEPARATOR = "__".freeze
  NAME_FORMAT = /\A[a-zA-Z0-9_-]{1,64}\z/ # ce que l'API Claude accepte comme nom d'outil

  LABELS = {
    "mark_read" => "Marquer le fil comme lu", "mark_unread" => "Marquer le fil comme non lu", "assign" => "Assigner le fil",
    "add_note" => "Ajouter une note interne", "screen_sender" => "Trier un expéditeur", "update_stacks" => "Ranger le fil",
    "create_draft" => "Préparer un brouillon", "update_draft" => "Modifier un brouillon",
    "read_attachment" => "Lire une pièce jointe", "upload_attachment" => "Envoyer une pièce jointe"
  }.freeze

  def self.label(name)
    slug, tool = name.to_s.split(SEPARATOR, 2)
    return LABELS.fetch(name, name.to_s.humanize) unless tool

    "#{Integration.find_by(slug: slug)&.name || slug} : #{tool.tr('_', ' ')}"
  end

  def self.remote?(name) = name.to_s.include?(SEPARATOR)

  def initialize(user, base_url: nil, chat: nil)
    @attachments = AgentAttachmentTools.new(user, chat: chat)
    @context = { actions: MailActions.new(user, via: "agent"), serializer: ApiSerializer.new(user: user, base_url: base_url) }
    @connections = IntegrationConnection.connected.where(user: user).includes(:integration).to_a
  end

  attr_reader :connections

  # Relit les outils des serveurs connectés quand ils datent (au début d'une réponse de l'agent).
  def refresh_remote_tools!
    @connections.each { |connection| RemoteMcp.new(connection).refresh_if_stale! }
    @connections.select!(&:connected?)
    @remote = nil
  end

  # Les définitions d'outils pour l'API Claude. L'agent travaille dans un seul client : pas d'account_id.
  def definitions
    local = TOOLS.values.map do |tool|
      schema = tool.input_schema_value.to_h.except(:"$schema")
      { name: tool.name_value, description: tool.description_value, input_schema: schema.merge(properties: schema[:properties].except(:account_id)) }
    end
    local + AgentAttachmentTools::DEFINITIONS + remote.map do |name, (connection, tool)|
      { name: name, description: "[#{connection.integration.name}] #{tool["description"]}".first(4000),
        input_schema: tool["input_schema"].to_h.except("$schema").reverse_merge("type" => "object") }
    end
  end

  def known?(name) = TOOLS.key?(name) || AgentAttachmentTools.handles?(name) || remote.key?(name)

  # Un outil inconnu ou sans annotation compte comme une écriture.
  def writes?(name)
    return remote[name].nil? || !remote[name].last["read_only"] if self.class.remote?(name)
    return name.in?(AgentAttachmentTools::WRITES) if AgentAttachmentTools.handles?(name)

    TOOLS[name]&.annotations_value&.read_only_hint != true
  end

  # { "text" => …, "error" => true|false }
  def call(name, input)
    if self.class.remote?(name)
      connection, tool = remote[name]
      return { "text" => "Unknown tool #{name}: the person may have disconnected it", "error" => true } unless connection

      return RemoteMcp.new(connection).call(tool["name"], input.to_h)
    end

    return @attachments.call(name, input.to_h.stringify_keys) if AgentAttachmentTools.handles?(name)

    tool = TOOLS[name] or return { "text" => "Unknown tool #{name}", "error" => true }
    arguments = input.to_h.transform_keys(&:to_sym).except(:mark_read) # lire n'est pas « marquer comme lu »
    response = tool.call(server_context: @context, **arguments)
    { "text" => response.content.map { |block| block[:text] }.join("\n"), "error" => response.error? }
  rescue ArgumentError => error # argument manquant ou inconnu
    { "text" => error.message, "error" => true }
  end

  private

  # « slug__outil » => [connexion, outil], pour chaque outil d'un serveur connecté.
  def remote
    @remote ||= @connections.each_with_object({}) do |connection, tools|
      connection.tools_list.each do |tool|
        name = "#{connection.integration.slug}#{SEPARATOR}#{tool["name"]}"
        tools[name] = [ connection, tool ] if name.match?(NAME_FORMAT)
      end
    end
  end
end
