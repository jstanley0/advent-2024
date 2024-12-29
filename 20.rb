require_relative "skim"

def mark_path(map, x, y, c = 0)
  path = []
  loop do
    map[x, y] = c
    path << [x, y]
    _, x1, y1 = map.nabes(x, y, diag: false).find { |v, _, _| v.is_a?(String) && v != '#' }
    break if x1.nil?

    c += 1
    x = x1
    y = y1
  end
  path
end

map = Skim.read
x, y = map.find_coords("S")
path = mark_path(map, x, y)

shortcut_counts = Hash.new(0)

path.each do |x, y|
  [[-1, 0], [1, 0], [0, -1], [0, 1]].each do |dx, dy|
    x1, y1 = x + dx, y + dy
    x2, y2 = x + dx + dx, y + dy + dy
    if map.in_bounds?(x2, y2) && map[x1, y1] == '#' && map[x2, y2].is_a?(Integer) && map[x2, y2] > map[x, y]
      shortcut_size = map[x2, y2] - map[x, y] - 2
      shortcut_counts[shortcut_size] += 1
    end
  end
end

puts shortcut_counts.inspect if map.width < 50
puts shortcut_counts.select { |k, v| k >= 100 }.values.sum

shortcut_counts = Hash.new(0)
path.each do |x, y|
  (x-20..x+20).each do |x2|
    (y-20..y+20).each do |y2|
      manhattan = (x2 - x).abs + (y2 - y).abs
      if map.in_bounds?(x2, y2) && manhattan <= 20 && map[x2, y2].is_a?(Integer) && map[x2, y2] > map[x, y]
        shortcut_size = map[x2, y2] - map[x, y] - manhattan
        shortcut_counts[shortcut_size] += 1
      end
    end
  end
end

puts shortcut_counts.inspect if map.width < 50
puts shortcut_counts.select { |k, v| k >= 100 }.values.sum
