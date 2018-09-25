# frozen_string_literal: true

require 'eventmachine'
require 'bitcoin/connection'

Bitcoin.network = ARGV[0] || :bitcoin
# Bitcoin.network = :testnet

class SimpleConnection < Bitcoin::Connection
  def on_handshake_begin
    puts "handshake begin"
    version = Bitcoin::Protocol::Version.new(
      last_block: 127_953,
      from: "127.0.0.1:8333",
      to: @sockaddr.reverse.join(":"),
      user_agent: "/rbtc:0.0.1/",
      relay: true
    )
    puts "-> version: #{version.fields}"
    send_data(version.to_pkt)
  end

  def on_version(version)
    puts "<- version: #{version.fields}"
  end

  def on_verack
    puts "<- verack"
    on_handshake_complete
  end

  def on_handshake_complete
    puts "handshake complete with #{@sockaddr}"
    @connected = true

    query_blocks
  end

  def send_data(data)
    puts "-> data: #{data}"
    super(data)
  end

  def receive_data(data)
    puts "<- data: #{data}"
    super(data)
  end

  def on_ping(nonce)
    puts "<- ping: #{nonce}"
    return unless nonce

    pong = Bitcoin::Protocol.pong_pkt(nonce)
    puts "-> pong: #{pong}"
    send_data(pong)
  end

  def on_addr(addr); end

  def on_inv_block(hash); end

  def on_inv_transaction(hash); end

  def on_block(block)
    puts "block <- peer: #{block.hash}"
  end

  def on_tx(tx)
    puts "tx <- peer: #{tx.hash}"
  end

  def on_get_block(hash); end

  def on_get_transaction(hash); end
end

EM.run do
  connections = []
  # host = '127.0.0.1'
  # host = '217.157.1.202'
  host = "1.36.96.26"

  SimpleConnection.connect(host, 8333, connections)
  # SimpleConnection.connect_random_from_dns(connections)
end
