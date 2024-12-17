require_relative "skim"

class Computer
  attr_accessor :a, :b, :c, :program, :ip, :trace, :output

  def initialize(program, a: 0, b: 0, c: 0, trace: false)
    self.ip = 0
    self.program = program
    self.a = a
    self.b = b
    self.c = c
    self.output = []
    @trace = trace
  end

  def combo_rval(operand)
    case operand
    when 0..3
      operand
    when 4
      a
    when 5
      b
    when 6
      c
    when 7
      raise "invalid combo operand"
    end
  end

  def combo_trace(operand)
    case operand
    when 0..3
      operand.to_s
    when 4
      "a (#{a})"
    when 5
      "b (#{b})"
    when 6
      "c (#{c})"
    when 7
      raise "invalid combo operand"
    end
  end

  def trace(description)
    puts "#{ip}. #{description} ==> {a: #{a}, b: #{b}, c: #{c}}" if @trace
  end

  def exec(opcode, operand)
    case opcode
    when 0 # adv
      self.a /= (1 << combo_rval(operand))
      trace("a /= 1 << #{combo_trace(operand)}")
    when 1 # bxl
      self.b ^= operand
      trace("b ^= #{operand}")
    when 2 # bst
      self.b = combo_rval(operand) & 7
      trace("b = #{combo_trace(operand)} & 7")
    when 3 # jnz
      trace("jnz #{operand}")
      self.ip = operand if (a != 0)
    when 4 # bxc
      self.b ^= c
      trace("b ^= c")
    when 5 # out
      out(combo_rval(operand) & 7)
      trace("out #{combo_trace(operand)}")
    when 6 # bdv
      self.b = a / (1 << combo_rval(operand))
      trace("b = a / (1 << #{combo_trace(operand)})")
    when 7 # cdv
      self.c = a / (1 << combo_rval(operand))
      trace("c = a / (1 << #{combo_trace(operand)})")
    end
    self.ip += 2 unless opcode == 3 && a != 0
  end

  def out(val)
    output << val
  end

  def run
    while ip < program.size
      opcode = program[ip]
      operand = program[ip + 1]
      exec(opcode, operand)
    end
    output
  end
end

puts Computer.new([0,1,5,4,3,0], a: 729).run.join(?,)
puts Computer.new([2,4,1,1,7,5,4,6,0,3,1,4,5,5,3,0], a: 28066687).run.join(?,)
puts Computer.new([0,3,5,4,3,0], a: 117440).run.join(?,)

#  0. 2,4  b = a & 7
#  2. 1,1  b ^= 1
#  4. 7,5  c = a / (1 << b)
#  6. 4,6  b ^= c
#  8. 0,3  a >>= 3
# 10. 1,4  b ^= 4
# 12. 5,5  out b
# 14. 3,0  jnz 0

quine = [2,4,1,1,7,5,4,6,0,3,1,4,5,5,3,0]


ub = 1 << (quine.size * 3)
step = ub / 100
a = 0
a += step until Computer.new(quine, a:).run.size == quine.size

lb = (0..a).bsearch { Computer.new(quine, a: _1).run.size == quine.size }
ub = (a..ub).bsearch { Computer.new(quine, a: _1).run.size != quine.size }

puts "0. #{lb.to_s(16)}...#{ub.to_s(16)}"

d = 1
N = 2048
while ub - lb > N
  step = (ub - lb) / N
  lb += step until Computer.new(quine, a: lb).run.last(d) == quine.last(d)
  lb -= step

  ub -= step until Computer.new(quine, a: ub).run.last(d) == quine.last(d)
  ub += step

  puts "#{d}. #{lb.to_s(16)}...#{ub.to_s(16)}"
  d += 1
end

lb += 1 until Computer.new(quine, a: lb).run == quine
puts lb.to_s(16)
puts lb
