class Arel::Nodes::Inequality
  attr_accessor :left, :right, :operand

  def initialize attribute, value, op
    @left = attribute
    @right = value
    @operand = op
  end
end
