require "byebug"
require "colorize"

class Gate
  attr_accessor :adder, :inputs, :gate, :output

  def initialize(adder, line)
    self.adder = adder
    inputs, self.output = line.split(" -> ")
    self.inputs = inputs.split
    self.gate = self.inputs.delete_at(1)
  end

  def ready?
    inputs.all? { wires.key?(_1) }
  end

  def input_values
    inputs.map { wires[_1] }
  end

  def propagate
    return false unless ready?
    return false if wires.key?(output)

    case gate
    when "AND"
      wires[output] = input_values.all?(1) ? 1 : 0
    when "OR"
      wires[output] = input_values.any?(1) ? 1 : 0
    when "XOR"
      wires[output] = input_values.uniq.size == 1 ? 0 : 1
    end
    true
  end

  def shape
    case gate
    when "AND" then "invtrapezium"
    when "OR" then "invhouse"
    when "XOR" then "invtriangle"
    end
  end

private
  def wires
    adder.wires
  end
end

class BrokenAdder
  attr_accessor :gates, :wires, :xsize, :zsize

  def initialize
    _wires, _gates = ARGF.read.split("\n\n")
    self.wires = _wires.split("\n").map { _1.split(":") }.to_h
    wires.transform_values!(&:to_i)
    self.gates = _gates.split("\n").map { Gate.new(self, _1) }
    self.xsize = input_nodes(?x).count
    self.zsize = output_nodes.count
  end

  def swap_outputs(swaps)
    iswaps = swaps.invert
    gates.each do |gate|
      gate.output = swaps[gate.output] || iswaps[gate.output] || gate.output
    end
  end

  def propagate
    loop do
      updates = false
      gates.each do |gate|
        updates = true if gate.propagate
      end
      break unless updates
    end
    z
  end

  def val_bit(var, bit)
    "#{var}%02d" % bit
  end

  def get_val(var)
    bit = 0
    val = 0
    while wires.key?(val_bit(var, bit))
      val |= (wires[val_bit(var, bit)] << bit)
      bit += 1
    end
    val
  end

  def set_val(var, val)
    (0...xsize).each do |bit|
      wires[val_bit(var, bit)] = val[bit]
    end
    val
  end

  def clear
    wires.clear
  end

  def detect_changes
    before = wires.to_a
    yield self
    (wires.to_a - before).to_h
  end

  def add(x, y)
    clear
    set_val(?x, x)
    set_val(?y, y)
    propagate
  end

  def each_bit
    return to_enum(:each_bit) unless block_given?

    bit = 1
    xsize.times do
      yield bit
      bit <<= 1
    end
  end

  def bad_bits(expected, test)
    bits = []
    zsize.times do |bit|
      bits << bit if expected[bit] != test[bit]
    end
    "#{bits.min}-#{bits.max}"
  end

  def test_add(x, y, tag)
    expected = x + y
    test = add(x, y)
    return 0 if test == expected

    puts "#{tag} test failure on bits #{bad_bits(expected, test)}"
    puts "  %0*b" % [xsize, x]
    puts "+ %0*b" % [xsize, y]
    puts "-" * (zsize + 1)
    puts (" %0*b" % [zsize, test]).colorize(:red)
    puts (" %0*b" % [zsize, expected]).colorize(:green)
    puts
    1
  end

  def test_x
    each_bit.sum do |bit|
      test_add bit, 0, :x_plus_zero
    end
  end

  def test_y
    each_bit.sum do |bit|
      test_add 0, bit, :zero_plus_y
    end
  end

  def test_co
    each_bit.sum do |bit|
      test_add bit, bit, :carry_out
    end
  end

  def test_ripple
    test_add (1 << xsize) - 1, 1, :ripple
  end

  def test_suite
    failures = test_x + test_y + test_co + test_ripple
    puts "#{failures} failures"
    failures
  end

  def find_output_gate(net)
    return net if net =~ /^[xy]\d+$/

    i = gates.find_index { |gate| gate.output == net }
    "g#{i}"
  end

  def find_input_gate(net)
    return net if net =~ /^z\d+$/

    i = gates.find_index { |gate| gate.inputs.include?(net) }
    "g#{i}"
  end

  def input_nodes(v)
    gates.map(&:inputs).flatten.grep(/^#{Regexp.quote(v)}\d+$/).uniq
  end

  def output_nodes
    gates.map(&:output).grep(/^z\d+$/)
  end

  def visualize
    dot = File.open("24.dot", "w")

    dot.puts "digraph {"
    input_nodes("x").sort.each { dot.puts "#{_1} [shape=circle color=blue];" }
    input_nodes("y").sort.each { dot.puts "#{_1} [shape=circle color=green];" }
    output_nodes.sort.each { dot.puts "#{_1} [shape=circle color=red];" }

    gates.each_with_index do |gate, i|
      dot.puts "g#{i} [label=\"#{gate.gate}\" shape=#{gate.shape}];"
    end

    edges = []
    gates.each_with_index do |gate, i|
      edges << "#{find_output_gate(gate.inputs.first)} -> g#{i} [label=\"#{gate.inputs.first}\"];"
      edges << "#{find_output_gate(gate.inputs.last)} -> g#{i} [label=\"#{gate.inputs.last}\"];"
      edges << "g#{i} -> #{find_input_gate(gate.output)} [label=\"#{gate.output}\"];"
    end
    edges.uniq.each { dot.puts _1 }

    dot.puts "}"
    dot.close
    `dot -Tpng -o 24.png 24.dot`
  end

  def x; get_val(?x); end
  def x=(val); set_val(?x, val); end
  def y; get_val(?y); end
  def y=(val); set_val(?y, val); end
  def z; get_val(?z); end
end

adder = BrokenAdder.new
adder.visualize
adder.propagate
puts adder.get_val("z")
exit if adder.wires["z45"].nil?

# determined visually from 24.png, assisted by test failures
adder.swap_outputs("dhg" => "z06", "dpd" => "brk", "bhd" => "z23", "z38" => "nbf")

puts $swaps.to_a.flatten.sort.join(?,) if adder.test_suite == 0
