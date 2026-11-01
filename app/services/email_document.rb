# Prépare le corps HTML d'un email pour l'iframe du fil, pour qu'il se fonde dans SG Mail :
# - une feuille de style de base (Geist, encre et papier, mode sombre) placée AVANT celles de l'expéditeur,
#   avec une spécificité nulle (:where) : la mise en forme voulue par l'expéditeur garde toujours la main ;
# - un email « composé » (fonds de couleur, newsletter) reste sur une feuille claire en mode sombre,
#   un email « simple » (écrit dans Gmail, Outlook…) prend les couleurs de l'app ;
# - les liens s'ouvrent dans un nouvel onglet, sans référent ;
# - le texte cité d'une réponse est repéré (classe sg-quote), replié par défaut.
class EmailDocument
  # Fonds posés par l'expéditeur : l'email a été composé pour un fond clair.
  DESIGNED = /bgcolor\s*=|background(?:-color)?\s*:\s*+(?!transparent|none|inherit|initial)[^;"'}]+/i

  # Texte cité, selon le logiciel de l'expéditeur.
  QUOTE_SELECTORS = [
    ".gmail_quote_container", ".gmail_quote", # Gmail
    ".moz-cite-prefix",                        # Thunderbird (suivi de son blockquote)
    "#divRplyFwdMsg", "#appendonsend",         # Outlook (tout ce qui suit est cité)
    "body > blockquote[type=cite]", "body > div > blockquote[type=cite]" # Apple Mail
  ].freeze

  FORWARD = /forwarded message|message transféré|message d'origine|original message|weitergeleitet/i

  def initialize(html, font_url: nil)
    @html = html.to_s
    @font_url = font_url
  end

  def designed? = @html.match?(DESIGNED)

  def to_html = @to_html ||= render

  # Y a-t-il du texte cité à déplier ?
  def quoted? = to_html.present? && @quoted

  private

  def render
    document = Nokogiri::HTML5(@html)
    document.at("html")["class"] = [ document.at("html")["class"], designed? ? "sg-designed" : "sg-plain" ].compact.join(" ")
    document.at("head").prepend_child(<<~HTML)
      <meta charset="utf-8">
      <meta name="color-scheme" content="#{designed? ? "light" : "light dark"}">
      <meta name="referrer" content="no-referrer">
      <style>#{stylesheet}</style>
    HTML
    document.css("a[href]").each do |link|
      link["target"] = "_blank"
      link["rel"] = "noopener noreferrer"
    end
    @quoted = mark_quote(document)
    document.to_html
  end

  def mark_quote(document)
    body = document.at("body")
    start = QUOTE_SELECTORS.lazy.filter_map { |selector| body.at_css(selector) }.first or return false
    # Un transfert : le message, c'est le texte cité.
    return false if start.text.first(300).match?(FORWARD)

    quote = [ start ]
    quote += start.xpath("following-sibling::node()").to_a if start.matches?(".moz-cite-prefix, #divRplyFwdMsg, #appendonsend")
    quote.unshift(start.previous_element) if start.previous_element&.name == "hr" # le trait d'Outlook
    quoted_text = quote.sum("") { |node| node.text }
    return false if body.text.sub(quoted_text, "").strip.empty?

    quote.each do |node|
      if node.element?
        node["class"] = [ node["class"], "sg-quote" ].compact.join(" ")
      elsif node.text.strip.present?
        node.replace(document.create_element("span", node.text, class: "sg-quote"))
      end
    end
    true
  end

  def stylesheet
    <<~CSS.squish
      #{"@font-face { font-family: 'Geist'; font-weight: 100 900; font-display: swap; src: url('#{@font_url}') format('woff2'); }" if @font_url}
      :where(html) { color-scheme: #{designed? ? "light" : "light dark"}; }
      :where(body) { margin: 0; padding: 0; font-family: Geist, system-ui, -apple-system, 'Segoe UI', sans-serif;
        font-size: 15px; line-height: 1.6; color: #1a1a1a; background: transparent; overflow-wrap: break-word; }
      :where(a) { color: #6b3fa0; }
      :where(img) { max-width: 100%; height: auto; }
      :where(blockquote) { margin: .6em 0; padding: 0 0 0 1em; border-left: 2px solid #ddd6c8; color: #5e5a53; }
      :where(pre, code) { font-family: ui-monospace, 'SF Mono', Menlo, monospace; font-size: .9em; white-space: pre-wrap; }
      :where(hr) { border: 0; border-top: 1px solid #ddd6c8; }
      .sg-quote { display: none !important; }
      html.sg-show-quote .sg-quote { display: revert !important; }
      @media (prefers-color-scheme: dark) {
        html.sg-plain body { color: #f7f3ea; }
        html.sg-plain a { color: #c8adf0 !important; }
        html.sg-plain blockquote { border-color: #3a3833; color: #aaa59b; }
        html.sg-plain hr { border-top-color: #3a3833; }
        html.sg-plain :is([style*='color'], font[color]):not(a) { color: inherit !important; }
        /* La feuille claire a besoin d'une marge : sans elle, le texte colle au bord. */
        html.sg-designed body { background: #fff; padding: clamp(12px, 3vw, 22px) clamp(14px, 4vw, 26px); }
      }
    CSS
  end
end
