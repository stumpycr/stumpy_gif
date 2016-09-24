require "stumpy_core"
require "set"
require "./utils"
require "./median_split"

module StumpyGIF
  class ColorTable
    property colors : Array(StumpyCore::RGBA)

    def initialize
      @colors = [] of StumpyCore::RGBA
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

    def self.median_split(frames)
      unique_colors = Set(StumpyCore::RGBA).new

      frames.each do |frame|
        frame.pixels.each do |color|
          unique_colors.add(color)
        end
      end

      ct = ColorTable.new
      ct.colors = MedianSplit.split(unique_colors.to_a).map do |split_colors|
        min, max = MedianSplit.min_max(split_colors)
        StumpyCore::RGBA.new(
          min.r + (max.r - min.r) / 2,
          min.g + (max.g - min.g) / 2,
          min.b + (max.b - min.b) / 2,
          UInt16::MAX
        )
      end

      while ct.colors.size < 256
        ct.colors << StumpyCore::RGBA.new(0_u16, 0_u16, 0_u16, UInt16::MAX)
      end

      ct
    end
  end
end
