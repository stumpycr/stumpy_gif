module StumpyGIF
  module Extension
    class Netscape
      property loop_count : UInt16
      def initialize(@loop_count = 0_u16)
      end

      def read(io)
        size = io.read_bytes(UInt8, IO::ByteFormat::LittleEndian)
        raise "Invalid netscape extension size: #{size}" if size != 11

        # Skip application name and auth code
        io.skip(11)

        sub_size = io.read_bytes(UInt8, IO::ByteFormat::LittleEndian)
        raise "Invalid netscape extension subblock size: #{sub_size}" if sub_size != 3

        sub_type = io.read_bytes(UInt8, IO::ByteFormat::LittleEndian)
        raise "Invalid netscape extension subblock type: #{sub_type}" if sub_type != 1

        @loop_count = io.read_bytes(UInt16, IO::ByteFormat::LittleEndian)

        terminator = io.read_bytes(UInt8, IO::ByteFormat::LittleEndian)
        raise "Invalid block terminator: #{terminator}" if terminator != 0
      end

      def write(io)
        puts "Writing netscape"
        # Extension header
        io.write_bytes(0x21_u8, IO::ByteFormat::LittleEndian)
        io.write_bytes(0xff_u8, IO::ByteFormat::LittleEndian)

        # Block size
        io.write_bytes(11_u8, IO::ByteFormat::LittleEndian)

        "NETSCAPE2.0".chars.each do |c|
          io.write_bytes(c.ord.to_u8, IO::ByteFormat::LittleEndian)
        end

        # Sub-block size
        io.write_bytes(3_u8, IO::ByteFormat::LittleEndian)

        # Loop sub-block
        io.write_bytes(1_u8, IO::ByteFormat::LittleEndian)

        # Loop as long as possible
        # TODO: make this customizable
        io.write_bytes(0x0_u16, IO::ByteFormat::LittleEndian)

        # Block terminator
        io.write_bytes(0_u8, IO::ByteFormat::LittleEndian)
      end
    end
  end
end
