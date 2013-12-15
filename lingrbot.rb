require "sinatra"
require "json"
require "mecab-mora"
require "shogi_koma"

post "/" do
  request_body = JSON.load(request.body)
  event = request_body["events"].first
  message = event["message"]
  text = message["text"]

  /^% ?(\w+) ?(.*)/ =~ text
  command = $1
  command_params = $2
  return unless command

  case command
  when /mecab/
    mecab(command_params)
  when /mora/
    mora(command_params)
  when /fc_list/
    fc_list
  when /shogikoma/
    shogikoma(command_params)
  end
end

helpers do
  def mecab(command_params)
    "#{MeCab::Tagger.new.parse(command_params).gsub(/EOS\n\z/, "")}"
  end

  def mora(command_params)
    "#{MeCab::Mora.new(command_params).count}"
  end

  def fc_list
    `fc-list`.force_encoding("utf-8").split(/\n/).collect {|f|
       f.split(/:/)[0].split(/,/)[0]
    }.reject {|f|
      /[ -]/ =~ f
    }.uniq.join(", ")
  end

  def shogikoma(command_params)
    image_uri = File.join("shogikoma", "#{Time.now.strftime("%Y%m%d%H%M%S")}.png")
    output_path = File.join(File.dirname(__FILE__), "public", image_uri)
    data, options = option_parse(command_params)
    # TODO: refactoring
    max_width  = 400
    max_height = 400
    if options[:width] && options[:width] > max_width
      options[:width] = max_width
    end
    if options[:height] && options[:height] > max_height
      options[:height] = max_height
    end
    painter = ShogiKoma::Painter.new
    painter.width = options[:width] || 200
    painter.height = options[:height] || options[:width] || 200
    painter.font = options[:font] || "IPAMincho"
    painter.set_text_color(options[:text_color]) if options[:text_color]
    painter.set_body_color(options[:body_color]) if options[:body_color]
    painter.set_frame_color(options[:frame_color]) if options[:frame_color]
    painter.write_to_png(data, output_path)
    "http://myokoym.net/lingrbot/#{image_uri}"
  end

  def option_parse(command_params)
    params = command_params.split(/\s/)
    options = {}
    require "optparse"
    parser = OptionParser.new
    parser.on("-f", "--font FONT") do |font|
      options[:font] = font
    end
    parser.on("--width LENGTH", Integer) do |length|
      options[:width] = length
    end
    parser.on("--height LENGTH", Integer) do |length|
      options[:height] = length
    end
    parser.on("--text-color COLOR") do |color|
      options[:text_color] = color
    end
    parser.on("--body-color COLOR") do |color|
      options[:body_color] = color
    end
    parser.on("--frame-color COLOR") do |color|
      options[:frame_color] = color
    end
    parser.parse!(params)
    [params.join(" "), options]
  end
end
