class RBTC::P2P::MessageParser
  def initialize

  end

  def parse_header(bytes)
    magic, command, length, checksum = bytes.unpack("a4A12Va4")
    RBTC::Engine::Message::Header.new(magic, command, length, checksum)
  end

  def parse(header, bytes)
    payload = send(:"parse_#{header.command}", bytes)
    RBTC::Engine::Message.new(header, payload)
  end

  private

  def parse_tx(bytes)
    raise "BOOM"
  end

  def parse_block(bytes)
    raise "BOOM"
  end

  def parse_headers(bytes)
    raise "BOOM"
  end

  def parse_inv(bytes)
    raise "BOOM"
  end

  def parse_getdata(bytes)
    raise "BOOM"
  end

  def parse_addr(bytes)
    raise "BOOM"
  end

  def parse_getaddr(bytes)
    raise "BOOM"
  end

  def parse_verack(bytes)
    raise "BOOM"
  end

  def parse_version(bytes)
    version, services, timestamp, addr_recv, addr_from, nonce, bytes = bytes.unpack("VQQa26a26Qa*")
    addr_recv, addr_from = [addr_recv, addr_from].map do |addr|
      ip, port = addr.unpack("x8x12a4n")
      ip = ip.unpack("C*").join(".")
      "#{ip}:#{port}"
    end
    user_agent, bytes = Bitcoin::Protocol.unpack_var_string(bytes)
    last_block, bytes = bytes.unpack("Va*")
    relay, _ = (version >= 70_001 && bytes) ? Bitcoin::Protocol.unpack_boolean(bytes) : [true, nil]

    RBTC::Engine::Message::Version.new(
        version: version,
        services: services,
        timestamp: timestamp,
        addr_recv: addr_recv,
        addr_from: addr_from,
        nonce: nonce,
        user_agent: user_agent.to_s,
        last_block: last_block,
        relay: relay,
    )
  end

  def parse_alert(bytes)
    raise "BOOM"
  end

  def parse_ping(bytes)
    raise "BOOM"
  end

  def parse_pong(bytes)
    raise "BOOM"
  end

  def parse_getblocks(bytes)
    raise "BOOM"
  end

  def parse_getheaders(bytes)
    raise "BOOM"
  end

  def parse_mempool(bytes)
    raise "BOOM"
  end

  def parse_notfound(bytes)
    raise "BOOM"
  end

  def parse_merkleblock(bytes)
    raise "BOOM"
  end

  def parse_reject(bytes)
    raise "BOOM"
  end
end