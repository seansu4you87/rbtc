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
      puts "<- #{m.type}: #{peer} #{m.payload}"
      send(:"handle_#{m.type}", m.payload, peer)
    end
  end

  def handshake(peer)
    # NOTE(yu): This initiates the peer connection
    #
    # A VERSION is sent to the new peer.  If it is accepted, then we will receive VERSION back,
    # followed by a VERACK.
    puts "extending hands..."
    version = Bitcoin::Protocol::Version.new(
        last_block: 127_953,
        from: "127.0.0.1:8333",
        to: "#{peer.ip}:#{peer.port}",
        user_agent: "/rbtc:0.0.1/",
        relay: true
    )
    message = Message.build(version, :version)
    respond(message, peer)
  end

  private

  def respond(message, peer)
    puts "-> #{message.type}: #{peer} #{message.payload}"
    peer.delv(message)
  end

  def handle_version(version, peer)
    # NOTE(yu): Nothing to do here, for client connections
    #
    # TODO(yu): for server connections, we need to send our own VERSION, along with a VERACK
  end

  def handle_verack(_, peer)
    # NOTE(yu): At this point, the connection is fully established
    #
    # We can start sending other messages.  Not sure what so far?

    # start = ("\x00" * 32)
    # stop  = ("\x00" * 32)
    # pkt = Bitcoin::Protocol.pkt("getblocks", "\x00" + start + stop )
    # puts "-> getblocks (#{start}, #{stop})"
    # peer.delv pkt
  end

  def handle_ping(ping, peer)
    # NOTE(yu): This is a health check, sent by our peer.
    #
    # Respond with PONG
    # TODO(yu): Switch this to use `Message` once there is a `Pong` object
    pong = Bitcoin::Protocol.pong_pkt(ping.nonce)
    puts "-> pong: #{pong}"
    peer.delv pong
  end

  def handle_alert(_, peer)
    # NOTE(yu): Deprecated in March 2016
  end

  def handle_addr(addr, peer)
    # NOTE(yu): Store and persist these addresses in our potential peers list?
  end

  def handle_getheaders(headers, peer)
    # NOTE(yu): Send HEADERS message back with appropriate headers
  end

  def handle_inv(inv, peer)
    # NOTE(yu): Save information if relevant
    #
    # Can be of type:
    # - ERROR -> ignore
    # - MSG_TX -> TX
    # - MSG_BLOCK -> BLOCK
    # - MSG_FILTERED_BLOCK -> MERKLEBLOCK
    # - MSG_CMPCT_BLOCK -> CMPCTBLOCK
    #
    # Reply with the GETDATA message
  end
end

require_relative "./engine/message"
