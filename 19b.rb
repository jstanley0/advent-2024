patterns, towels = ARGF.read.split("\n\n")
patterns = patterns.split(", ")
towels = towels.split

def variations(towel, patterns, memo = {})
  return 1 if towel.empty?
  return memo[towel] if memo.key?(towel)

  pats = patterns.select { |pat| towel.start_with?(pat) }
  memo[towel] = pats.sum { |pat| variations(towel[pat.size..], patterns, memo) }
end

puts towels.sum { |towel| variations(towel, patterns) }
