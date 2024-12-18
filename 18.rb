require_relative "search"

class Memory
  attr_accessor :w, :h, :t, :drops, :obstacles

  def initialize
    rows = ARGF.readlines
    self.w, self.h, self.t = rows.shift.split.map(&:to_i)
    self.drops = rows.map.with_index { |row, i| [i, row.split(?,).map(&:to_i)] }.to_h
    self.obstacles = drops.invert
  end

  def obstacle?(x, y, t = nil)
    o = obstacles[[x, y]]
    return false unless o

    o < (t || self.t)
  end
end

class SearchNode < Search::Node
  attr_accessor :memory, :x, :y, :t

  def initialize(memory, x, y, t = nil)
    self.memory = memory
    self.x = x
    self.y = y
    self.t = t
  end

  def to_s
    t ? "#{x},#{y},#{t}" : "#{x},#{y}"
  end

  def hash
    to_s.hash
  end

  def enum_edges
    yield 1, SearchNode.new(memory, x - 1, y, t) unless x == 0 || memory.obstacle?(x - 1, y, t)
    yield 1, SearchNode.new(memory, x + 1, y, t) unless x == memory.w || memory.obstacle?(x + 1, y, t)
    yield 1, SearchNode.new(memory, x, y - 1, t) unless y == 0 || memory.obstacle?(x, y - 1, t)
    yield 1, SearchNode.new(memory, x, y + 1, t) unless y == memory.h || memory.obstacle?(x, y + 1, t)
  end

  def goal?
    x == memory.w && y == memory.h
  end
end

memory = Memory.new
puts Search::bfs(SearchNode.new(memory, 0, 0)).first

t = (memory.t...memory.drops.size).bsearch do |time|
  result = Search::bfs(SearchNode.new(memory, 0, 0, time))
  puts "#{time}: #{result ? result.first : "DNF"}"
  result.nil?
end

x, y = memory.drops[t - 1]
puts "#{t - 1}: #{x},#{y}"
