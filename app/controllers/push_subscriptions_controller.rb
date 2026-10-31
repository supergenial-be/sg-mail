# Mes notifications : les activer sur cet appareil, en envoyer une de test, retirer un appareil.
class PushSubscriptionsController < ApplicationController
  def index
    @subscriptions = Current.user.push_subscriptions.order(:created_at)
    @vapid_public_key = VapidKey.public_key
  end

  # Le navigateur vient de s'abonner : on garde son adresse de push et ses clés (un même appareil qui se
  # réabonne remplace son ancien abonnement).
  def create
    attributes = params.require(:subscription).permit(:endpoint, keys: %i[p256dh auth])
    subscription = PushSubscription.find_or_initialize_by(endpoint: attributes[:endpoint])
    subscription.update!(user: Current.user, p256dh: attributes.dig(:keys, :p256dh), auth: attributes.dig(:keys, :auth),
      name: subscription.name || Passkey.default_name(request.user_agent))
    flash[:notice] = "Notifications activées sur cet appareil."
    render json: { redirect: push_subscriptions_path }
  rescue ActiveRecord::RecordInvalid, ActionController::ParameterMissing
    render json: { error: "Abonnement refusé : réessaie depuis l'app." }, status: :unprocessable_entity
  end

  def test
    delivered = Current.user.push_subscriptions.map do |subscription|
      subscription.deliver(title: "SG Mail", body: "Les notifications fonctionnent sur cet appareil.", url: push_subscriptions_path, tag: "test")
    end
    if delivered.any?
      count = delivered.count(true)
      redirect_to push_subscriptions_path, notice: count > 1 ? "Notification envoyée sur tes #{count} appareils." : "Notification envoyée sur ton appareil."
    else
      redirect_to push_subscriptions_path, alert: "Aucun appareil n'est abonné pour l'instant."
    end
  end

  def destroy
    Current.user.push_subscriptions.find(params[:id]).destroy!
    redirect_to push_subscriptions_path, notice: "Cet appareil ne recevra plus de notifications."
  end
end
