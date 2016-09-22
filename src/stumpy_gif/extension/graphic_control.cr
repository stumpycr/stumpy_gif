module StumpyGIF
  module Extension
    class GraphicControl
      property disposal_method : UInt8
      property user_input_flag : Bool
      property transparent_color_flag : Bool

      property delay_time : UInt16
      property transparent_color_index : UInt8

      def initialize
        @disposal_method = 0_u8
        @user_input_flag = false
        @transparent_color_flag = false
        @transparent_color_index = 0_u8
        @delay_time = 0_u16
      end

      def read(io)
        size = io.read_bytes(UInt8, IO::ByteFormat::LittleEndian)
        raise "Invalid GCE siez: #{size}" if size != 4

        packed_fields = io.read_bytes(UInt8, IO::ByteFormat::LittleEndian)

        # 0 - No disposal specified. The decoder is not required to take any action.
        # 1 - Do not dispose. The graphic is to be left in place.
        # 2 - Restore to background color. The area used by the
        #     graphic must be restored to the background color.
        # 3 - Restore to previous. The decoder is required to
        #     restore the area overwritten by the graphic with
        #     what was there prior to rendering the graphic.
        # 4-7 - To be defined.
        @disposal_method = (packed_fields >> 2) & 0b111
        if @disposal_method != 0 && @disposal_method != 1
          raise "Unsupported disposal_method #{@disposal_method}"
        end

        # 0 - User input is not expected.
        # 1 - User input is expected.
        @user_input_flag = ((packed_fields >> 1) & 0b1) == 1
        if @user_input_flag
          raise "Unsupported user_input_flag: #{@user_input_flag}"
        end

        # 0 - Transparent Index is not given.
        # 1 - Transparent Index is given.
        @transparent_color_flag = (packed_fields & 0b1) == 1

        # If not 0, this field specifies the number of
        # hundredths (1/100) of a second to wait before continuing with the
        # processing of the Data Stream.
        @delay_time = io.read_bytes(UInt16, IO::ByteFormat::LittleEndian)

        # if @transparent_color_flag
          @transparent_color_index = io.read_bytes(UInt8, IO::ByteFormat::LittleEndian)
        # end

        terminator = io.read_bytes(UInt8, IO::ByteFormat::LittleEndian)
        raise "Invalid block terminator: #{terminator}" if terminator != 0
      end

      def write(io)
        # Extension header
        io.write_bytes(0x21_u8, IO::ByteFormat::LittleEndian)
        io.write_bytes(0xf9_u8, IO::ByteFormat::LittleEndian)

        # Block size
        io.write_bytes(4_u8, IO::ByteFormat::LittleEndian)

        packed_fields = 0_u8
        packed_fields |= @disposal_method << 2
        packed_fields |= 1 << 1 if @user_input_flag
        packed_fields |= 1 if @transparent_color_flag

        io.write_bytes(packed_fields, IO::ByteFormat::LittleEndian)
        io.write_bytes(@delay_time, IO::ByteFormat::LittleEndian)

        # if @transparent_color_flag
          io.write_bytes(@transparent_color_index, IO::ByteFormat::LittleEndian)
        # end

        # Terminator
        io.write_bytes(0_u8, IO::ByteFormat::LittleEndian)
      end
    end
  end
end
