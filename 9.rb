disk_map = ARGF.read.chars.map(&:to_i).each_slice(2).to_a

file_id = 0
disk = []
disk_map.each do |data, slack|
  disk.concat(Array.new(data, file_id))
  disk.concat(Array.new(slack)) if slack
  file_id += 1
end

l = 0
r = disk.size - 1
loop do
  l += 1 while l < r && !disk[l].nil?
  r -= 1 while l < r && disk[r].nil?
  break if l >= r

  disk[l] = disk[r]
  disk[r] = nil
end

puts disk.each_with_index.inject(0) { |sum, (v, i)| sum + v.to_i * i }
