class Monkey
  attr_accessor :secret

  def gen(num)
    num = ((num << 6) ^ num) & 0xFFFFFF
    num = ((num >> 5) ^ num)
    num = ((num << 11) ^ num) & 0xFFFFFF
    num
  end

  def initialize(secret)
    self.secret = secret
  end

  def generate(bids)
    prices = []
    n = secret
    2000.times do
      n = gen(n)
      prices << n % 10
    end
    eval_bids(bids, prices)
    n
  end

  def eval_bids(bids, prices)
    seen = Set[]
    prices.each_cons(5) do |seq|
      diffs = seq.each_cons(2).map { _2 - _1 }
      next if seen.include?(diffs)

      seen << diffs
      bids[diffs] += seq.last
    end
  end
end

monkeys = ARGF.readlines.map { Monkey.new(_1.to_i) }
bids = Hash.new(0)
total = monkeys.sum { _1.generate(bids) }
puts total
best = bids.max_by{|_,v| v}
puts "#{best.first.join(",")} #{best.last}"
