class Membership < ApplicationRecord
  ROLES = %w[admin member].freeze

  belongs_to :account
  belongs_to :user

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :account_id }
  validate :keeps_an_admin, on: :update

  before_destroy :ensure_not_last_admin
  after_destroy :revoke_mailbox_accesses

  scope :admins, -> { where(role: "admin") }

  # Une visite de la Réception plus de 30 minutes après la précédente ouvre une nouvelle visite.
  VISIT_GAP = 30.minutes

  def admin? = role == "admin"

  # Retient que j'ouvre la Réception et rend le seuil des « Nouveaux messages » : ce qui est arrivé
  # avant ma visite précédente, je l'ai déjà vu passer dans la liste, même sans l'ouvrir.
  def visit_imbox!(now = Time.current)
    attributes = { imbox_visited_at: now }
    attributes[:imbox_seen_at] = imbox_visited_at if imbox_visited_at && imbox_visited_at < now - VISIT_GAP
    update_columns(attributes)
    imbox_seen_at || created_at
  end

  def role_label = Membership.role_label(role)

  def self.role_label(role) = role == "admin" ? "Admin" : "Membre"

  private

  def revoke_mailbox_accesses
    Tenancy.with_account(account) { MailboxAccess.where(user_id: user_id).delete_all }
  end

  def last_admin?
    role_was == "admin" && account.memberships.admins.where.not(id: id).none?
  end

  def keeps_an_admin
    errors.add(:role, "ne peut pas changer : il faut au moins un admin") if role_changed? && last_admin?
  end

  def ensure_not_last_admin
    return unless last_admin?

    errors.add(:base, "Impossible de retirer le dernier admin du client.")
    throw :abort
  end
end
