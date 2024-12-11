stones = ARGF.read.split
25.times do |n|
  new_stones = []
  stones.each do |stone|
    if stone == "0"
      new_stones << "1"
    elsif stone.size.even?
      new_stones << stone[0...stone.size/2]
      new_stones << stone[stone.size/2..].to_i.to_s
    else
      new_stones << (stone.to_i * 2024).to_s
    end
  end
  stones = new_stones
  puts "blink #{n + 1}: #{stones.size}"
end
