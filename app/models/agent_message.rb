# Un tour de la discussion, tel qu'il part chez Claude ou en revient (blocs de contenu), avec son coût.
class AgentMessage < ApplicationRecord
  ROLES = %w[user assistant].freeze
  # Ce que l'API accepte en retour, bloc par bloc. Une réponse contient aussi des champs en lecture seule
  # (caller, citations vides…) que l'API refuse si on les lui renvoie.
  BLOCK_KEYS = {
    "text" => %w[type text], "thinking" => %w[type thinking signature], "redacted_thinking" => %w[type data],
    "tool_use" => %w[type id name input], "tool_result" => %w[type tool_use_id content is_error]
  }.freeze

  acts_as_tenant :account
  belongs_to :agent_chat, touch: true
  has_many :agent_actions, dependent: :destroy

  validates :role, inclusion: { in: ROLES }

  scope :this_month, -> { where(created_at: Time.current.all_month) }

  # Le texte visible : les blocs « text » seulement (ni réflexion, ni outils, ni résultats d'outils).
  def text = content.select { |block| block["type"] == "text" }.map { |block| block["text"] }.join("\n\n").strip

  def tool_uses = content.select { |block| block["type"] == "tool_use" }

  def to_claude
    { role: role, content: content.map { |block| with_attachments(BLOCK_KEYS[block["type"]]&.then { |keys| block.slice(*keys) } || block) } }
  end

  private

  # Les pièces jointes lues par l'agent, relues depuis le cache au moment de partir chez Claude.
  def with_attachments(block)
    return block unless block["type"] == "tool_result" && block["content"].is_a?(Array)

    block.merge("content" => block["content"].map do |part|
      part["type"] == AgentAttachmentTools::REFERENCE ? AgentAttachmentTools.content_block(agent_chat.user, part) : part
    end)
  end
end
