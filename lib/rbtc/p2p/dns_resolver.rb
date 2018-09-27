class RBTC::P2P::DNSResolver
  attr_reader :seeds

  def initialize(seeds)
    raise "BOOM" if seeds.empty?
    @seeds = seeds
    @ips = []
  end

  def next_ip
    while ips.empty?
      raise "BOOM! out of seeds" if seeds.empty?

      seed = seeds.shift.tap { |s| puts "Out of IPs, fetching next seed: #{s}" }
      new_ips = Resolv::DNS.new.getaddresses(seed).compact.map(&:to_s).tap { |new| puts "Fetched #{new.count} ips" }
      ips.concat(new_ips)
    end

    ips.shift
  end

  private

  attr_reader :ips
end

# seeds = Bitcoin.network[:dns_seeds]
# resolver = DNSResolver.new(seeds)
# ip = resolver.next_ip

