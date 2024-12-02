data = ARGF.readlines.map { _1.split.map(&:to_i) }
a = data.map(&:first).sort
b = data.map(&:last).sort
puts a.each_index.sum { |i| (b[i] - a[i]).abs }
puts a.sum { b.count(_1) * _1 }
