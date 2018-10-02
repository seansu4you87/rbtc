class RBTC::Engine::Message::Version
  def initialize(version:,
                 services:,
                 timestamp:,
                 addr_recv:,
                 addr_from:,
                 nonce:,
                 user_agent:,
                 last_block:,
                 relay:)
    @version = version
    @services = services
    @timestamp = timestamp
    @addr_recv = addr_recv
    @addr_from = addr_from
    @nonce = nonce
    @user_agent = user_agent
    @last_block = last_block
    @relay = relay
  end
end