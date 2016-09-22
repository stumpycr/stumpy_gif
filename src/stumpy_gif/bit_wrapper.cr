module StumpyGIF
  class BitWrapper
    property byte_pointer : Int32
    property bit_pointer : Int32
    property bytes : Array(UInt8)

    def initialize(@bytes = [] of UInt8)
      @byte_pointer = 0
      @bit_pointer = 0
    end

    def current
      (@bytes[@byte_pointer].to_u16 >> @bit_pointer) & 0b1
    end

    def write_bits(values)
      current_byte = 0_u8
      values.each do |value, n|
        n.times do |i|
          current_byte += ((value.to_u64 >> i) & 0b1) << @bit_pointer
          @bit_pointer += 1

          if @bit_pointer == 8
            bytes << current_byte
            current_byte = 0_u8
            @bit_pointer = 0
            @byte_pointer += 1
          end
        end
      end

      if @bit_pointer != 0
        bytes << current_byte
      end

      rewind
    end

    def rewind
      @bit_pointer = 0
      @byte_pointer = 0
    end

    def read_bits(n)
      result = 0_u32

      n.times do |i|
        result += (current << i)
        @bit_pointer += 1

        if @bit_pointer == 8
          @bit_pointer = 0
          @byte_pointer += 1
        end
      end

      result
    end
  end
end
