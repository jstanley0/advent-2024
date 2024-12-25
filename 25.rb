require_relative "skim"

locks, keys = Skim.read_many.partition { _1[0,0] == '#' }
puts locks.product(keys).count { |lock, key|
  lock.cols.zip(key.cols).all? { |l, k| l.count('#') + k.count('#') <= 7 }
}
