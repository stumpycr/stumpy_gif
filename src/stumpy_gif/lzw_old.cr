require "./bit_wrapper"

module StumpyGIF
  class LZW
    property min_code_size : UInt8
    property table : Array(Array(UInt8))

    property clear_code : UInt16
    property eoi_code : UInt16

    property current_size : UInt8

    def initialize(@min_code_size)
      @table = [] of Array(UInt8)

      @clear_code = (2 ** @min_code_size).to_u16
      @eoi_code = @clear_code + 1 # End of Information code

      @current_size = @min_code_size + 1

      256.times do |i|
        @table << [i.to_u8]
      end

      # @table << [@clear_code]
      # @table << [@eoi_code]

      # Use placeholders instead
      @table << [0_u8]
      @table << [0_u8]

      @local_string = [] of UInt8
    end

    def add_code(code)
      @table << code
      @current_size += 1 if @table.size > 2 ** @current_size
      puts "#{(@table.size - 1).to_s(16)}: #{code}"
    end

    def encode(stream)
      # This is pretty fucked up right now,
      # the algorithm was adapdet from
      # https://en.wikipedia.org/wiki/GIF

      # Array of {Code padded with 0 to a length of 16, real length
      codes = [] of Tuple(UInt16, UInt8)
      codes << {@clear_code, @current_size}

      local_string = [] of UInt8
      prev_code = 0
      last_found_in_table = false

      # Always output first pixel
      codes << {stream[0].to_u16, @current_size} if stream.size >= 1

      if stream.size >= 2
        last_found_in_table = true
        # Special treatment of the first 2 bytes
        add_code(stream[0, 2])
        local_string = [stream[1]]
        prev_code = stream[1]

        stream[2..-1].each do |byte|
          prev_string = local_string.clone
          local_string << byte
          current_code = @table.index(local_string)

          if current_code.nil?
            last_found_in_table = false

            codes << {prev_code.to_u16, @current_size}
            add_code(local_string)

            local_string = local_string[-1, 1]
          else
            last_found_in_table = true
            prev_code = current_code
          end
        end
      end

      codes << {prev_code.to_u16, @current_size} if last_found_in_table
      codes << {@eoi_code, @current_size}

      codes
    end

    def decode(stream)
      wrapper = BitWrapper.new(stream.to_a)
      output = [] of UInt32

      clear_code = wrapper.read_bits(@current_size)
      raise "Invalid LZW stream" if clear_code != @clear_code

      local_code = 0

      incoming_code = wrapper.read_bits(@current_size)
      return output if incoming_code == @eoi_code
      foo = incoming_code

      output << incoming_code
      incoming_code = wrapper.read_bits(@current_size)
      return output if incoming_code == @eoi_code
      output << incoming_code

      local_code = incoming_code
      add_code([foo.to_u8, incoming_code.to_u8])

      loop do
        incoming_code = wrapper.read_bits(@current_size)
        break if incoming_code == @eoi_code

        # Is incoming code found in table?
        #   YES: add string for local code followed by first byte of string for incoming code
        #   NO:  add string for local code followed by copy of its own first byte
        if incoming_code >= @table.size
          incoming = nil
        else
          incoming = @table[incoming_code]
        end

        if local_code >= @table.size
          puts local_code
          local = nil
          raise "Error"
        else
          local = @table[local_code]
        end

        if incoming.nil?
          puts "incoming is nil"
          add_code(local + local[0, 1])

          incoming = (local + local[0, 1])
        else
          puts "incoming is not nil"
          add_code(local + incoming[0, 1])
        end

        local_code = incoming_code
        output += incoming
      end

      output
    end

    def encode(stream)
      # This is pretty fucked up right now,
      # the algorithm was adapdet from
      # https://en.wikipedia.org/wiki/GIF

      # Array of {Code padded with 0 to a length of 16, real length
      codes = [] of Tuple(UInt16, UInt8)
      codes << {@clear_code, @current_size}

      local_string = [] of UInt8
      prev_code = 0
      last_found_in_table = false

      # Always output first pixel
      codes << {stream[0].to_u16, @current_size} if stream.size >= 1

      if stream.size >= 2
        last_found_in_table = true
        # Special treatment of the first 2 bytes
        add_code(stream[0, 2])
        local_string = [stream[1]]
        prev_code = stream[1]

        stream[2..-1].each do |byte|
          prev_string = local_string.clone
          local_string << byte
          current_code = @table.index(local_string)

          if current_code.nil?
            last_found_in_table = false

            codes << {prev_code.to_u16, @current_size}
            add_code(local_string)

            local_string = local_string[-1, 1]
          else
            last_found_in_table = true
            prev_code = current_code
          end
        end
      end

      codes << {prev_code.to_u16, @current_size} if last_found_in_table
      codes << {@eoi_code, @current_size}

      codes
    end
  end
end
