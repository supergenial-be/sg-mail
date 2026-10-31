class Message < ApplicationRecord
  # Colonne calculée par Postgres pour la recherche (voir MessageSearch) : inutile à charger.
  self.ignored_columns += %w[search_vector]

  acts_as_tenant :account
  belongs_to :mailbox
  belongs_to :mail_folder, optional: true
  belongs_to :conversation, optional: true
  has_many :readings, dependent: :delete_all
  # Les pièces jointes déjà rapatriées du fournisseur (voir AttachmentCache).
  has_many_attached :attachment_files

  before_validation { self.account_id ||= mailbox&.account_id }

  scope :recent, -> { order(sent_at: :desc) }

  def from_display = from_name.presence || from_address

  # Les images du corps (logos de signature, icônes Facebook ou Instagram…) ne sont pas des pièces jointes,
  # même quand elles viennent d'un message cité ou que le corps ne les appelle plus.
  def listed_attachments
    attachments.reject { |attachment| self.class.body_image?(attachment, body_has_images: body_html.to_s.match?(/cid:/i)) }
  end

  # Nom typique d'une image de signature, pour les listes enregistrées avant le drapeau inline.
  SIGNATURE_IMAGE = /\A(outlook-|image\d{3}|logo|signature|facebook|instagram|linkedin|twitter|youtube|whatsapp|x\.)/i
  SMALL_IMAGE = 100.kilobytes

  # body_has_images : le corps HTML appelle au moins une image intégrée (cid:…). Sans cela, une image
  # « intégrée » ne s'afficherait nulle part : elle reste une pièce jointe.
  def self.body_image?(attachment, body_has_images:)
    return false unless body_has_images && attachment["content_type"].to_s.downcase.start_with?("image/")
    return attachment["inline"] if attachment.key?("inline")

    attachment["content_id"].present? || SIGNATURE_IMAGE.match?(attachment["filename"].to_s) || attachment["size"].to_i < SMALL_IMAGE
  end

  def read_by?(user) = readings.any? { |reading| reading.user_id == user.id }

  def unread_in_provider?
    labels.include?("UNREAD") || (mailbox.imap? && !labels.include?("Seen"))
  end
end
