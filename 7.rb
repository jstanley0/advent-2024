def possible?(sum, operands, so_far = nil, cat: false)
  unless so_far
    operands = operands.dup
    so_far = operands.shift
  end

  return so_far == sum if operands.empty?
  return false if so_far > sum

  cdr = operands.dup
  car = cdr.shift
  possible?(sum, cdr, so_far + car, cat:) ||
    possible?(sum, cdr, so_far * car, cat:) ||
    cat && possible?(sum, cdr, (so_far.to_s + car.to_s).to_i, cat:)
end

data = ARGF.readlines.map do |line|
  sum, operands = line.split(':')
  [sum.to_i, operands.split.map(&:to_i)]
end

puts data.sum { |sum, operands| possible?(sum, operands) ? sum : 0 }
puts data.sum { |sum, operands| possible?(sum, operands, cat: true) ? sum : 0 }
