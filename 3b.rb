def count(segment)
  segment.scan(/mul\((\d{1,3}),(\d{1,3})\)/).sum { _1.map(&:to_i).inject(:*) }
end

chunks = ARGF.read.split("don't()")
puts count(chunks.shift) + chunks.sum { |chunk| count(chunk.split("do()", 2)[1] || "") }
