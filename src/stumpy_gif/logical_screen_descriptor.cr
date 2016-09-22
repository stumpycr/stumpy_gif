module StumpyGIF
  class LogicalScreenDescriptor
    property width : UInt16
    property height : UInt16

    property gct_flag : Bool
    property sort_flag : Bool
    property color_resolution : UInt8

    property background_color_index : UInt8
    property pixel_aspect_ration : UInt8

    def initialize
      @width = 0_u16
      @height = 0_u16
      @gct_flag = true
      @color_resolution = 8_u8
      @sort_flag = false
      @gct_size_value = 7_u8
      @background_color_index = 0_u8
      @pixel_aspect_ration = 0_u8
    end

    def gct_size
      gct_size = 2 ** (@gct_size_value + 1)
    end

    def gct_size=(value)
      log = Math.log2(value)
      if (log % 1.0) != 0.0
        raise "Invalid Global Color Table size: #{value}, must be a power of 2"
      else
        @gct_size_value = (log - 1).to_u8
      end
    end

    def read(io)
      @width = io.read_bytes(UInt16, IO::ByteFormat::LittleEndian)
      @height = io.read_bytes(UInt16, IO::ByteFormat::LittleEndian)
      packed_fields = io.read_bytes(UInt8, IO::ByteFormat::LittleEndian)

      # 0 -   No Global Color Table follows,
      #       the Background Color Index field is meaningless.
      # 1 -   A Global Color Table will immediately follow,
      #       the Background Color Index field is meaningful.
      @gct_flag = (packed_fields >> 7) == 1

      # Number of bits per primary color available to the original image, minus 1
      @color_resolution = ((packed_fields >> 4) & 0b111) + 1

      if @color_resolution != 8
        raise "Unsupported color resolution: #{@color_resolution}"
      end

      # Indicates whether the Global Color Table is sorted
      # (only relevant if we can display less than 256 colors)
      @sort_flag = ((packed_fields >> 3) & 0b1) == 1

      # Size of Global Color Table - If the Global Color Table Flag is
      # set to 1, the value in this field is used to calculate the number
      # of bytes contained in the Global Color Table. To determine that
      # actual size of the color table, raise 2 to [the value of the field + 1].
      @gct_size_value = packed_fields & 0b111

      # Background Color Index - Index into the Global Color Table for the Background Color
      # The Background Color is the color used for
      # those pixels on the screen that are not covered by an image. If the
      # Global Color Table Flag is set to (zero), this field should be zero
      # and should be ignored.
      @background_color_index = io.read_bytes(UInt8, IO::ByteFormat::LittleEndian)

      # Pixel Aspect Ratio
      # (for now, just hope it is 0 => pixel width = pixel height)
      @pixel_aspect_ration = io.read_bytes(UInt8, IO::ByteFormat::LittleEndian)
      if @pixel_aspect_ration != 0
        raise "Unsupported pixel aspect ratio: #{pixel_aspect_ration}"
      end
    end

    def write(io)
      io.write_bytes(@width, IO::ByteFormat::LittleEndian)
      io.write_bytes(@height, IO::ByteFormat::LittleEndian)

      packed_fields = 0_u8
      packed_fields |= 1 << 7 if @gct_flag
      packed_fields |= ((@color_resolution - 1) & 0b111) << 4
      packed_fields |= 1 << 3 if @sort_flag
      packed_fields |= @gct_size_value & 0b111

      io.write_bytes(packed_fields, IO::ByteFormat::LittleEndian)
      io.write_bytes(@background_color_index, IO::ByteFormat::LittleEndian)
      io.write_bytes(@pixel_aspect_ration, IO::ByteFormat::LittleEndian)
    end
  end
end
