# Fait avancer une discussion avec l'agent : appelle Claude, exécute les lectures, met les écritures en attente
# de confirmation, et recommence tant que Claude veut des outils. S'arrête sur une réponse, sur une action à
# confirmer, ou au plafond mensuel du client (décision A5).
class AgentRun
  MODEL = "claude-sonnet-5-5" # décision A6
  # Prix en millionièmes de dollar par jeton : 2 $ / 10 $ par million, cache lu à 0,20 $, écrit à 2,50 $.
  PRICES = { input: 2.0, output: 10.0, cache_read: 0.2, cache_write: 2.5 }.freeze
  MAX_STEPS = 12
  MAX_TOKENS = 8000

  class BudgetExceeded < StandardError; end

  # Qui appelle vraiment Claude (remplacé dans les tests) : reçoit les paramètres, rend un Hash
  # { "content" => [blocs], "stop_reason" => …, "usage" => {…} }.
  cattr_accessor :client, default: ->(**params) { JSON.parse(AgentRun.anthropic.messages.create(**params).to_h.to_json) }

  def self.anthropic = @anthropic ||= Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))
  def self.configured? = ENV["ANTHROPIC_API_KEY"].present?

  # Ce que la personne lit quand Claude refuse la requête : la raison donnée par l'API quand il y en a une
  # (crédit épuisé, clé invalide…), pour savoir quoi corriger sans fouiller les logs.
  def self.failure_message(error)
    body = error.respond_to?(:body) ? error.body : nil
    detail = body.is_a?(Hash) ? (body.dig(:error, :message) || body.dig("error", "message")) : nil
    reason = [ error.class.name.demodulize, detail&.truncate(200) ].compact.join(" : ")
    "L'agent n'a pas pu répondre (#{reason}). Réessaie dans un instant."
  end

  def self.cost_micros(usage)
    (usage["input_tokens"].to_i * PRICES[:input] + usage["output_tokens"].to_i * PRICES[:output] +
      usage["cache_read_input_tokens"].to_i * PRICES[:cache_read] + usage["cache_creation_input_tokens"].to_i * PRICES[:cache_write]).round
  end

  # Ce que le client a dépensé ce mois-ci, en cents.
  def self.month_spend_cents = AgentMessage.this_month.sum(:cost_micros) / 10_000

  def initialize(chat, base_url: nil)
    @chat = chat
    @agent = Agent.for(chat.user)
    @toolbox = AgentToolbox.new(chat.user, base_url: base_url, chat: chat)
  end

  def perform
    @toolbox.refresh_remote_tools!
    MAX_STEPS.times do
      ensure_budget!
      reply = record_reply(call_claude)
      return finish("idle") unless reply.tool_uses.any?

      start_tools(reply)
      return finish("waiting") if @chat.agent_actions.pending.exists?

      continue_after(reply)
    end
    finish("idle")
  rescue BudgetExceeded
    say("Le plafond mensuel de l'agent pour #{@chat.account.name} est atteint. Un admin peut le relever dans Réglages → Agent.")
    finish("idle")
  rescue StandardError => error
    Rails.logger.error("Agent : discussion #{@chat.id} : #{error.class} #{error.message}")
    close_dangling_tools
    @chat.update!(status: "failed", error: self.class.failure_message(error))
    @chat.broadcast_refresh
  end

  # Après la décision de la personne sur chaque action en attente : exécute ce qu'elle a confirmé et reprend.
  def resume
    reply = @chat.agent_messages.where(role: "assistant").last
    continue_after(reply)
    perform
  end

  private

  def call_claude
    self.class.client.call(
      model: MODEL, max_tokens: MAX_TOKENS, system_: system_prompt, tools: @toolbox.definitions,
      messages: @chat.agent_messages.map(&:to_claude), output_config: { effort: "medium" },
      cache_control: { type: "ephemeral" }
    )
  end

  def record_reply(response)
    usage = response.fetch("usage", {})
    content = response.fetch("content", [])
    content = [ { "type" => "text", "text" => "Je préfère ne pas répondre à cette demande." } ] if response["stop_reason"] == "refusal" && content.none? { |b| b["type"] == "text" }
    @chat.agent_messages.create!(role: "assistant", content: content, model: MODEL,
      input_tokens: usage["input_tokens"].to_i, output_tokens: usage["output_tokens"].to_i, cost_micros: self.class.cost_micros(usage))
  end

  # Lectures exécutées tout de suite, écritures en attente.
  def start_tools(reply)
    reply.tool_uses.each do |block|
      writes = @toolbox.writes?(block["name"])
      action = @chat.agent_actions.create!(agent_message: reply, tool_use_id: block["id"], tool_name: block["name"],
        input: block["input"] || {}, writes: writes, status: "pending")
      execute(action) unless writes
    end
    @chat.broadcast_refresh
  end

  def execute(action)
    result = @toolbox.call(action.tool_name, action.input)
    action.update!(status: result["error"] ? "failed" : "done", result: result)
  end

  # Tous les résultats d'un tour repartent ensemble, dans un seul message (règle de l'API).
  def continue_after(reply)
    actions = reply.agent_actions.order(:id).to_a
    actions.select { |action| action.status == "confirmed" }.each { |action| execute(action) }
    @chat.agent_messages.create!(role: "user", content: actions.map(&:tool_result))
  end

  # Un outil demandé sans résultat rendrait la discussion invalide pour l'API : on le clôt en échec.
  def close_dangling_tools
    last = @chat.agent_messages.reload.last
    return unless last&.role == "assistant" && last.tool_uses.any?

    last.agent_actions.where(status: %w[pending confirmed]).update_all(status: "failed", result: { "text" => "Interrupted", "error" => true })
    known = last.agent_actions.pluck(:tool_use_id)
    results = last.agent_actions.reload.map(&:tool_result) +
      last.tool_uses.reject { |block| block["id"].in?(known) }.map { |block| { "type" => "tool_result", "tool_use_id" => block["id"], "content" => "Interrupted", "is_error" => true } }
    @chat.agent_messages.create!(role: "user", content: results)
  rescue StandardError
    nil
  end

  def finish(status)
    @chat.update!(status: status)
    @chat.broadcast_refresh
  end

  def say(text)
    @chat.agent_messages.create!(role: "assistant", content: [ { "type" => "text", "text" => text } ])
  end

  def ensure_budget!
    raise BudgetExceeded if self.class.month_spend_cents >= @chat.account.agent_monthly_budget_cents
  end

  def system_prompt
    [ { type: "text", text: AgentPrompt.persona(@agent) }, { type: "text", text: AgentPrompt.context(@chat, connections: @toolbox.connections) } ]
  end
end
