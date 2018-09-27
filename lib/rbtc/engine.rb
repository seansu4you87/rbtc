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
#   - single input, single output, i.e. event based
class RBTC::Engine
  include RBTC::Logger

  def handle(messages, peer)
    messages.each do |m|
      puts_recv(m.type, m.value, peer)
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
    message = Message.new(version, :version)
    respond(message, peer)
  end

  private

  def respond(message, peer)
    puts_delv(message.type, message.value, peer)
    peer.delv(message)
  end

  def handle_version(version, peer)
  end

  def handle_verack(_, peer)
    # start = ("\x00" * 32)
    # stop  = ("\x00" * 32)
    # pkt = Bitcoin::Protocol.pkt("getblocks", "\x00" + start + stop )
    # puts "-> getblocks (#{start}, #{stop})"
    # peer.delv pkt
  end

  def handle_ping(nonce, peer)
    # TODO(yu): Switch this to use `Message` once there is a `Pong` object
    pong = Bitcoin::Protocol.pong_pkt(nonce)
    puts "-> pong: #{pong}"
    peer.delv pong
  end

  def handle_alert(_, peer)
  end

  def handle_addr(address, peer)
  end

  def handle_getheaders(headers, peer)
  end

  def handle_inv(inv, peer)
  end

  def puts_recv(type, value, peer)
    puts "<- #{type}: #{peer} #{value}"
  end

  def puts_delv(type, value, peer)
    puts "-> #{type}: #{peer} #{value}"
  end
end

require_relative "./engine/message"
