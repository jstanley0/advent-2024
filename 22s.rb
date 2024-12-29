class Monkey
  attr_accessor :secret, :prices

  def gen(num)
    num = ((num << 6) ^ num) & 0xFFFFFF
    num = ((num >> 5) ^ num)
    num = ((num << 11) ^ num) & 0xFFFFFF
    num
  end

  def initialize(secret)
    self.secret = secret
  end

  def generate
    self.prices = []
    n = secret
    2000.times do
      n = gen(n)
      prices << n % 10
    end
    n
  end

  def bid(d0, d1, d2, d3)
    (1..prices.size - 4).each do |i|
      return prices[i + 3] if (prices[i] - prices[i - 1] == d0 &&
                               prices[i + 1] - prices[i] == d1 &&
                               prices[i + 2] - prices[i + 1] == d2 &&
                               prices[i + 3] - prices[i + 2] == d3)
    end
    0
  end
end

monkeys = ARGF.readlines.map { Monkey.new(_1.to_i) }
total = monkeys.sum { _1.generate }
puts total

best = 0
(-9..9).each do |d0|
  (-9..9).each do |d1|
    (-9..9).each do |d2|
      (-9..9).each do |d3|
        bid = monkeys.sum { _1.bid(d0, d1, d2, d3) }
        if (bid > best)
          best = bid
          puts "#{d0},#{d1},#{d2},#{d3} -> #{best}"
        end
      end
    end
  end
end
puts best
