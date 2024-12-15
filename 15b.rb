require_relative "skim"

MOVES = {
  "<" => [-1, 0],
  ">" => [1, 0],
  "^" => [0, -1],
  "v" => [0, 1]
}

old_map = Skim.read
moves = ARGF.read.scan(/\S/)

map = Skim.new(old_map.width * 2, old_map.height)
old_map.each do |c, x, y|
  nx = x * 2
  case c
  when '#', '.'
    map[nx, y] = map[nx + 1, y] = c
  when 'O'
    map[nx, y] = '['
    map[nx + 1, y] = ']'
  when '@'
    map[nx, y] = '@'
    map[nx + 1, y] = '.'
  end
end

Box = Struct.new(:x, :y)

def box_at(map, bx, by)
  case map[bx, by]
  when '['
    raise "box split L" unless map[bx + 1, by] == ']'
    Box.new(bx, by)
  when ']'
    raise "box split R" unless map[bx - 1, by] == '['
    Box.new(bx - 1, by)
  else
    nil
  end
end

def box_can_move?(map, box, dy)
  return false if map[box.x, box.y + dy] == '#' || map[box.x + 1, box.y + dy] == '#'

  secondary_boxes = [box_at(map, box.x, box.y + dy), box_at(map, box.x + 1, box.y + dy)].compact.uniq
  secondary_boxes.all? { |sb| box_can_move?(map, sb, dy) }
end

def push_box(map, box, dy)
  secondary_boxes = [box_at(map, box.x, box.y + dy), box_at(map, box.x + 1, box.y + dy)].compact.uniq
  secondary_boxes.each { |sb| push_box(map, sb, dy) }
  raise "box broken" unless map[box.x, box.y] == '[' && map[box.x + 1, box.y] == ']'
  raise "can't push" unless map[box.x, box.y + dy] == '.' && map[box.x + 1, box.y + dy] == '.'
  map[box.x, box.y + dy] = '['
  map[box.x + 1, box.y + dy] = ']'
  map[box.x, box.y] = map[box.x + 1, box.y] = '.'
  nil
end

x, y = map.find_coords("@")
moves.each do |move|
  case move
  when '<', '>'
    dx, _ = MOVES[move]
    case map[x + dx, y]
    when '[', ']'
      nx = x + 2 * dx
      nx += dx while %w{[ ]}.include?(map[nx, y])
      if map[nx, y] == '.'
        while nx != x
          map[nx, y] = map[nx - dx, y]
          nx -= dx
        end
        map[nx, y] = '.'
        x += dx
      end
    when '.'
      map[x, y] = '.'
      x += dx
      map[x, y] = '@'
    end
  when '^', 'v'
    _, dy = MOVES[move]
    box = box_at(map, x, y + dy)
    push_box(map, box, dy) if box && box_can_move?(map, box, dy)
    if map[x, y + dy] == '.'
      map[x, y] = '.'
      y += dy
      map[x, y] = '@'
    end
  end
  #puts move
  #map.print(highlights: %w[@])
end

sum = 0
map.each do |c, x, y|
  sum += 100 * y + x if c == '['
end
puts sum
