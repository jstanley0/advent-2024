rules, updates = ARGF.read.split("\n\n")
rules = rules.split("\n").map { _1.split("|").map(&:to_i) }
updates = updates.split("\n").map { _1.split(",").map(&:to_i) }

good, bad = updates.partition do |update|
  rules.all? do |a, b|
    i = update.index(a)
    j = update.index(b)
    !i || !j || i < j
  end
end

puts good.sum { _1[_1.size / 2] }

bad.map! do |update|
  loop do
    swapped = false
    rules.each do |a, b|
      i = update.index(a)
      j = update.index(b)
      if i && j && i > j
        swapped = true
        update.insert(j, update.delete_at(i))
      end
    end
    break unless swapped
  end
  update
end

puts bad.sum { _1[_1.size / 2] }
