require 'pqueue'

class Search
  # to use Search, derive from Search::Node and implement `enum_edges`
  # and probably one or the other of `goal?` and `est_dist`
  class Node
    # expected to yield cost, node pairs
    def enum_edges
    end

    # for bfs, indicate whether a goal state has been reached
    def goal?
    end

    # for a_star, estimate cost to another node
    # (this method must not underestimate it)
    def est_cost(other)
    end

    # something that compares equal if the search states are equivalent
    def hash
    end

    def eql?(other)
      hash == other.hash
    end

    # in case there are attributes such as time that aren't part of the A* heuristic
    def fuzzy_equal?(other)
      eql?(other)
    end

    # used by the underlying implementation; Search users don't need to touch this
    attr_accessor :cost_heuristic
  end

  # finds a least-cost path from start_node to a goal node
  # and returns [cost, [search_node, search_node...]]
  def self.bfs(start_node)
    search_impl(start_node,
                ->(node) { node.goal? },
                ->(_node, cost_so_far) { cost_so_far })
  end

  # finds a least-cost path from start_node to end_node
  # and returns [cost, [search_node, search_node...]]
  def self.a_star(start_node, end_node)
    search_impl(start_node,
                ->(node) { node.fuzzy_equal?(end_node) },
                ->(node, cost_so_far) { cost_so_far + node.est_cost(end_node) })
  end

  private

  def self.search_impl(start_node, goal_proc, cost_heuristic_proc)
    path_links = {}
    best_cost_to = { start_node => 0 }
    fringe = PQueue.new { |a, b| a.cost_heuristic < b.cost_heuristic }
    start_node.cost_heuristic = cost_heuristic_proc.call(start_node, 0)
    fringe.push start_node

    until fringe.empty?
      node = fringe.pop
      cost_so_far = best_cost_to[node]
      # puts "searching from #{node} at cost #{cost_so_far}"
      return cost_so_far, build_path(path_links, node) if goal_proc.call(node)

      node.enum_edges do |cost, neighbor|
        cost_to_neighbor = cost_so_far + cost
        if best_cost_to[neighbor].nil? || cost_to_neighbor < best_cost_to[neighbor]
          best_cost_to[neighbor] = cost_to_neighbor
          path_links[neighbor] = node
          neighbor.cost_heuristic = cost_heuristic_proc.call(neighbor, cost_to_neighbor)
          fringe.push neighbor
        end
      end
    end

    nil
  end

  def self.build_path(path_links, target_point)
    path = [target_point]
    while (target_point = path_links[target_point])
      path.unshift target_point
    end
    path
  end
end

