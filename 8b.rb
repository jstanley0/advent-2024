map = ARGF.readlines.map(&:strip)
h = map.size
w = map[0].size

ants = {}
map.each_with_index do |row, y|
  row.chars.each_with_index do |c, x|
    if c != '.'
      ants[c] ||= []
      ants[c] << [x, y]
    end
  end
end

nodes = Set.new
ants.each do |freq, coords|
  coords.combination(2) do |(x0, y0), (x1, y1)|
    if x0 > x1
      x0, x1 = x1, x0
      y0, y1 = y1, y0
    end
    dx = x1 - x0
    dy = y1 - y0

    x, y = x0, y0
    while x >= 0 && (0...h).include?(y)
      nodes << [x, y]
      x -= dx
      y -= dy
    end

    x, y = x1, y1
    while x < w && (0...h).include?(y)
      nodes << [x, y]
      x += dx
      y += dy
    end
  end
end

puts nodes.size
