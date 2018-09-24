# frozen_string_literal: true

require 'socket'

class Server
  def initialize(ip, port)
    puts "Initializing server"

    @socket = listen(ip, port)
    @users = {}

    run
  end

  private

  attr_reader :socket, :users

  def listen(ip, port)
    TCPServer.open(ip, port)
  end

  def run
    loop do
      spawn_worker
    end
  end

  def spawn_worker
    conn = socket.accept
    puts "Got a customer! #{conn}"

    Thread.start(Server::Worker.new(conn)) do |worker|
      worker.setup { |w, name| add_user(name, w) }
      worker.recv_loop { |w, msg| broadcast(w, msg) }
    end
  end

  def add_user(name, worker)
    worker.die! if users[name]

    puts "Connecting #{worker} as #{name}"
    users[name] = worker
  end

  def broadcast(worker, msg)
    puts "All users: #{users}"
    users.values.each do |other_worker|
      next if worker.name == other_worker.name
      other_worker.send_message!(worker.name, msg)
    end
  end

  class Worker
    attr_reader :name

    def initialize(conn)
      @conn = conn
    end

    def setup(&blk)
      recv_name!
      blk.call(self, @name)
      send_connected!
    end

    def recv_loop(&blk)
      loop do
        msg = recv_message!
        blk.call(self, msg)
      end
    end

    def send_message!(from, msg)
      conn.puts "#{from}: #{msg}"
    end

    def die!
      conn.puts "This username already exists!"
      Thread.kill self
    end

    private

    def recv_name!
      send_instructions!
      @name = recv_message!
    end

    def send_instructions!
      conn.puts "Welcome to ChatLand, please enter your name..."
    end

    def send_connected!
      conn.puts "Connection established, Thank you for joining!"
    end

    def recv_message!
      conn.gets.chomp
    end

    attr_reader :conn
  end
end

Server.new("localhost", 4000)
