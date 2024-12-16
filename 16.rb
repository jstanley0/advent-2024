require_relative "skim"

class ReindeerSearchNode < Skim::SearchNode
  attr_accessor :dir

  def initialize(context, x, y, dir)
    self.context = context
    self.x = x
    self.y = y
    self.dir = dir
  end

  def enum_edges
    if context.skim[x + Skim::DX[dir], y + Skim::DY[dir]] != '#'
      yield 1, ReindeerSearchNode.new(context, x + Skim::DX[dir], y + Skim::DY[dir], dir)
    end
    yield 1000, ReindeerSearchNode.new(context, x, y, (dir - 1) & 3)
    yield 1000, ReindeerSearchNode.new(context, x, y, (dir + 1) & 3)
  end

  def hash
    1000000 * dir + super
  end

  def to_s
    "(#{x},#{y},#{dir})"
  end
end

map = Skim.read

x, y = map.find_coords('S')

context = Skim::SearchContext.new(map, false, nil, 'E')
results = Search::bfs(ReindeerSearchNode.new(context, x, y, 0), find_all_paths: true)
puts "best score: #{results.shift}"
puts "#{results.size} best paths"

cells = Set.new
results.each_with_index do |path, i|
  path.each do |node|
    cells << [node.x, node.y]
    map[node.x, node.y] = 'O'
  end
end
map.print(highlights: ['O'])
puts "#{cells.size} cells on best paths"
