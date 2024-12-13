require "z3"

Puzzle = Struct.new(:ax, :ay, :bx, :by, :x, :y) do
  def solve
    a = Z3.Int("a")
    b = Z3.Int("b")
    c = Z3.Int("c")
    z3 = Z3::Optimize.new
    z3.assert a * ax + b * bx == x
    z3.assert a * ay + b * by == y
    z3.assert a * 3 + b == c
    z3.minimize c
    z3.model[c].to_i if z3.satisfiable?
  end
end
puzzles = ARGF.read.split("\n\n").map { Puzzle.new(*_1.scan(/\d+/m).map(&:to_i)) }
puts puzzles.map(&:solve).compact.sum
