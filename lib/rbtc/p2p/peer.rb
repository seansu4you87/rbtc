require "bitcoin"

class RBTC::P2P::Peer
  include RBTC::Logger

  attr_reader :ip, :port, :thread

  def initialize(ip, engine)
    @socket = connect(ip)
    @stream_parser = RBTC::P2P::StreamParser.new
    @engine = engine
  end

  def run_loop!
    @thread ||= Thread.new do
      engine.handshake(self)
      loop do
        recv
      end
    end
  end

  def to_s
    "(Peer@#{ip})"
  end

  # NOTE(yu): `send` is a Ruby object variable we don't want to override
  def delv(message)
    data = message
    data = data.payload unless data.is_a? String
    data = data.to_pkt unless data.is_a? String

    puts "-> data: #{data.unpack("b*").first}"
    socket.puts data
  end

  private

  attr_reader :socket, :stream_parser, :engine

  def recv(_type = nil)
    socket.gets.tap do |data|
      if data.nil?
        # puts "<- nil"
      else
        puts "<- data: #{data.unpack("b*").first}"

        messages = stream_parser.parse(data)
        engine.handle(messages, self) unless messages.empty?
      end
    end
  end

  def connect(ip)
    port = Bitcoin.network[:default_port]
    puts "Connecting to peer @ #{ip}:#{port}"

    TCPSocket.open(ip, port).tap do
      @ip = ip
      @port = port
      puts "Connected!"
    end
  end
end
