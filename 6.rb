class Maze
  DIRS = [[0, -1], [1, 0], [0, 1], [-1, 0]]
  attr_accessor :maze, :w, :h, :start_x, :start_y, :visited

  def initialize(stream)
    self.maze = ARGF.readlines
    self.w = maze[0].size
    self.h = maze.size
    self.start_y = maze.find_index { _1.include?('^') }
    self.start_x = maze[start_y].index('^')
  end

  def overwrite(x, y, c)
    maze[y][x] = c
  end

  # return true if looped
  def run
    dir = 0
    x = start_x
    y = start_y

    self.visited = Set.new
    until visited.include?(dir << 24 | y << 12 | x)
      visited << (dir << 24 | y << 12 | x)
      nx = x + DIRS[dir][0]
      ny = y + DIRS[dir][1]
      return false unless (0...w).include?(nx) && (0...h).include?(ny)

      if maze[ny][nx] == '#'
        dir = (dir + 1) & 3
      else
        x = nx
        y = ny
      end
    end

    true
  end

  def cells_visited
    visited.map { [_1 & 0xFFF, (_1 >> 12) & 0xFFF] }.uniq
  end
end

maze = Maze.new(ARGV)
maze.run
cells = maze.cells_visited
puts cells.size

n = 0
(cells - [maze.start_x, maze.start_y]).each do |x, y|
  maze.overwrite(x, y, '#')
  n += 1 if maze.run
  maze.overwrite(x, y, '.')
end
puts n
