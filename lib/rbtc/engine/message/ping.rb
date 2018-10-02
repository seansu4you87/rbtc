class RBTC::Engine::Message::Ping
  attr_reader :nonce

  def initialize(nonce)
    @nonce = nonce
  end
end