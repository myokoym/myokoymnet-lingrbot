require "sinatra"
require "json"
require "mecab-mora"
require "shogi_koma"

post "/" do
  request_body = JSON.load(request.body)
  event = request_body["events"].first
  message = event["message"]
  text = message["text"]

  /^% ?(\w+) (.*)/ =~ text
  command = $1
  command_params = $2
  return unless command

  case command
  when /mecab/
    "#{MeCab::Tagger.new.parse(command_params).gsub(/EOS\n\z/, "")}"
  when /mora/
    "#{MeCab::Mora.new(command_params).count}"
  when /shogikoma/
    return "shogikoma: it supports one or two characters." if command_params.length > 2
    image_uri = File.join("shogikoma", "#{Time.now.strftime("%Y%m%d%H%M%S")}.png")
    output_path = File.join(File.dirname(__FILE__), 
                            "public",
                            image_uri)
    painter = ShogiKoma::Painter.new
    painter.width = 200
    painter.height = 200
    painter.font = "IPAMincho"
    painter.write_to_png(command_params, output_path)
    "http://myokoym.net/lingrbot/#{image_uri}"
  end
end
