require_relative "skim"

MOVES = {
  "<" => [-1, 0],
  ">" => [1, 0],
  "^" => [0, -1],
  "v" => [0, 1]
}

map = Skim.read
moves = ARGF.read.scan(/\S/)

x, y = map.find_coords("@")
moves.each do |move|
  dx, dy = MOVES[move]
  c = map[x + dx, y + dy]
  case c
  when '.'
    map[x, y] = '.'
    x += dx
    y += dy
    map[x, y] = '@'
  when 'O'
    nx = x + 2 * dx
    ny = y + 2 * dy
    while map[nx, ny] == 'O'
      nx += dx
      ny += dy
    end
    if map[nx, ny] == '.'
      map[nx, ny] = 'O'
      map[x, y] = '.'
      x += dx
      y += dy
      map[x, y] = '@'
    end
  end
  #map.print(highlights: %w[@])
end

sum = 0
map.each do |c, x, y|
  sum += 100 * y + x if c == 'O'
end
puts sum
