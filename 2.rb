def safe?(row)
  diffs = row.each_cons(2).map { _2 - _1 }
  diffs.all? { (1..3).include?(_1) } || diffs.all? { (-3..-1).include?(_1) }
end

def permute_row(row)
  result = [row]
  row.each_index do |i|
    result << row.dup.tap { _1.delete_at(i) }
  end
  result
end

data = ARGF.readlines.map { _1.split.map(&:to_i) }
puts data.count { safe?(_1) }
puts data.count { |row| permute_row(row).any? { safe?(_1) } }
