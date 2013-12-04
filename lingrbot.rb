require "sinatra"
require "json"
require "mecab-mora"

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
  end
end
