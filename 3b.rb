puts ARGF.read.split("do()").sum { |chunk| chunk.split("don't()", 2).first.scan(/mul\((\d+),(\d+)\)/).sum { _1.map(&:to_i).inject(:*) } }
