require "logger"
require "resolv"

module RBTC
end

require_relative './rbtc/engine'
require_relative './rbtc/peer'
require_relative './rbtc/stream_parser'

module RBTC
  attr_reader :peers, :bootnodes

  class FullNode
    def initialize(*bootnodes)
      @engine = Engine.new
      @bootnodes = bootnodes.freeze
    end

    def boot
      connect_peers
      start_engine
      start_monitor

      loop do
        puts "sleeping..."
        sleep(5)
      end
    end

    private

    attr_reader :engine

    def connect_peers
      # bootnodes = ["1.36.96.26"]
      bootnodes = ["178.33.136.164"]
      bootnodes
          .map { |ip| Peer.new(ip, engine) }.tap { |peers| @peers = peers }
          .map { |peer| peer.run_loop! }
    end

    def start_engine
    end

    def start_monitor
    end

    def puts(str)
      RBTC::Logger.info("FullNode") { str }
    end
  end

  class Logger
    FILE = File.new("../rbtc.log", "w")
    INSTANCE = ::Logger.new(FILE)

    class << self
      def info(progname, &blk)
        INSTANCE.info(progname, &blk)
      end
    end

    def puts(str)
      info(self.class) { str }
    end
  end
end

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

# seeds = Bitcoin.network[:dns_seeds]
# resolver = DNSResolver.new(seeds)
# ip = resolver.next_ip

node = RBTC::FullNode.new
# node.configure do
#   peer 10
#   bootnodes [ "178.33.136.164" ] # Fast guy
# end
node.boot
