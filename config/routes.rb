Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # SG Mail installable comme une app sur mobile et ordinateur (PWA).
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "installer" => "installs#show", as: :install

  resource :session
  post "session/passkey/options" => "passkey_sessions#options", as: :passkey_session_options
  post "session/passkey" => "passkey_sessions#create", as: :passkey_session
  resources :passkeys, only: %i[index create destroy] do
    post :options, on: :collection
  end
  resources :push_subscriptions, only: %i[index create destroy], path: "notifications" do
    post :test, on: :collection
  end
  resources :passwords, param: :token
  get "invitations/:token" => "invitation_acceptances#show", as: :invitation_acceptance
  get "inline/:token" => "inline_images#show", as: :inline_image
  post "invitations/:token" => "invitation_acceptances#create"

  resources :accounts, only: %i[index new create destroy]

  # Notifications Pub/Sub des boîtes Gmail (voir GmailWatch).
  post "webhooks/gmail" => "webhooks/gmail#create"

  # Adresse de retour fixe, déclarée dans la console Google.
  get "auth/google_oauth2/callback" => "google_oauth#callback"
  # Retour OAuth des outils connectés (adresse fixe, inscrite auprès de chaque outil).
  get "integrations/callback" => "integration_connections#callback", as: :integration_callback

  # Tout ce qui appartient à un client vit sous /<id du client>/.
  scope "/:account_id", constraints: { account_id: /\d+/ } do
    resources :mailboxes, only: %i[index show new create edit update destroy] do
      post :sync, on: :member
      patch :preferences, on: :member
      resources :accesses, controller: "mailbox_accesses", only: %i[index update]
    end
    resources :conversations, only: %i[index show] do
      post :unread, on: :member
      patch :assign, on: :member
      patch :stack, on: :member
      patch :archive, on: :member
      resources :notes, only: %i[create destroy]
      post :mark_all_read, on: :collection
      post :bulk, on: :collection
    end
    resources :drafts, except: :show do
      post :cancel, on: :member
    end
    resource :focus_reply, only: :show, path: "plus-tard/a-la-suite"
    resources :screenings, only: %i[index create], path: "screener"
    resource :search, only: :show
    resources :messages, only: :show do
      resources :attachments, only: %i[show create] do
        get :thumbnail, on: :member
        get :archive, on: :collection
      end
    end
    resources :memberships, only: %i[index update destroy]
    resource :sharing, only: %i[show update], path: "partage"
    resource :account_settings, only: %i[show update], path: "client"
    resources :invitations, only: %i[create destroy]
    resources :api_tokens, only: %i[index create destroy]
    resources :access_logs, only: :index, path: "journal"
    resources :oauth_connections, only: :destroy
    # L'agent intégré : réglages du client (admin), mon agent, mes discussions avec lui.
    resource :agent_settings, only: %i[show update], path: "agent"
    resources :integrations, only: %i[index create destroy], path: "outils" do
      resource :connection, controller: "integration_connections", only: %i[create destroy]
    end
    resource :agent, only: %i[edit update], path: "mon-agent" do
      get :avatar, path: "image"
    end
    resources :agent_chats, only: %i[index show create], path: "agent/discussions" do
      resources :agent_messages, only: :create, path: "messages"
      resources :agent_actions, only: :update, path: "actions"
    end
    get "auth/google_oauth2" => "google_oauth#new", as: :google_oauth
    get "/" => "conversations#index", as: :account_root
  end

  # API JSON, utilisée par le CLI et le MCP (jeton personnel ; le client est celui du jeton).
  namespace :api do
    namespace :v1 do
      resource :me, only: :show, controller: "me"
      resources :conversations, only: %i[index show update] do
        post :read, on: :member
        post :unread, on: :member
        resources :notes, only: :create
      end
      resources :screenings, only: %i[index create], path: "screener"
      resources :drafts, only: %i[index show create update] do
        post :deliver, on: :member
      end
    end
  end

  # Serveur MCP pour Claude : jeton personnel, ou OAuth 2.1 pour les connecteurs claude.ai.
  post "mcp" => "mcp#create", as: :mcp
  match "mcp" => "mcp#unsupported", via: %i[get delete]
  get ".well-known/oauth-protected-resource(/mcp)" => "oauth/metadata#protected_resource", as: :oauth_protected_resource
  get ".well-known/oauth-authorization-server" => "oauth/metadata#authorization_server", as: :oauth_authorization_server
  namespace :oauth do
    get "authorize" => "authorizations#new", as: :authorization
    post "authorize" => "authorizations#create"
    post "token" => "tokens#create", as: :token
    post "revoke" => "tokens#revoke", as: :revocation
    post "register" => "registrations#create", as: :registration
  end

  root "accounts#index"
end
