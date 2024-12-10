a, b = ARGF.readlines.map { _1.split.map(&:to_i) }.transpose.map(&:sort)
puts a.zip(b).sum { (_2 - _1).abs }
puts a.sum { b.count(_1) * _1 }
