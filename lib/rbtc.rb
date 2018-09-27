require "logger"
require "resolv"

module RBTC
  module Logger
    FILE = File.new("../rbtc.log", "w")
    INSTANCE = ::Logger.new(FILE)

    def info(progname, &blk)
      INSTANCE.info(progname, &blk)
    end

    def puts(str)
      info(self.class) { str }
    end
  end
end

require_relative './rbtc/engine'
require_relative './rbtc/full_node'
require_relative './rbtc/p2p'

node = RBTC::FullNode.new
# node.configure do
#   peer 10
#   bootnodes [ "178.33.136.164" ] # Fast guy
# end
node.boot
