require "stumpy_core"

module StumpyGIF
  module Utils
    def self.read_rgb(io)
      r = io.read_bytes(UInt8, IO::ByteFormat::LittleEndian)
      g = io.read_bytes(UInt8, IO::ByteFormat::LittleEndian)
      b = io.read_bytes(UInt8, IO::ByteFormat::LittleEndian)

      RGBA.from_rgb_n(r, g, b, 8)
    end

    def self.write_rgb(io, rgba)
      r, g, b = rgba.to_rgb8

      io.write_bytes(r, IO::ByteFormat::LittleEndian)
      io.write_bytes(g, IO::ByteFormat::LittleEndian)
      io.write_bytes(b, IO::ByteFormat::LittleEndian)
    end
  end
end
