patterns, towels = ARGF.read.split("\n\n")
patterns = patterns.split(", ")
towels = towels.split

def can_make?(towel, patterns)
  return true if towel.empty?

  pats = patterns.select { |pat| towel.start_with?(pat) }
  pats.any? { |pat| can_make?(towel[pat.size..], patterns) }
end

puts towels.count { |towel| can_make?(towel, patterns) }
