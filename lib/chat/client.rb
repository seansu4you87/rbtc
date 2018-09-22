require 'socket'

class Client
  def initialize(ip, port)
    puts "Initializing client"

    @socket = connect(ip, port)
    @send_thread = Thread.new { send_loop }
    @recv_thread = Thread.new { recv_loop }

    [@send_thread, @recv_thread].map(&:join)
  end

  private

  attr_reader :socket

  def connect(ip, port)
    TCPSocket.open(ip, port)
  end

  def send_loop
    loop do
      msg = $stdin.gets.chomp
      @socket.puts msg
    end
  end

  def recv_loop
    loop do
      msg = socket.gets.chomp
      puts msg
    end
  end
end

Client.new("localhost", 4000)
