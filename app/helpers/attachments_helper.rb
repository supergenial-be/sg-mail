module AttachmentsHelper
  # Famille d'un fichier, pour son icône et sa couleur.
  FAMILIES = {
    "pdf" => { types: %w[application/pdf], extensions: %w[pdf] },
    "image" => { types: %w[image/], extensions: %w[jpg jpeg png gif webp heic heif tif tiff bmp svg] },
    "sheet" => { types: %w[spreadsheet excel text/csv], extensions: %w[xls xlsx csv ods numbers] },
    "slides" => { types: %w[presentation powerpoint], extensions: %w[ppt pptx odp key] },
    "doc" => { types: %w[msword wordprocessing opendocument.text rtf text/plain], extensions: %w[doc docx odt rtf txt md pages] },
    "archive" => { types: %w[zip rar 7z tar gzip], extensions: %w[zip rar 7z tar gz tgz] },
    "calendar" => { types: %w[text/calendar], extensions: %w[ics] },
    "audio" => { types: %w[audio/], extensions: %w[mp3 m4a wav ogg] },
    "video" => { types: %w[video/], extensions: %w[mp4 mov webm avi] }
  }.freeze

  def attachment_family(attachment)
    type = attachment["content_type"].to_s.downcase
    extension = attachment_extension(attachment).downcase
    FAMILIES.find { |_, rule| rule[:types].any? { |part| type.include?(part) } || extension.in?(rule[:extensions]) }&.first || "other"
  end

  def attachment_extension(attachment)
    File.extname(attachment["filename"].to_s).delete_prefix(".").first(4).upcase
  end

  # La visionneuse montre les images et les PDF ; le serveur revérifie le vrai type à l'ouverture.
  def attachment_viewer_kind(attachment)
    case attachment["content_type"].to_s.downcase
    when *AttachmentServing::VIEWABLE_IMAGES then "image"
    when "application/pdf" then "pdf"
    end
  end

  def attachment_thumbnail?(attachment) = attachment_family(attachment).in?(%w[image pdf])

  # Le corps HTML, avec les images intégrées (cid:…) remplacées par leur adresse signée.
  def message_body_html(message)
    message.body_html.gsub(/(?<=["'(])cid:([^"'\s)>]+)/i) do
      inline_image_path(InlineImagesController.token_for(message, CGI.unescape(Regexp.last_match(1))), account_id: nil)
    end
  end

  # Le corps prêt pour l'iframe du fil, habillé aux couleurs de SG Mail (voir EmailDocument).
  def email_document(message)
    EmailDocument.new(message_body_html(message), font_url: asset_path("geist.woff2"))
  end
end
