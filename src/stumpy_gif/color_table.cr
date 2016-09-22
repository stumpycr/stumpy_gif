require "stumpy_core"
require "./utils"

module StumpyGIF
  class ColorTable
    property colors : Array(StumpyCore::RGBA)

    def initialize
      @colors = [] of RGBA
    end

    def read(size, io)
      @colors = Array(StumpyCore::RGBA).new(size) { Utils.read_rgb(io) }
    end

    def write(io)
      @colors.each do |color|
        Utils.write_rgb(io, color)
      end
    end

    def [](index)
      @colors[index]
    end

    def []=(index, value)
      @colors[index] = value
    end

    def closest_index(color)
      return @colors.index(Websafe.make_websafe(color)) || 0
      # TODO: fix this function
      # closest = @colors.min_by do |other|
        # (other.r.to_i32 - color.r.to_i32) ** 2 +
        # (other.g.to_i32- color.g.to_i32) ** 2 +
        # (other.b.to_i32 - color.b.to_i32) ** 2
      # end

      # @colors.index(closest) || 0
    end
  end
end
