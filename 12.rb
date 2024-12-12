require_relative 'skim'

Region = Struct.new(:area, :perimeter)
regions = []

map = Skim.read
rmap = Skim.new(map.width, map.height)
map.each do |c, x, y|
  if y > 0 && map[x, y - 1] == c
    ri = rmap[x, y - 1]
    regions[ri].area += 1
    regions[ri].perimeter += 2
  end
  if x > 0 && map[x - 1, y] == c
    if ri
      lr = rmap[x - 1, y]
      if lr == ri
        regions[ri].perimeter -= 2
      else
        regions[ri].area += regions[lr].area
        regions[ri].perimeter = regions[ri].perimeter + regions[lr].perimeter - 2
        regions[lr].area = 0
        rmap.flood_fill!(x - 1, y, ri)
      end
    else
      ri = rmap[x - 1, y]
      regions[ri].area += 1
      regions[ri].perimeter += 2
    end
  end
  unless ri
    ri = regions.size
    regions << Region.new(1, 4)
  end
  rmap[x, y] = ri
end

puts regions.sum { _1.area * _1.perimeter }

def in_region?(rmap, ri, x, y)
  rmap.in_bounds?(x, y) && rmap[x, y] == ri
end

rmap.each do |ri, x, y|
  if in_region?(rmap, ri, x + 1, y)
    regions[ri].perimeter -= 1 unless in_region?(rmap, ri, x, y - 1) || in_region?(rmap, ri, x + 1, y - 1)
    regions[ri].perimeter -= 1 unless in_region?(rmap, ri, x, y + 1) || in_region?(rmap, ri, x + 1, y + 1)
  end
  if in_region?(rmap, ri, x, y + 1)
    regions[ri].perimeter -= 1 unless in_region?(rmap, ri, x - 1, y) || in_region?(rmap, ri, x - 1, y + 1)
    regions[ri].perimeter -= 1 unless in_region?(rmap, ri, x + 1, y) || in_region?(rmap, ri, x + 1, y + 1)
  end
end

puts regions.sum { _1.area * _1.perimeter }
