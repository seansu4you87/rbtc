# NOTE(yu): This is the heart of the full node
#
# It's the engine that takes in messages from peers, processes them, and reacts
# accordingly.
#
# This class is the the innermost domain layer.  It should have as little to do with
# the following as possible:
#   - binary
#   - hex
#   - serialization
#   - sockets
#   - persistence
#
# This class should have everything to do with:
#   - business logic
#   - validation rules
#   - communication algorithm
#
# This class should be:
#   - easily testable
#   - stateless
#   - unnecessary to mock (inject stateful dependencies and assert on those)
class RBTC::Engine
  def handle(messages, peer)
    messages.each do |m|
      puts "handling <- message: (#{m.type}, #{m.value})"
      send(:"handle_#{m.type}", m.value, peer)
    end
  end

  def handshake(peer)
    puts "extending hands..."
    version = Bitcoin::Protocol::Version.new(
        last_block: 127_953,
        from: "127.0.0.1:8333",
        to: "#{peer.ip}:#{peer.port}",
        user_agent: "/rbtc:0.0.1/",
        relay: true
    )
    puts_delv(:version, version.to_pkt, peer)
    peer.delv(version.to_pkt)
  end

  private

  def handle_version(version, peer)
    puts_recv(:version, version, peer)
  end

  def handle_verack(_, peer)
    puts "handling <- verack"
    puts_recv(:verack, nil, peer)

    # start = ("\x00" * 32)
    # stop  = ("\x00" * 32)
    # pkt = Bitcoin::Protocol.pkt("getblocks", "\x00" + start + stop )
    # puts "-> getblocks (#{start}, #{stop})"
    # peer.delv pkt
  end

  def handle_ping(nonce, peer)
    puts_recv(:ping, nonce, peer)

    pong = Bitcoin::Protocol.pong_pkt(nonce)
    puts "-> pong: #{pong}"
    peer.delv pong
  end

  def handle_alert(_, peer)
    puts_recv(:alert, nil, peer)
  end

  def handle_addr(address, peer)
    puts_recv(:addr, address, peer)
  end

  def handle_getheaders(headers, peer)
    puts_recv(:getheaders, headers, peer)
  end

  def handle_inv(inv, peer)
    puts_recv(:inv, inv, peer)
  end

  # def method_missing(m, *args, &blk)
  #   if m.to_s.start_with?("handle")
  #     puts "No handler defined: #{m}"
  #   else
  #     raise "BOOM: (#{m}, #{args}, #{blk}"
  #   end
  #
  #   super
  # end

  def puts(str)
    RBTC::Logger.info("Engine") { str }
  end

  def puts_recv(type, value, peer)
    puts "<- #{type}: #{peer} #{value}"
  end

  def puts_delv(type, value, peer)
    puts "-> #{type}: #{peer} #{value}"
  end
end