require "stumpy_core"
require "./stumpy_gif/lzw"
require "./stumpy_gif/logical_screen_descriptor"
require "./stumpy_gif/color_table"
require "./stumpy_gif/image"
require "./stumpy_gif/extension/*"
require "./stumpy_gif/websafe"

include StumpyCore

module StumpyGIF
  def self.write(frames, filename, delay_time = 10, quantization = :websafe)
    canvas = frames.first
    gif = GIF.new
    gif.logical_screen_descriptor.width = canvas.width.to_u16
    gif.logical_screen_descriptor.height = canvas.height.to_u16
    gif.logical_screen_descriptor.gct_flag = true

    case quantization
    when :websafe
      gct = ColorTable.new
      gct.colors = Websafe.colors
    when :median_split
      gct = ColorTable.median_split(frames)
    else
      raise "Unknown quantization method: #{quantization}"
    end

    gif.global_color_table = gct

    frames.each do |canvas|
      image = Image.new(gct)
      image.descriptor.width = canvas.width.to_u16
      image.descriptor.height = canvas.height.to_u16
      image.canvas = canvas
      gif.frames << image

      gce = Extension::GraphicControl.new
      gce.delay_time = delay_time.to_u16

      gif.gces << gce
    end

    File.open(filename, "w") do |file|
      gif.write(file)
    end
  end

  class GIF
    HEADER_1 = 0x47494638_u32
    HEADER_2_89 = 0x3961_u16
    HEADER_2_87 = 0x3761_u16

    property logical_screen_descriptor : LogicalScreenDescriptor
    property global_color_table : ColorTable
    property frames : Array(Image)
    property gces : Array(Extension::GraphicControl)

    def initialize
      @logical_screen_descriptor = LogicalScreenDescriptor.new
      @global_color_table = ColorTable.new
      @frames = [] of Image
      @gces = [] of Extension::GraphicControl
    end

    def write(io : IO)
      io.write_bytes(HEADER_1, IO::ByteFormat::BigEndian)
      io.write_bytes(HEADER_2_89, IO::ByteFormat::BigEndian)

      @logical_screen_descriptor.write(io)
      if @logical_screen_descriptor.gct_flag
        @global_color_table.write(io)
      end

      Extension::Netscape.new.write(io)

      @frames.each_with_index do |image, index|
        if index < @gces.size
          gce = @gces[index] || Extension::GraphicControl.new
          gce.write(io)
        else
          raise "Not enough GCE blocks"
        end

        image.write(io)
      end

      # Gif terminator
      io.write_bytes(0x3b_u8, IO::ByteFormat::LittleEndian)
    end
  end
end
