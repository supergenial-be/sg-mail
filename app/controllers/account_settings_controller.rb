# Le client lui-même : son nom et sa couleur, qui teinte la barre latérale de tous ses membres.
# Tout le monde voit ; seuls les admins changent.
class AccountSettingsController < ApplicationController
  include AccountScoped
  before_action :require_admin, only: :update

  def show
  end

  def update
    color = params.dig(:account, :color).presence
    if current_account.update(name: params.dig(:account, :name).to_s.strip, color: color)
      redirect_to account_settings_path, notice: "#{current_account.name} : réglages enregistrés."
    else
      render :show, status: :unprocessable_entity
    end
  end
end
