require_relative "search"

class Memory
  attr_accessor :w, :h, :cycles, :obstacles, :next_obstacles

  def initialize
    data = ARGF.readlines
    self.w, self.h, self.cycles = data.shift.split.map(&:to_i)
    self.obstacles = Set.new(data.first(cycles).map { _1.split(?,).map(&:to_i) })
    self.next_obstacles = data[cycles..].map { _1.split(?,).map(&:to_i) }
  end

  def drop
    o = next_obstacles.shift
    obstacles << o
    o
  end
end

class SearchNode < Search::Node
  attr_accessor :memory, :x, :y

  def initialize(memory, x, y)
    self.memory = memory
    self.x = x
    self.y = y
  end

  def to_s
    "#{x},#{y}"
  end

  def hash
    to_s.hash
  end

  def enum_edges
    yield 1, SearchNode.new(memory, x - 1, y) unless x == 0 || memory.obstacles.include?([x - 1, y])
    yield 1, SearchNode.new(memory, x + 1, y) unless x == memory.w || memory.obstacles.include?([x + 1, y])
    yield 1, SearchNode.new(memory, x, y - 1) unless y == 0 || memory.obstacles.include?([x, y - 1])
    yield 1, SearchNode.new(memory, x, y + 1) unless y == memory.h || memory.obstacles.include?([x, y + 1])
  end

  def goal?
    x == memory.w && y == memory.h
  end
end

memory = Memory.new
puts Search::bfs(SearchNode.new(memory, 0, 0)).first

loop do
  x, y = memory.drop
  next unless Search::bfs(SearchNode.new(memory, 0, 0)).nil?

  puts "#{x},#{y}"
  break
end
