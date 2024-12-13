Puzzle = Struct.new(:ax, :ay, :bx, :by, :x, :y) do
  def solve
    best_cost = nil
    100.times do |a|
      100.times do |b|
        if a * ax + b * bx == x && a * ay + b * by == y
          cost = 3 * a + b
          best_cost = cost if best_cost.nil? || best_cost > cost
        end
      end
    end
    best_cost
  end
end
puzzles = ARGF.read.split("\n\n").map { Puzzle.new(*_1.scan(/\d+/m).map(&:to_i)) }
puts puzzles.map(&:solve).compact.sum
