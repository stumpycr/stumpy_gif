require "stumpy_core"
require "./utils"

module StumpyGIF
  class ColorTable
    property colors : Array(StumpyCore::RGBA)

    def initialize
      @colors = [] of RGBA
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
      closest = @colors.min_by do |other|
        (other.r.to_i64 - color.r.to_i64) ** 2 +
        (other.g.to_i64- color.g.to_i64) ** 2 +
        (other.b.to_i64 - color.b.to_i64) ** 2
      end

      @colors.index(closest) || 0
    end
  end
end
