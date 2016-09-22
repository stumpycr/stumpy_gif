require "stumpy_core"
require "./image_descriptor"
require "./color_table"

module StumpyGIF
  class Image
    property descriptor : ImageDescriptor
    property canvas : StumpyCore::Canvas
    property local_color_table : ColorTable
    property global_color_table : ColorTable

    def initialize(@global_color_table)
      @descriptor = ImageDescriptor.new
      @canvas = StumpyCore::Canvas.new(1, 1)
      @local_color_table = ColorTable.new
      @indizes = [] of UInt8
    end

    def write(io)
      puts "Writing image"
      io.write_bytes(0x2c_u8, IO::ByteFormat::LittleEndian)
      @descriptor.write(io)
      @local_color_table.write(io) if @descriptor.lct_flag

      lzw_min_code_size = 8_u8
      output = [] of UInt8

      x = 0
      y = 0

      io.write_bytes(lzw_min_code_size, IO::ByteFormat::LittleEndian)
      
      canvas.pixels.each do |pixel|
        index = @global_color_table.closest_index(pixel)
        output << index.to_u8
      end

      lzw = LZW.new(lzw_min_code_size)

      # wrapper = BitWrapper.new
      # wrapper.write_bits(lzw.encode(output))

      # bytes = wrapper.bytes
      bytes = lzw.encode(output)

      bytes.each_slice(255) do |block|
        io.write_bytes(block.size.to_u8, IO::ByteFormat::LittleEndian)
        block.each do |byte|
          io.write_bytes(byte, IO::ByteFormat::LittleEndian)
        end
      end

      # Empty block as terminator
      io.write_bytes(0_u8, IO::ByteFormat::LittleEndian)
    end

    def read(io)
      @descriptor.read(io)
      @local_color_table.read(@descriptor.lct_size, io) if @descriptor.lct_flag

      # The image data for a table based image consists of a
      # sequence of sub-blocks, of size at most 255 bytes each, containing an
      #  index into the active color table, for each pixel in the image.  Pixel
      #  indices are in order of left to right and from top to bottom.  Each index
      #  must be within the range of the size of the active color table, starting
      #  at 0. The sequence of indices is encoded using the LZW Algorithm with
      #  variable-length code, as described in Appendix F

      lzw_min_code_size = io.read_bytes(UInt8, IO::ByteFormat::LittleEndian)
      raw = [] of UInt8

      loop do
        block_size = io.read_bytes(UInt8, IO::ByteFormat::LittleEndian)
        break if block_size == 0

        block = Slice(UInt8).new(block_size)
        io.read_fully(block)
        raw += block.to_a
      end

      lzw = LZW.new(lzw_min_code_size)
      data = lzw.decode(raw)

      @canvas = StumpyCore::Canvas.new(@descriptor.width.to_i32, @descriptor.height.to_i32)

      x = 0
      y = 0
      data.each do |index|
        if @descriptor.lct_flag
          color = @local_color_table[index]
        else
          color = @global_color_table[index]
        end

        @canvas[x, y] = color

        x += 1
        if x == @descriptor.width
          x = 0
          y += 1
        end
      end
    end
  end
end
