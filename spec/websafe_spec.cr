require "minitest/autorun"
require "../src/stumpy_gif/websafe"

module StumpyGIF
  class WebsafeTest < Minitest::Test
    def test_colors
      assert_equal 216, Websafe.colors.size
    end

    def test_make_websafe
      # Steps: 0, 51, 102, 153, 204, 255

      assert_equal 0, Websafe.make_websafe(0)
      assert_equal 0, Websafe.make_websafe(10)
      assert_equal 0, Websafe.make_websafe(25)

      assert_equal 51, Websafe.make_websafe(26)
      assert_equal 51, Websafe.make_websafe(50)
      assert_equal 51, Websafe.make_websafe(75)

      assert_equal 102, Websafe.make_websafe(77)

      assert_equal 255, Websafe.make_websafe(230)
    end
  end
end
