require_relative 'skim'

map = Skim.read
sum = map.all_coords('0').sum do |x, y|
  goals = Set.new
  map.bfs(x, y, diag: false, goal: nil) do |source_char, dest_char, x0, y0, x1, y1|
    goals << [x0, y0] if source_char == '9'
    (dest_char.ord == source_char.ord + 1) ? 1 : nil
  end
  puts "trailhead at #{x},#{y} has score #{goals.size}"
  goals.size
end
puts sum
