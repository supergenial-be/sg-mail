# Un client de Super Génial (Semisto, Silvéa…). Tout ce qui touche aux emails lui appartient.
class Account < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :invitations, dependent: :destroy

  # La couleur du client teinte la barre latérale (et le tiroir sur téléphone), pour savoir d'un coup d'œil
  # chez qui on est. Une palette fermée, accordée au papier et à l'encre, en clair comme en sombre :
  # dot = pastille, light/dark = fond de la barre en thème clair/sombre.
  COLORS = {
    "lavender"  => { label: "Lavande",   dot: "#8a63cf", light: "#ece4f6", dark: "#261d36" },
    "sage"      => { label: "Sauge",     dot: "#4c7a57", light: "#e0ebdd", dark: "#1a271e" },
    "ochre"     => { label: "Ocre",      dot: "#b07d1f", light: "#f2e5c6", dark: "#2b2315" },
    "brick"     => { label: "Brique",    dot: "#c4553b", light: "#f4ddd4", dark: "#301d19" },
    "raspberry" => { label: "Framboise", dot: "#b3477a", light: "#f4dde7", dark: "#2e1a25" },
    "sky"       => { label: "Ciel",      dot: "#3d74a0", light: "#dce8f2", dark: "#18232f" },
    "teal"      => { label: "Sarcelle",  dot: "#2f7f7a", light: "#d8ebe8", dark: "#152826" },
    "olive"     => { label: "Olive",     dot: "#717c2b", light: "#e8ead0", dark: "#222419" },
    "slate"     => { label: "Ardoise",   dot: "#5f6670", light: "#e4e4e7", dark: "#1f1f26" }
  }.freeze

  validates :name, presence: true
  validates :color, inclusion: { in: COLORS.keys }, allow_nil: true

  def color_palette = COLORS[color]

  # Les teintes du client, en propriétés CSS (pastille, fond clair, fond sombre). Vide sans couleur : papier.
  def color_style
    return unless (palette = color_palette)
    "--client: #{palette[:dot]}; --client-light: #{palette[:light]}; --client-dark: #{palette[:dark]}"
  end

  # Tables qui appartiennent au client, dans un ordre qui respecte leurs clés étrangères.
  OWNED_TABLES = %w[
    integration_connections integrations agent_actions agent_messages agent_chats readings access_logs notes drafts conversation_states screenings messages conversations mail_folders
    mailbox_accesses mailboxes oauth_tokens oauth_authorization_codes api_tokens invitations memberships
  ].freeze

  # Suppression complète du client, à sa demande (cadrage §4.2) : boîtes, emails, tâches, notes, jetons,
  # membres. L'accès Google de chaque boîte Gmail est révoqué. Irréversible.
  def purge!
    gmail_mailboxes = Tenancy.with_account(self) do
      mailboxes = Mailbox.where(provider: "gmail").to_a
      transaction do
        OWNED_TABLES.each { |table| self.class.connection.delete("DELETE FROM #{table} WHERE account_id = #{id.to_i}") }
        self.class.where(id: id).delete_all
      end
      mailboxes
    end
    # Hors du client, qui n'existe plus : le job ne doit pas le recharger.
    ActsAsTenant.without_tenant { gmail_mailboxes.each(&:revoke_google_access) }
  end
end
