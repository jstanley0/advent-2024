word_search = ARGF.readlines

DIRS = [[-1, -1], [-1, 0], [-1, 1],
  [0, -1], [0, 1],
  [1, -1], [1, 0], [1, 1]]

def match?(word, word_search, x, y, dx, dy)
  return true if word.empty?

  (0...word_search.size).include?(y) && (0...word_search[y].size).include?(x) && word_search[y][x] == word[0] &&
    match?(word[1..], word_search, x + dx, y + dy, dx, dy)
end

n = 0
word_search.each_with_index do |row, y|
  row.size.times do |x|
    n += DIRS.count { |dx, dy| match?('XMAS', word_search, x, y, dx, dy) }
  end
end

puts n
