require "stumpy_core"

module StumpyGIF
  module Utils
    def self.write_rgb(io, rgba)
      r, g, b = rgba.to_rgb8

      io.write_bytes(r, IO::ByteFormat::LittleEndian)
      io.write_bytes(g, IO::ByteFormat::LittleEndian)
      io.write_bytes(b, IO::ByteFormat::LittleEndian)
    end
  end
end
