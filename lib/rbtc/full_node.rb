class RBTC::FullNode
  include RBTC::Logger

  attr_reader :peers, :bootnodes

  def initialize(*bootnodes)
    @engine = RBTC::Engine.new
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
        .map { |ip| RBTC::P2P::Peer.new(ip, engine) }.tap { |peers| @peers = peers }
        .map { |peer| peer.run_loop! }
  end

  def start_engine
  end

  def start_monitor
  end
end
