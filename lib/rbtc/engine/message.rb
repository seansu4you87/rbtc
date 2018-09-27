class RBTC::Engine::Message
  attr_reader :value, :type

  def initialize(value, type)
    @value = value
    @type = type.to_sym
  end
end