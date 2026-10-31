# Un outil que l'agent a appelé. Une lecture s'exécute tout de suite ; une écriture attend que la personne
# confirme (décision A3). Le journal reste visible dans la discussion.
class AgentAction < ApplicationRecord
  STATUSES = %w[pending confirmed done rejected failed].freeze

  acts_as_tenant :account
  belongs_to :agent_chat
  belongs_to :agent_message
  belongs_to :decided_by, class_name: "User", optional: true

  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }

  def pending? = status == "pending"
  def done? = status == "done"
  def label = AgentToolbox.label(tool_name)
  def result_text = result&.fetch("text", nil)

  # Le résultat tel que Claude le reçoit. Une pièce jointe lue y est un renvoi (AgentAttachmentTools::REFERENCE) :
  # le fichier n'est jamais recopié dans la discussion, AgentMessage#to_claude le relit à chaque tour.
  def tool_result
    text = case status
    when "rejected" then "The user declined this action. Do not retry it unless they ask."
    else result_text.to_s
    end
    reference = result&.dig("attachment") if done?
    content = reference ? [ { "type" => "text", "text" => text }, reference.merge("type" => AgentAttachmentTools::REFERENCE) ] : text
    { "type" => "tool_result", "tool_use_id" => tool_use_id, "content" => content, "is_error" => status.in?(%w[rejected failed]) }
  end
end
