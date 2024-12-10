require_relative 'skim'

def path_count(map, x, y)
  c = map[x, y]
  return 1 if c == '9'

  nc = (c.ord + 1).chr
  count = 0
  map.nabes(x, y, diag: false) do |v, i, j|
    count += path_count(map, i, j) if v == nc
  end
  count
end

sum = 0
map = Skim.read
map.all_coords('0') do |x, y|
  paths = path_count(map, x, y)
  puts "trailhead at #{x},#{y} has rating #{paths}"
  sum += paths
end
puts sum
