word_search = ARGF.readlines

n = 0
(1...word_search.size - 1).each do |y|
  (1...word_search[y].size - 1).each do |x|
    if word_search[y][x] == 'A'
      ul = "MS".index(word_search[y - 1][x - 1])
      ur = "MS".index(word_search[y - 1][x + 1])
      ll = "SM".index(word_search[y + 1][x - 1])
      lr = "SM".index(word_search[y + 1][x + 1])
      n += 1 if ul && ul == lr && ur && ur == ll
    end
  end
end

puts n
