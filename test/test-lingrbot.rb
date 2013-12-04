class LingrbotTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    @app ||= Rack::Builder.parse_file(File.join(base_dir, "config.ru")).first
  end

  def test_parse
    post "/", File.read(File.join(fixtures_dir, "test_parse.json"))
    assert_true(last_response.ok?)
    assert_empty(last_response.body)
  end

  def test_mecab
    post "/", File.read(File.join(fixtures_dir, "test_mecab.json"))
    assert_true(last_response.ok?)
    assert_match(/\Ahoge\t.*(,.*){5}\n\z/, last_response.body)
  end  

  def test_mora
    post "/", File.read(File.join(fixtures_dir, "test_mora.json"))
    assert_true(last_response.ok?)
    assert_equal("0", last_response.body)
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
