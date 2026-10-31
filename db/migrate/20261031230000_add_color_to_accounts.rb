class AddColorToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :color, :string
  end
end
