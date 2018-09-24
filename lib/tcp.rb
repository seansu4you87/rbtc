# frozen_string_literal: true
# ruby
require 'resolv'
require 'socket'

# gem
require 'bitcoin'

# lib
require_relative './stream_parser'

class DNSResolver
  attr_reader :seeds

  def initialize(seeds)
    raise "BOOM" if seeds.empty?
    @seeds = seeds
    @ips = []
  end

  def next_ip
    while ips.empty?
      raise "BOOM! out of seeds" if seeds.empty?

      seed = seeds.shift.tap { |s| puts "Out of IPs, fetching next seed: #{s}" }
      new_ips = Resolv::DNS.new.getaddresses(seed).compact.map(&:to_s).tap { |new| puts "Fetched #{new.count} ips" }
      ips.concat(new_ips)
    end

    ips.shift
  end

  private

  attr_reader :ips
end

class Peer
  attr_reader :ip, :port

  def initialize(ip, engine)
    @socket = connect(ip)
    @stream_parser = StreamParser.new
    @engine = engine.tap { |e| e.channel = @socket }

  end

  def run_loop
    engine.send_version(ip, port)
    count = 0
    loop do
      recv

      puts "listening...#{count} loops" if count % 1_000_000 == 0
      count += 1
    end
  end

  private

  attr_reader :socket, :stream_parser, :engine

  def recv(_type = nil)
    socket.gets.tap do |data|
      if data.nil?
        # puts "<- nil"
      else
        puts "<- data: #{data}"

        messages = stream_parser.parse(data)
        engine.handle(messages) unless messages.empty?
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

class Engine
  attr_accessor :channel

  def handle(messages)
    messages.each do |m|
      puts "handling <- message: (#{m.type}, #{m.value})"
      send(:"handle_#{m.type}", m.value)
    end
  end

  def handle_version(version)
    puts "handling <- version: #{version.fields}"
  end

  def handle_verack(_)
    puts "handling <- verack"

    start = ("\x00"*32)
    stop  = ("\x00"*32)
    pkt = Bitcoin::Protocol.pkt("getblocks", "\x00" + start + stop )
    # puts "-> getblocks (#{start}, #{stop})"
    # channel.puts pkt
  end

  def handle_ping(nonce)
    puts "handling <- ping with nonce: #{nonce}"

    pong = Bitcoin::Protocol.pong_pkt(nonce)
    puts "-> pong: #{pong}"
    channel.puts pong
  end

  def handle_alert(_)
    puts "handling <- alert"
  end

  def handle_addr(address)
    puts "handling <- addr: #{address}"
  end

  def handle_getheaders(headers)
    puts "handling <- getheaders: #{headers}"
  end

  def handle_inv(inv)
    puts "handling <- inv: #{inv}"
  end

  def send_version(ip, port)
    puts "shaking hands..."
    version = Bitcoin::Protocol::Version.new(
        last_block: 127_953,
        from: "127.0.0.1:8333",
        to: "#{ip}:#{port}",
        user_agent: "/rbtc:0.0.1/",
        relay: true
    )
    puts "-> version: #{version.fields}"
    channel.puts version.to_pkt
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
end

# NOTE(yu): Network Protocol Flow
#
# -> version
# <- version
# <- verack

puts "NEW RUN: #{Time.now}"

# seeds = Bitcoin.network[:dns_seeds]
# resolver = DNSResolver.new(seeds)
# ip = resolver.next_ip
# ip = "1.36.96.26"
ip = "178.33.136.164" # Fast guy

engine = Engine.new
peer = Peer.new(ip, engine)
peer.run_loop

puts "DONE"
