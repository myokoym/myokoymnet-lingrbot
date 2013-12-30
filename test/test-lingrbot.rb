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

  def test_fc_list
    post "/", @request.gsub("XXX", "%25fc_list")
    assert_true(last_response.ok?)
    assert_match(/Mincho|OTF/, last_response.body)
  end

  class ShogikomaTest < self
    def test_plain
      post "/", @request.gsub("XXX", "%25shogikoma R")
      assert_true(last_response.ok?)
      assert_match(%r(\Ahttp://myokoym.net/lingrbot/shogikoma/\w+\.png\z),
                   last_response.body)
    end

    def test_font
      post "/", @request.gsub("XXX", "%25shogikoma --font KouzanBrushFontOTF R")
      assert_true(last_response.ok?)
      assert_match(%r(\Ahttp://myokoym.net/lingrbot/shogikoma/\w+\.png\z),
                   last_response.body)
    end

    def test_width_and_height
      post "/", @request.gsub("XXX", "%25shogikoma --width 100 --height 100 FU")
      assert_true(last_response.ok?)
      assert_match(%r(\Ahttp://myokoym.net/lingrbot/shogikoma/\w+\.png\z),
                   last_response.body)
    end

    def test_max_width_and_max_height
      post "/", @request.gsub("XXX", "%25shogikoma --width 500 --height 500 FU")
      assert_true(last_response.ok?)
      assert_match(%r(\Ahttp://myokoym.net/lingrbot/shogikoma/\w+\.png\z),
                   last_response.body)
    end

    def test_text_color
      post "/", @request.gsub("XXX", "%25shogikoma --text-color red To")
      assert_true(last_response.ok?)
      assert_match(%r(\Ahttp://myokoym.net/lingrbot/shogikoma/\w+\.png\z),
                   last_response.body)
    end

    def test_body_color
      post "/", @request.gsub("XXX", "%25shogikoma --body-color gray FU")
      assert_true(last_response.ok?)
      assert_match(%r(\Ahttp://myokoym.net/lingrbot/shogikoma/\w+\.png\z),
                   last_response.body)
    end

    def test_frame_color
      post "/", @request.gsub("XXX", "%25shogikoma --frame-color #00CCFF FU")
      assert_true(last_response.ok?)
      assert_match(%r(\Ahttp://myokoym.net/lingrbot/shogikoma/\w+\.png\z),
                   last_response.body)
    end
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
