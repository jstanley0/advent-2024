require_relative 'skim'

def path_count(map, x, y)
  c = map[x, y]
  return 1 if c == '9'

  nc = (c.ord + 1).chr
  map.nabes(x, y, diag: false).filter_map { |v, i, j| path_count(map, i, j) if v == nc }.sum
end

map = Skim.read
puts map.all_coords('0').sum { |x, y| path_count(map, x, y) }
