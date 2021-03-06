require "sinatra"
require "json"
require "sinatra/json"
require "mecab-mora"
require "shogi_koma"
require "tanka_renderer"

post "/" do
  request_body = JSON.load(request.body)
  event = request_body["events"].first
  message = event["message"]
  text = message["text"]

  /^% ?(\w+)(?: (.*))?/ =~ text
  command = $1
  command_params = $2
  return unless command

  case command
  when /\Amecab\z/
    mecab(command_params)
  when /\Amora\z/
    mora(command_params)
  when /\Afc_list\z/
    fc_list
  when /\Ashogikoma\z/
    shogikoma(command_params)
  when /\Arender\z/
    tanka_renderer(command_params)
  end
end

get "/shogikoma.json" do
  output = "#{File.dirname(__FILE__)}/public/shogikoma/*.png"
  images = Dir[output].sort_by do |image|
    File.ctime(image)
  end
  json images.collect {|image| File.basename(image) }
end

delete "/shogikoma/:name" do |name|
  image = "#{File.dirname(__FILE__)}/public/shogikoma/#{name}.png"
  if /\A\d+\z/ !~ name
    400 # Bad request
  elsif File.exist?(image)
    File.delete(image)
    200 # HTTP Header
  else
    400 # Bad request
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
    `fc-list`.force_encoding("utf-8").split(/\n/).collect {|font_info|
       font_info.split(/:/)[0].split(/,/)[0]
    }.reject {|font_name|
      /[ -]/ =~ font_name
    }.select {|font_name|
      /^(Kouzan|Aoyagi|IPA|Motoya)/i =~ font_name
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
    painter.set_font(options[:font] || "IPAMincho")
    painter.set_text_color(options[:text_color]) if options[:text_color]
    painter.set_body_color(options[:body_color]) if options[:body_color]
    painter.set_frame_color(options[:frame_color]) if options[:frame_color]
    painter.write_to_png(data, output_path)
    "http://myokoym.net/lingrbot/#{image_uri}"
  end

  def tanka_renderer(command_params)
    image_uri = File.join("tanka_renderer", "#{Time.now.strftime("%Y%m%d%H%M%S")}.png")
    output_path = File.join(File.dirname(__FILE__), "public", image_uri)
    data, options = option_parse(command_params)
    renderer = TankaRenderer::Renderer::Image.new
    renderer.guess_font(options[:font] || "KouzanBrushFontOTF")
    renderer.width = options[:height] if options[:height]
    renderer.height = options[:width] if options[:width]
    renderer.text_color = options[:text_color] if options[:text_color]
    renderer.body_color = options[:body_color] if options[:body_color]
    renderer.vertical = false
    renderer.render(data, output_path)
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
