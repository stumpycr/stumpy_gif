require "minitest/autorun"
require "../src/stumpy_gif/lzw"

module StumpyGIF
  class LZWTest < Minitest::Test
    def test_empty_encode
      bytes = [] of UInt8
      lzw = LZW.new(8_u8)
      assert_equal [0x100, 0x101], lzw.encode(bytes).map(&.first)
    end

    def test_empty_decode
      wrapper = BitWrapper.new
      wrapper.write_bits([
        {0x100, 9},
        {0x101, 9}
      ])

      lzw = LZW.new(8_u8)
      assert_equal [] of UInt8, lzw.decode(wrapper.bytes)
    end

    def test_one_byte_encode
      bytes = [0x28_u8]
      lzw = LZW.new(8_u8)
      assert_equal [0x100, 0x28, 0x101], lzw.encode(bytes).map(&.first)
    end

    def test_one_byte_decode
      wrapper = BitWrapper.new
      wrapper.write_bits([
        {0x100, 9},
        {0x028, 9},
        {0x101, 9}
      ])

      lzw = LZW.new(8_u8)
      assert_equal [0x28], lzw.decode(wrapper.bytes)
    end

    def test_two_byte_encode
      bytes = [0x28_u8, 0xff_u8]
      lzw = LZW.new(8_u8)
      assert_equal [0x100, 0x28, 0xff, 0x101], lzw.encode(bytes).map(&.first)
    end

    def test_two_byte_decode
      wrapper = BitWrapper.new
      wrapper.write_bits([
        {0x100, 9},
        {0x028, 9},
        {0x0ff, 9},
        {0x101, 9}
      ])

      lzw = LZW.new(8_u8)
      assert_equal [0x28, 0xff], lzw.decode(wrapper.bytes)
    end

    def test_full_encode
      bytes = [
        0x28_u8, 0xff_u8, 0xff_u8, 0xff_u8,
        0x28_u8, 0xff_u8, 0xff_u8, 0xff_u8,
        0xff_u8, 0xff_u8, 0xff_u8, 0xff_u8,
        0xff_u8, 0xff_u8, 0xff_u8,
      ]
      lzw = LZW.new(8_u8)

      expected = [
        {0x100, 9},
        {0x028, 9},
        {0x0ff, 9},
        {0x103, 9},
        {0x102, 9},
        {0x103, 9},
        {0x106, 9},
        {0x107, 9},
        {0x101, 9}
      ]

      assert_equal expected, lzw.encode(bytes)
    end

    def test_full_decode
      wrapper = BitWrapper.new
      wrapper.write_bits([
        {0x100, 9},
        {0x028, 9},
        {0x0ff, 9},
        {0x103, 9},
        {0x102, 9},
        {0x103, 9},
        {0x106, 9},
        {0x107, 9},
        {0x101, 9}
      ])

      expected = [
        0x28, 0xff, 0xff, 0xff,
        0x28, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff,
      ]

      lzw = LZW.new(8_u8) 
      assert_equal expected, lzw.decode(wrapper.bytes)
    end
  end
end
