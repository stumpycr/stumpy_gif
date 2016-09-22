require "minitest/autorun"
require "../src/stumpy_gif/bit_wrapper"

module StumpyGIF
  class BitWrapperTest < Minitest::Test
    def test_read
      bytes = [
        0b01110100_u8,
        0b00111001_u8
      ]
      wrapper = BitWrapper.new(bytes)

      assert_equal 0b00000100, wrapper.read_bits(3)
      assert_equal 0b00101110, wrapper.read_bits(7)
      assert_equal 0b00000010, wrapper.read_bits(2)
      assert_equal 0b00000001, wrapper.read_bits(1)
      assert_equal 0b00000001, wrapper.read_bits(3)
    end

    def test_read_more_than_8_bits
      bytes = [
        0b00000000_u8,
        0b00000001_u8
      ]
      wrapper = BitWrapper.new(bytes)

      assert_equal 0b100000000, wrapper.read_bits(9)
    end

    def test_write_bytes
      codes = [
        {0b01010011, 8},
        {0b10111000, 8},
      ]

      wrapper = BitWrapper.new([] of UInt8)
      wrapper.write_bits(codes)

      assert_equal codes.map(&.first), wrapper.bytes
    end

    def test_write_odd
      codes = [
        {0b00000100, 3},
        {0b00101110, 7},
        {0b00000010, 2},
        {0b00000001, 1},
        {0b00000001, 3},
      ]

      wrapper = BitWrapper.new([] of UInt8)
      wrapper.write_bits(codes)

      bytes = [
        0b01110100_u8,
        0b00111001_u8
      ]

      assert_equal bytes, wrapper.bytes
    end

    def test_write_padding
      codes = [
        {0b00000100, 3},
        {0b00101110, 7},
        {0b00000010, 2},
        {0b00000001, 1},
      ]

      wrapper = BitWrapper.new([] of UInt8)
      wrapper.write_bits(codes)

      bytes = [
        0b01110100_u8,
        0b00011001_u8
      ]

      assert_equal bytes, wrapper.bytes
    end

    def test_reload
      codes = [
        {0b00000100, 3},
        {0b100101110, 12},
        {0b00000010, 2},
        {0b00000001, 1},
      ]

      wrapper = BitWrapper.new([] of UInt8)
      wrapper.write_bits(codes)

      wrapper2 = BitWrapper.new(wrapper.bytes)

      assert_equal codes[0][0], wrapper2.read_bits(3)
      assert_equal codes[1][0], wrapper2.read_bits(12)
      assert_equal codes[2][0], wrapper2.read_bits(2)
      assert_equal codes[3][0], wrapper2.read_bits(1)
    end
  end
end
