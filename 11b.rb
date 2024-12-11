stones = Hash.new(0)
ARGF.read.split.each { stones[_1] += 1 }
75.times do |n|
  new_stones = Hash.new(0)
  stones.each do |stone, count|
    if stone == "0"
      new_stones["1"] += count
    elsif stone.size.even?
      new_stones[stone[0...stone.size/2]] += count
      new_stones[stone[stone.size/2..].to_i.to_s] += count
    else
      new_stones[(stone.to_i * 2024).to_s] += count
    end
  end
  stones = new_stones
  puts "blink #{n + 1}: #{stones.size} distinct values; #{stones.values.sum} total stones"
end
