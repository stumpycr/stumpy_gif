require "../src/stumpy_gif"

frames = [] of StumpyCore::Canvas

(0..5).each do |z|
  canvas = StumpyCore::Canvas.new(256, 256)

  (0..255).each do |x|
    (0..255).each do |y|
      color = StumpyCore::RGBA.from_rgb_n([x, y, z * 51], 8)
      canvas[x, y] = color
    end
  end

  frames << canvas
end

StumpyGIF.write(frames, "rainbow_websafe.gif")
StumpyGIF.write(frames, "rainbow_median_split.gif", :median_split)
