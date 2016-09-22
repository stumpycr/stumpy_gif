require "stumpy_core"

module StumpyGIF
  module Websafe
    def self.colors
      colors = [] of StumpyCore::RGBA

      (0...6).each do |step_r|
        (0...6).each do |step_g|
          (0...6).each do |step_b|
            r = (255.0 / 5 * step_r).to_i
            g = (255.0 / 5 * step_g).to_i
            b = (255.0 / 5 * step_b).to_i

            colors << StumpyCore::RGBA.from_rgb_n({r, g, b}, 8)
          end
        end
      end

      until colors.size == 256
        colors << StumpyCore::RGBA.from_rgb_n({0, 0, 0}, 8)
      end
      
      colors
    end

    def self.make_websafe(color : StumpyCore::RGBA)
      r, g, b = color.to_rgb8

      r = make_websafe(r)
      g = make_websafe(g)
      b = make_websafe(b)

      StumpyCore::RGBA.from_rgb_n({r, g, b}, 8)
    end

    def self.make_websafe(value)
      (value / (255.0 / 5)).round * (255.0 / 5)
    end
  end
end
