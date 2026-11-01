# Transforme un email brut (RFC 822) en attributs de Message.
class MessageParser
  SNIPPET_LENGTH = 200

  def self.parse(raw) = new(raw).attributes

  # Aperçu en texte brut, sans entités HTML : Gmail fournit le sien échappé (J&#39;ai, &quot;…&quot;),
  # et la vue l'échapperait une seconde fois.
  def self.snippet(text)
    decode_entities(text).squish.truncate(SNIPPET_LENGTH).presence
  end

  # Décode toutes les entités HTML nommées ou numériques (&nbsp;, &eacute;, &#39;…), sans toucher au reste :
  # un « <adresse@exemple.org> » dans du texte brut reste tel quel.
  def self.decode_entities(text)
    text.to_s.gsub(/&(?:[a-zA-Z][a-zA-Z0-9]*|#[0-9]+|#[xX][0-9a-fA-F]+);/) { |entity| Nokogiri::HTML5.fragment(entity).text }
  end

  def initialize(raw)
    @raw = raw.to_s.b
    @mail = Mail.new(@raw)
  end

  def attributes
    {
      message_id_header: @mail.message_id,
      thread_key: thread_key,
      subject: clean(@mail.subject),
      from_address: @mail.from&.first,
      from_name: from_name,
      to_addresses: Array(@mail.to),
      cc_addresses: Array(@mail.cc),
      sent_at: sent_at,
      body_text: body_text,
      body_html: body_html,
      snippet: self.class.snippet(body_text.presence || html_as_text),
      size: @raw.bytesize,
      has_attachments: @mail.attachments.any?,
      attachments: attachments
    }
  end

  # Les pièces jointes elles-mêmes restent chez le fournisseur : on ne garde que de quoi les lister.
  # content_id relie une image intégrée au corps HTML (<img src="cid:…">) ; inline dit que l'expéditeur l'a
  # placée dans le corps plutôt qu'en pièce jointe (toujours présent : son absence marque une ancienne liste).
  def attachments
    @mail.attachments.each_with_index.map do |part, index|
      content_id = (clean(part.content_id)&.delete("<>").presence if part.has_content_id?)
      { "index" => index, "filename" => clean(part.filename).presence || "piece-jointe-#{index + 1}",
        "content_type" => part.mime_type, "size" => part.body.decoded.bytesize,
        "content_id" => content_id, "inline" => part.inline? || content_id.present? }.compact
    end
  rescue StandardError
    []
  end

  # Contenu d'une pièce jointe, dans l'ordre de #attachments.
  def attachment_data(index) = @mail.attachments[index]&.decoded

  private

  # Approximation pour l'IMAP : le premier message du fil sert de clé.
  def thread_key
    Array(@mail.references).first.presence || Array(@mail.in_reply_to).first.presence || @mail.message_id
  end

  def from_name
    field = @mail[:from]
    clean(field.display_names.first) if field.respond_to?(:display_names)
  rescue StandardError
    nil
  end

  def sent_at
    @mail.date&.to_time
  rescue StandardError
    nil
  end

  def body_text
    @body_text ||= decoded_part("text/plain")
  end

  def body_html
    @body_html ||= decoded_part("text/html")
  end

  # Pour les messages sans partie texte : le texte visible, entités décodées.
  def html_as_text
    document = Nokogiri::HTML5(body_html.to_s)
    document.css("head, style, script").remove
    document.css("br, p, div, li, tr").each { |node| node.add_previous_sibling(" ") }
    document.text
  rescue StandardError
    nil
  end

  def decoded_part(mime_type)
    part =
      if @mail.multipart?
        mime_type == "text/plain" ? @mail.text_part : @mail.html_part
      elsif @mail.mime_type.to_s.downcase == mime_type || (@mail.mime_type.nil? && mime_type == "text/plain")
        @mail
      end
    clean(part&.decoded)
  rescue StandardError
    nil
  end

  # Postgres refuse les octets nuls et l'UTF-8 invalide.
  def clean(string)
    return if string.nil?

    string = string.to_s
    unless [ Encoding::UTF_8, Encoding::BINARY, Encoding::US_ASCII ].include?(string.encoding)
      string = string.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "")
    end
    string.dup.force_encoding(Encoding::UTF_8).scrub("").delete("\u0000")
  end
end
