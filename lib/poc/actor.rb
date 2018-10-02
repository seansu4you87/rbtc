# frozen_string_literal: true

require 'bitcoin'
require 'celluloid/current'

require_relative './/stream_parser'

# NOTE(yu): Celluloid is unmaintained
#
# While really simple to use (literally just include the module, and add a single `async` call),
# the library quickly crashed with
#
# `E, [2018-09-24T00:35:59.347720 #83602] ERROR -- : Couldn't cleanly terminate all actors in 10 seconds!`
#
# I checked and it looked like the library is unmaintained.  What a shame, seems a lot better than
# EventMachine.
#
# The `Engine` and `Peer` class are copy/pasta'd from `tcp.rb`

def log(str, tags = [])
  out = str
  if tags.count > 0
    tag_str = tags.map { |t| "[#{t}]" }.join(" ")
    out = "#{tag_str} #{out}"
  end
  puts "#{Time.now} #{out}"
end

class Engine_
  attr_accessor :channel

  def handle(messages)
    messages.each do |m|
      log "handling <- message: (#{m.type}, #{m.payload})"
      send(:"handle_#{m.type}", m.payload)
    end
  end

  def handle_version(version)
    log "handling <- version: #{version.fields}"
  end

  def handle_verack(_)
    log "handling <- verack"

    # start = ("\x00" * 32)
    # stop  = ("\x00" * 32)
    # pkt = Bitcoin::Protocol.pkt("getblocks", "\x00" + start + stop )
    # log "-> getblocks (#{start}, #{stop})"
    # channel.puts pkt
  end

  def handle_ping(nonce)
    log "handling <- ping with nonce: #{nonce}"

    pong = Bitcoin::Protocol.pong_pkt(nonce)
    log "-> pong: #{pong}"
    channel.puts pong
  end

  def handle_alert(_)
    log "handling <- alert"
  end

  def handle_addr(address)
    log "handling <- addr: #{address}"
  end

  def handle_getheaders(headers)
    log "handling <- getheaders: #{headers}"
  end

  def handle_inv(inv)
    log "handling <- inv: #{inv}"
  end

  def send_version(ip, port)
    log "shaking hands..."
    version = Bitcoin::Protocol::Version.new(
        last_block: 127_953,
        from: "127.0.0.1:8333",
        to: "#{ip}:#{port}",
        user_agent: "/rbtc:0.0.1/",
        relay: true
      )
    log "-> version: #{version.fields}"
    channel.puts version.to_pkt
  end

  # def method_missing(m, *args, &blk)
  #   if m.to_s.start_with?("handle")
  #     log "No handler defined: #{m}"
  #   else
  #     raise "BOOM: (#{m}, #{args}, #{blk}"
  #   end
  #
  #   super
  # end
end

class Peer_
  include Celluloid

  attr_reader :ip, :port

  def initialize(ip, engine)
    @socket = connect(ip)
    @stream_parser = StreamParser.new
    @engine = engine.tap { |e| e.channel = @socket }
  end

  def run_loop
    engine.send_version(ip, port)
    loop do
      recv
    end
  end

  private

  attr_reader :socket, :stream_parser, :engine

  def recv(_type = nil)
    socket.gets.tap do |data|
      if data.nil?
        # log "<- nil"
      else
        log "<- data: #{data}"

        messages = stream_parser.parse(data)
        engine.handle(messages) unless messages.empty?
      end
    end
  end

  def connect(ip)
    port = Bitcoin.network[:default_port]
    log "Connecting to peer @ #{ip}:#{port}"

    TCPSocket.open(ip, port).tap do
      @ip = ip
      @port = port
      log "Connected!"
    end
  end
end

ip = "178.33.136.164" # Fast guy
engine = Engine_.new
peer = Peer_.new(ip, engine)
peer.async.run_loop

puts "DONE"
