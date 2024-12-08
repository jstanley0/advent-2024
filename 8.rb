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
    nodes << [x0 - dx, y0 - dy]
    nodes << [x1 + dx, y1 + dy]
  end
end

puts nodes.size

puts nodes.select { |x, y| (0...w).include?(x) && (0...h).include?(y) }.size
