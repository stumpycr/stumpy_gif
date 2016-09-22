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
      @current_size = @min_code_size + 1
      @clear_code = (1 << @min_code_size).to_u16
      @eoi_code = @clear_code + 1 # End of Information code

      clear

      @local_string = [] of UInt8
    end

    def clear
      @table = [] of Array(UInt8)
      @current_size = @min_code_size + 1

      256.times do |i|
        @table << [i.to_u8]
      end

      # @table << [@clear_code]
      # @table << [@eoi_code]
      # Use placeholders instead
      @table << [0_u8]
      @table << [0_u8]
    end

    def add_code(code)
      @table << code
      # if @table.size == (1 << @current_size) && @current_size < 12
        # @current_size += 1
        # puts "#{(@table.size - 1).to_s(16)}: #{code}"
        # puts "Increasing size to #{@current_size}"
      # end
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

      last = 0
      code = 0

      loop do
        last = code
        code = wrapper.read_bits(@current_size)

        if code == @clear_code
          clear
          next
        end

        if code == @eoi_code
          break
        end

        if code < @table.size
          if last != @clear_code
            add_code(@table[last] + @table[code][0, 1])
          end
        else
          raise "Invalid LZW code #{code}" if code != @table.size
          add_code(@table[last] + @table[last][0, 1])
        end

        output += @table[code]

        if @table.size == (1 << @current_size) && @current_size < 12
          @current_size += 1
        end
      end

      output
    end

    def encode(stream)
      # This is pretty fucked up right now,
      # the algorithm was adapdet from
      # https://en.wikipedia.org/wiki/GIF

      # Array of {Code padded with 0 to a length of 16, real length
      code_stream = [] of Tuple(UInt16, UInt8)
      code_stream << {@clear_code, @current_size}

      index_buffer = [] of UInt8

      # TODO: handle stream.size = 0 and size = 1
      index_buffer << stream.shift

      loop do
        next_index = stream.shift

        unless @table.index(index_buffer + [next_index]).nil?
          index_buffer << next_index
          break if stream.size == 0
        else
          add_code(index_buffer + [next_index])
          code_stream << {(@table.index(index_buffer) || 0).to_u16, @current_size}
          index_buffer = [next_index]
          break if stream.size == 0
        end

        if @table.size > (1 << @current_size) && @current_size < 12
          @current_size += 1
        end
      end

      code_stream << {(@table.index(index_buffer) || 0).to_u16, @current_size}
      code_stream << {@eoi_code, @current_size}

      code_stream
    end
  end
end
