require "test_helper"

class MessageAttachmentsTest < ActiveSupport::TestCase
  BODY = %(<p>Bonjour</p><img src="cid:facebook@sg">)

  def listed(attachments, body_html: BODY)
    with_account(accounts(:semisto)) { Message.new(attachments: attachments, body_html: body_html).listed_attachments.map { |a| a["filename"] } }
  end

  test "leaves out the images of the body, even one only a quoted message called" do
    attachments = [
      { "filename" => "facebook.jpg", "content_type" => "image/jpeg", "size" => 6_000, "content_id" => "facebook@sg", "inline" => true },
      { "filename" => "Outlook-bzvq41yk.png", "content_type" => "image/png", "size" => 5_500, "content_id" => "outlook@sg", "inline" => true },
      { "filename" => "rapport.pdf", "content_type" => "application/pdf", "size" => 14_000_000, "inline" => false },
      { "filename" => "photo.jpg", "content_type" => "image/jpeg", "size" => 2_000_000, "inline" => false }
    ]
    assert_equal %w[rapport.pdf photo.jpg], listed(attachments)
  end

  test "an inline image stays an attachment when the body shows no image at all" do
    attachments = [ { "filename" => "photo.jpg", "content_type" => "image/jpeg", "size" => 5_000, "content_id" => "x@sg", "inline" => true } ]
    assert_equal %w[photo.jpg], listed(attachments, body_html: "<p>Voici la photo</p>")
    assert_equal %w[photo.jpg], listed(attachments, body_html: nil)
  end

  test "lists saved before the inline flag: signature names, Content-ID or small images are left out" do
    attachments = [
      { "filename" => "Outlook-bzvq41yk.png", "content_type" => "image/png", "size" => 5_500 },
      { "filename" => "instagram.jpg", "content_type" => "image/jpeg", "size" => 8_100 },
      { "filename" => "chantier.jpg", "content_type" => "image/jpeg", "size" => 1_800_000, "content_id" => "c@sg" },
      { "filename" => "tampon.png", "content_type" => "image/png", "size" => 12_000 },
      { "filename" => "chantier-2.jpg", "content_type" => "image/jpeg", "size" => 2_400_000 },
      { "filename" => "rapport.pdf", "content_type" => "application/pdf", "size" => 3_000 }
    ]
    assert_equal %w[chantier-2.jpg rapport.pdf], listed(attachments)
  end

  test "the parser flags images placed in the body" do
    mail = Mail.new do
      html_part { content_type "text/html; charset=UTF-8"; body %(<img src="cid:logo@sg">) }
    end
    mail.attachments.inline["logo.png"] = { mime_type: "image/png", content: "png" }
    mail.attachments["devis.pdf"] = { mime_type: "application/pdf", content: "%PDF-1.4" }
    attachments = MessageParser.new(mail.to_s).attachments

    assert_equal [ true, false ], attachments.map { |a| a["inline"] }
    assert attachments.first["content_id"].present?
    assert_nil attachments.last["content_id"]
  end
end
