class RBTC::Engine::Message::Addr
  def initialize(time:,
                 services:,
                 ip:,
                 port:)
    @time = time
    @services = services
    @ip = ip
    @port = port
  end
end
