class AddImboxVisitsToMemberships < ActiveRecord::Migration[8.1]
  def change
    # « Nouveaux messages » : ce qui est arrivé depuis ma dernière visite de la Réception (et pas encore lu).
    add_column :memberships, :imbox_visited_at, :datetime
    add_column :memberships, :imbox_seen_at, :datetime
  end
end
