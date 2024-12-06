DIRS = [[0, -1], [1, 0], [0, 1], [-1, 0]]

def looped?(maze, x, y, w, h)
  dir = 0

  visited = Set.new
  until visited.include?([x, y, dir])
    visited << [x, y, dir]
    nx = x + DIRS[dir][0]
    ny = y + DIRS[dir][1]
    return false unless (0...w).include?(nx) && (0...h).include?(ny)

    if maze[ny][nx] == '#'
      dir = (dir + 1) & 3
    else
      x, y = nx, ny
    end
  end

  true
end

maze = ARGF.readlines
w = maze[0].size
h = maze.size
y = maze.find_index { _1.include?('^') }
x = maze[y].index('^')
n = 0

w.times do |i|
  h.times do |j|
    if maze[j][i] == '.'
      maze[j][i] = '#'
      n += 1 if looped?(maze, x, y, w, h)
      maze[j][i] = '.'
    end
  end
end
puts n
