require "test_helper"

class EmailDocumentTest < ActiveSupport::TestCase
  GMAIL_REPLY = <<~HTML
    <div dir="ltr">Hello Laurence,<div>Bon courage !</div></div><br>
    <div class="gmail_quote"><div class="gmail_attr">Le dim. 25 oct. 2026, Laurence a écrit :</div>
    <blockquote class="gmail_quote">Hello, <a href="https://example.org">lien</a></blockquote></div>
  HTML

  test "the base stylesheet comes first and cannot outweigh the sender's styles" do
    html = EmailDocument.new("<html><head><style>body { font-family: Georgia }</style></head><body>Salut</body></html>", font_url: "/assets/geist.woff2").to_html
    document = Nokogiri::HTML5(html)
    styles = document.css("head style")

    assert_equal 2, styles.size
    assert_includes styles.first.text, ":where(body) { margin: 0; padding: 0; font-family: Geist"
    assert_includes styles.first.text, "url('/assets/geist.woff2')"
    assert_includes styles.last.text, "Georgia"
  end

  test "a plain email takes the app colours, a designed one keeps its light sheet" do
    plain = EmailDocument.new(GMAIL_REPLY)
    designed = EmailDocument.new(%(<table bgcolor="#ffffff"><tr><td>Promo</td></tr></table>))

    assert_not plain.designed?
    assert_includes plain.to_html, %(class="sg-plain")
    assert_includes plain.to_html, %(content="light dark")
    assert designed.designed?
    assert_includes designed.to_html, %(class="sg-designed")
    assert_match(/html\.sg-designed body \{ background: #fff; padding: /, designed.to_html)
    assert EmailDocument.new(%(<div style="background-color: #fde">x</div>)).designed?
    assert_not EmailDocument.new(%(<div style="background: transparent">x</div>)).designed?
  end

  test "links open in a new tab without a referrer" do
    link = Nokogiri::HTML5(EmailDocument.new(GMAIL_REPLY).to_html).at("a")

    assert_equal "_blank", link["target"]
    assert_equal "noopener noreferrer", link["rel"]
  end

  test "the quoted text of a reply is folded away" do
    email = EmailDocument.new(GMAIL_REPLY)
    document = Nokogiri::HTML5(email.to_html)

    assert email.quoted?
    assert_includes document.at("div.gmail_quote")["class"], "sg-quote"
    assert_not document.at("div[dir=ltr]")["class"].to_s.include?("sg-quote")
  end

  test "Outlook quotes everything after its header" do
    email = EmailDocument.new(<<~HTML)
      <div>Merci !</div><hr><div id="divRplyFwdMsg"><b>De :</b> Eric</div><div>Texte d'origine</div>
    HTML
    document = Nokogiri::HTML5(email.to_html)

    assert email.quoted?
    assert_equal [ "hr", "div", "div" ], document.css(".sg-quote").map(&:name)
  end

  test "a forward or a quote alone stays visible" do
    forward = EmailDocument.new(<<~HTML)
      <div class="gmail_quote"><div class="gmail_attr">---------- Forwarded message ---------<br>De : Eric</div>Programme</div>
    HTML
    quote_only = EmailDocument.new(%(<blockquote type="cite">Rien que la citation</blockquote>))

    assert_not forward.quoted?
    assert_not quote_only.quoted?
    assert_not_includes quote_only.to_html, "sg-quote\""
  end
end
