require_relative "skim"
require_relative "search"

class SearchNode < Search::Node
  attr_accessor :skim, :x, :y, :c, :cc

  def initialize(skim, x, y, c = 0, cc = [])
    self.skim = skim
    self.x = x
    self.y = y
    self.c = c
    self.cc = cc
  end

  def to_s
    "#{x},#{y},#{cc.inspect}"
  end

  def hash
    to_s.hash
  end

  def enum_edges
    return if skim[x, y] == 'E' || c >= $no_cheat_time

    [[-1, 0], [1, 0], [0, -1], [0, 1]].each do |dx, dy|
      if skim.in_bounds?(x + dx, y + dy)
        if skim[x + dx, y + dy] == '#'
          if cc.empty?
            dcc = cc.dup
            dcc << [x, y]
            yield 1, SearchNode.new(skim, x + dx, y + dy, c + 1, dcc)
          end
        else
          if cc.size == 1
            dcc = cc.dup
            dcc << [x + dx, y + dy]
          end
          yield 1, SearchNode.new(skim, x + dx, y + dy, c + 1, dcc || cc)
        end
      end
    end
  end

  def goal?(_)
    if skim[x, y] == 'E'
      if c <= $no_cheat_time - 100
        $cheat_stats[$no_cheat_time - c] ||= Set.new
        $cheat_stats[$no_cheat_time - c] << cc
      end
    end
    false
  end
end


map = Skim.read
x, y = map.find_coords('S')

$no_cheat_time = map.bfs(x, y, goal: 'E') { |_, d| d != '#' }.first
puts $no_cheat_time

$cheat_stats = {}
$best_cheats = Set.new
Search::bfs(SearchNode.new(map, x, y))

stats = $cheat_stats.transform_values(&:size)
puts stats.inspect
puts stats.sum { |savings, num| savings >= 100 ? num : 0 }

# > 33
