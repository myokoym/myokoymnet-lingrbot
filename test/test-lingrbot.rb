class LingrbotTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    @app ||= Rack::Builder.parse_file(File.join(base_dir, "config.ru")).first
  end

  def setup
    @request = File.read(File.join(fixtures_dir, "test-request.json"))
  end

  def test_parse
    post "/", @request
    assert_true(last_response.ok?)
    assert_empty(last_response.body)
  end

  def test_mecab
    post "/", @request.gsub("XXX", "%25mecab hoge")
    assert_true(last_response.ok?)
    assert_match(/\Ahoge\t.*(,.*){5}\n\z/, last_response.body)
  end

  def test_mora
    post "/", @request.gsub("XXX", "%25mora foo")
    assert_true(last_response.ok?)
    assert_equal("0", last_response.body)
  end

  def test_shogikoma
    post "/", @request.gsub("XXX", "%25shogikoma R")
    assert_true(last_response.ok?)
    assert_match(%r(\Ahttp://myokoym.net/lingrbot/shogikoma/\w+\.png\z),
                 last_response.body)
  end

  def test_shogikoma_with_font
    post "/", @request.gsub("XXX", "%25shogikoma --font KouzanBrushFontOTF R")
    assert_true(last_response.ok?)
    assert_match(%r(\Ahttp://myokoym.net/lingrbot/shogikoma/\w+\.png\z),
                 last_response.body)
  end

  private
  def base_dir
    File.expand_path(File.join(File.dirname(__FILE__), ".."))
  end

  def test_dir
    File.join(base_dir, "test")
  end

  def fixtures_dir
    File.join(test_dir, "fixtures")
  end
end
