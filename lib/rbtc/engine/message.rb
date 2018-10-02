class RBTC::Engine::Message
  attr_reader :payload

  class << self
    def build(payload, command)
      header = Header.new(nil, command, nil, nil)
      new(header, payload)
    end
  end

  def initialize(header, payload)
    @header = header
    @payload = payload
  end

  def magic
    header.magic
  end

  def type
    header.command
  end

  def command
    header.command
  end

  def length
    header.length
  end

  def checksum
    header.checksum
  end

  private

  attr_reader :header

  class Header
    attr_reader :magic, :command, :length, :checksum

    def initialize(magic, command, length, checksum)
      @magic = magic
      @command = command.to_sym
      @length = length
      @checksum = checksum
    end
  end
end

require_relative "./message/addr"
require_relative "./message/ping"
require_relative "./message/verack"
require_relative "./message/version"
