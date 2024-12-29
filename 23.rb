conns = ARGF.readlines.map { _1.strip.split(?-).sort }

pcs = conns.flatten.uniq
puts "total PCs: #{pcs.size}"

conns = Set.new(conns)
cmap = pcs.map { |pc| [pc, pcs.select { |other| conns.include?([pc, other].sort) } ] }.to_h
#pp cmap

cl3ques = Set.new
cmap.each do |pc, conns|
  conns.combination(2).each do |c1, c2|
    cl3ques << [pc, c1, c2].sort if cmap[c1].include?(c2)
  end
end

#pp cl3ques
puts cl3ques.size
puts cl3ques.count { |clique| clique.any? { |pc| pc.start_with?('t') } }

def find_cliques(graph, r = [], p = graph.keys, x = [])
  cliques = []
  if p.empty? && x.empty?
    cliques << r
  else
    while (v = p.shift)
      cliques += find_cliques(graph, r | [v], p & graph[v], x & graph[v])
      x << v
    end
  end
  cliques
end

cliques = find_cliques(cmap)
#pp cliques
puts cliques.sort_by(&:size).last.sort.join(?,)
