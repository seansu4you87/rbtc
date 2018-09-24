# frozen_string_literal: true

class StreamParser
  class Message
    attr_reader :value, :type

    def initialize(value, type)
      @value = value
      @type = type.to_sym
    end
  end

  attr_reader :stats

  def initialize
    @buffer = ''
    @stats = { total_packets: 0, total_bytes: 0, total_errors: 0 }
  end

  # def parse(buf)
  #   @buffer += buf
  #   while parse_buffer
  #   end
  #   @buffer
  # end

  def parse(data)
    @buffer += data
    messages = []

    more = true
    while more do
      message, more = parse_buffer
      messages << message if message
    end
    messages
  end

  private

  def parse_buffer
    message = nil
    head_magic = Bitcoin.network[:magic_head]
    head_size = 24
    return [message, false] if @buffer.size < head_size

    magic, cmd, length, checksum = @buffer.unpack('a4A12Va4')
    payload = @buffer[head_size...head_size + length]

    if magic != head_magic
      handle_stream_error(:close, 'head_magic not found')
      @buffer = ''
    else
      if Digest::SHA256.digest(Digest::SHA256.digest(payload))[0...4] != checksum
        if (length < 50_000) && (payload.size < length)
          size_info = [payload.size, length].join('/')
          handle_stream_error(:debug, "chunked packet stream (#{size_info})")
        else
          handle_stream_error(:close, 'checksum mismatch')
        end
        return [message, false]
      end
      @buffer = @buffer[head_size + length..-1] || ''

      value = process_pkt(cmd, payload)
      message = Message.new(value, cmd)
    end

    # not empty yet? parse more.
    [message, !@buffer[0].nil?]
  end

  def parse_inv(payload, type = :put)
    count, payload = Bitcoin::Protocol.unpack_var_int(payload)
    payload.each_byte.each_slice(36).with_index do |i, idx|
      hash = i[4..-1].reverse.pack('C32')
      case i[0]
      when 1
        if type == :put
          puts "Parsed inv transaction #{hash}"
        else
          puts "Parsed get transaction #{hash}"
        end
      when 2
        if type == :put
          puts "Parsed inv block #{hash}, #{idx}, #{count}"
        else
          puts "Parsed get block #{hash}"
        end
      else
        parse_error(:parse_inv, i.pack('C*'))
      end
    end
  end

  def parse_addr(payload)
    _count, payload = Bitcoin::Protocol.unpack_var_int(payload)
    payload.each_byte.each_slice(30).inject([]) do |acc, byte_array|
      # begin
      acc << Bitcoin::Protocol::Addr.new(byte_array.pack('C*'))
      acc
      # rescue StandardError
      #   parse_error(:addr, byte_array.pack('C*'))
      #   acc
      # end
    end
  end

  def parse_headers(payload)
    buf = StringIO.new(payload)
    count = Bitcoin::Protocol.unpack_var_int_from_io(buf)
    count.times.map do
      break if buf.eof?
      b = Block.new
      b.parse_data_from_io(buf, true)
      b
    end
  end

  def parse_mrkle_block(payload)
    b = Block.new
    b.parse_data_from_io(payload, :filtered)
  end

  def parse_getblocks(payload)
    version, payload = payload.unpack('Va*')
    count, payload = Bitcoin::Protocol.unpack_var_int(payload)
    buf, payload = payload.unpack("a#{count * 32}a*")
    hashes = buf.each_byte.each_slice(32).map { |i| i.reverse.pack('C32').hth }
    stop_hash = payload[0..32].reverse_hth
    [version, hashes, stop_hash]
  end

  def process_pkt(command, payload)
    @stats[:total_packets] += 1
    @stats[:total_bytes] += payload.bytesize
    @stats[command] ? (@stats[command] += 1) : @stats[command] = 1
    case command
    when 'tx'
      puts "Parsed tx"
      Bitcoin::Protocol::Tx.new(payload)
    when 'block'
      puts "Parsed block"
      Bitcoin::Protocol::Block.new(payload)
    when 'headers'
      puts "Parsed headers"
      parse_headers(payload)
    when 'inv'
      # puts "Parsed inv"
      parse_inv(payload, :put)
      :inv
    when 'getdata'
      puts "Parsed getdata"
      parse_inv(payload, :get)
      :getdata
    when 'addr'
      puts "Parsed addr"
      parse_addr(payload)
    when 'getaddr'
      puts "Parsed getaddr"
      :getaddr
    when 'verack'
      puts "Parsed verack"
      :verack
    when 'version'
      puts "Parsed version"
      parse_version(payload)
    when 'alert'
      # puts "Parsed alert"
      parse_alert(payload)
      :alert
    when 'ping';
      puts "Parsed ping"
      payload.unpack1('Q')
    when 'pong';
      puts "Parsed pong"
      payload.unpack1('Q')
    when 'getblocks';
      puts "Parsed getblocks"
      parse_getblocks(payload)
    when 'getheaders';
      puts "Parsed getheaders"
      parse_getblocks(payload)
    when 'mempool';
      handle_mempool_request(payload)
      :mempool
    when 'notfound';
      handle_notfound_reply(payload)
      :notfound
    when 'merkleblock';
      puts "Parsed merkleblock"
      parse_mrkle_block(payload)
    when 'reject';
      puts "Parsed reject"
      handle_reject(payload)
    else
      puts "Parsed unknown...about to parse errors..."
      parse_error(:unknown_packet, [command, payload.hth])
      :error
    end
  end

  def parse_version(payload)
    @version = Bitcoin::Protocol::Version.parse(payload)
  end

  def parse_alert(payload)
    # NOTE(yu): Alert parsing is broken
    # Bitcoin::Protocol::Alert.parse(payload)

    puts "Parsed alert - except didn't cause it's broken"
  end

  def handle_reject(payload)
    Bitcoin::Protocol::Reject.parse(payload)
  end

  # https://en.bitcoin.it/wiki/BIP_0035
  def handle_mempool_request(_payload)
    return unless @version.fields[:version] >= 60_002 # Protocol version >= 60002
    return unless (@version.fields[:services] & Bitcoin::Protocol::Version::NODE_NETWORK) == 1 # NODE_NETWORK bit set in Services
    puts "Parsed mempool"
  end

  def handle_notfound_reply(payload)
    _count, payload = Bitcoin::Protocol.unpack_var_int(payload)
    payload.each_byte.each_slice(36) do |i|
      hash = i[4..-1].reverse.pack('C32')
      case i[0]
      when 1;
        puts "Parsed tx not found #{hash}"
      when 2;
        puts "Parsed block not found #{hash}"
      else
        parse_error(:notfound, [i.pack('C*'), hash])
      end
    end
  end

  def handle_stream_error(type, msg)
    case type
    when :close
      puts "closing packet stream (#{msg})"
    else
      puts [type, msg]
    end
  end

  def parse_error(*err)
    @stats[:total_errors] += 1
    puts "Parsed errors: #{err}"
  end
end
