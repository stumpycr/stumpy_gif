require "stumpy_core"
require "stumpy_png"
require "./stumpy_gif/lzw"
require "./stumpy_gif/logical_screen_descriptor"
require "./stumpy_gif/color_table"
require "./stumpy_gif/image"
require "./stumpy_gif/extension/*"
require "./stumpy_gif/websafe"

include StumpyCore

module StumpyGIF
  def self.read(filename)
    gif = GIF.new
    File.open(filename) do |io|
      gif.read(io)
    end
    gif
  end

  def self.write(frames, filename)
    canvas = frames.first
    gif = GIF.new
    gif.logical_screen_descriptor.width = canvas.width.to_u16
    gif.logical_screen_descriptor.height = canvas.height.to_u16
    gif.logical_screen_descriptor.gct_flag = true

    gct = ColorTable.new
    gct.colors = Websafe.colors

    gif.global_color_table = gct

    frames.each do |canvas|
      image = Image.new(gct)
      image.descriptor.width = canvas.width.to_u16
      image.descriptor.height = canvas.height.to_u16
      image.canvas = canvas
      gif.frames << image

      gce = Extension::GraphicControl.new
      gce.delay_time = 10_u16

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

    def read(io : IO)
      # The gif header is 6 bytes long,
      # so we check the 4 bytes of it (UInt32)
      # and then the rest (2 bytes, UInt16)
      header_1 = io.read_bytes(UInt32, IO::ByteFormat::BigEndian)
      header_2 = io.read_bytes(UInt16, IO::ByteFormat::BigEndian)
      raise "Invalid header" if header_1 != HEADER_1
      raise "Invalid header" if header_2 != HEADER_2_89 && header_2 != HEADER_2_87

      @logical_screen_descriptor.read(io)

      if @logical_screen_descriptor.gct_flag
        @global_color_table.read(@logical_screen_descriptor.gct_size, io)
      end

      loop do
        begin
          type = io.read_bytes(UInt8, IO::ByteFormat::LittleEndian)
          if type == 0x2c
            puts "Image"
            image = Image.new(@global_color_table)
            image.read(io)
            @frames << image
          elsif type == 0x21 # Extension block
            ext_type = io.read_bytes(UInt8, IO::ByteFormat::LittleEndian)
            if ext_type == 0xf9 # Graphic Control Extension
              puts "GCE"
              gce = Extension::GraphicControl.new
              gce.read(io)

              @gces << gce
            elsif ext_type == 0xff
              puts "Netscape"
              nets = Extension::Netscape.new
              nets.read(io)
            else
              # TODO: try to handle unknown extensions
              raise "Unknown extension type: #{ext_type}"
            end
          elsif type == 0x3b
            break
          else
            raise "Invalid byte: 0x#{type.to_s(16)}"
          end
        rescue e : IO::EOFError
          raise "Error, EOF"
          break
        end
      end
    end
  end
end
