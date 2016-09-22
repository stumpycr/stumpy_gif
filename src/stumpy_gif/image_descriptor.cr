module StumpyGIF
  class ImageDescriptor
    property left_position : UInt16
    property top_position : UInt16
    property width : UInt16
    property height : UInt16

    property lct_flag : Bool
    property interlace_flag : Bool
    property sort_flag : Bool

    property lct_size_value : UInt8

    def initialize
      @left_position = 0_u16
      @top_position = 0_u16
      @width = 0_u16
      @height = 0_u16

      @lct_flag = false
      @interlace_flag = false
      @sort_flag = false

      @lct_size_value = 0_u8
    end

    def lct_size
      lct_size = 2 ** (@lct_size_value + 1)
    end

    def lct_size=(value)
      log = Math.log2(value)
      if (log % 1.0) != 0.0
        raise "Invalid Global Color Table size: #{value}, must be a power of 2"
      else
        @lct_size_value = (log - 1).to_u8
      end
    end

    def read(io)
      @left_position = io.read_bytes(UInt16, IO::ByteFormat::LittleEndian)
      @top_position =  io.read_bytes(UInt16, IO::ByteFormat::LittleEndian)
      @width =         io.read_bytes(UInt16, IO::ByteFormat::LittleEndian)
      @height =        io.read_bytes(UInt16, IO::ByteFormat::LittleEndian)
      packed_fields =  io.read_bytes(UInt8, IO::ByteFormat::LittleEndian)

      # Local Color Table Flag - Indicates the presence of a Local Color
      # Table immediately following this Image Descripto
      @lct_flag = (packed_fields >> 7) == 1

      # Interlace Flag - Indicates if the image is interlaced.
      @interlace_flag = ((packed_fields >> 6) & 0b1) == 1
      raise "Unsupported interlace_flag: #{@interlace_flag}" if @interlace_flag

      # Sort Flag
      # (can be ignored, just like the gct sort flag)
      @sort_flag = ((packed_fields >> 5) & 0b1) == 1

      # Reserved, 2 bits

      # Size of Local Color Table
      @lct_size_value = packed_fields & 0b111
    end

    def write(io)
      io.write_bytes(@left_position, IO::ByteFormat::LittleEndian)
      io.write_bytes(@top_position, IO::ByteFormat::LittleEndian)
      io.write_bytes(@width, IO::ByteFormat::LittleEndian)
      io.write_bytes(@height, IO::ByteFormat::LittleEndian)

      packed_fields = 0_u8
      packed_fields |= 1 << 7 if @lct_flag
      packed_fields |= 1 << 6 if @interlace_flag
      packed_fields |= 1 << 5 if @sort_flag
      packed_fields |= @lct_size_value & 0b111

      io.write_bytes(packed_fields, IO::ByteFormat::LittleEndian)
    end
  end
end
