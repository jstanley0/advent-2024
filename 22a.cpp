#include <iostream>
#include <fstream>
#include <vector>
#include <algorithm>
#include <map>
#include <set>
#include <ranges>
#include <execution>
#include <atomic>

typedef std::array<int, 4> DiffArray;
typedef std::set<DiffArray> BidSet;

class Monkey {
  int secret;
  std::map<DiffArray, int> bids;

  int next(int num) {
    num = ((num << 6) ^ num) & 0xFFFFFF;
    num = ((num >> 5) ^ num) & 0xFFFFFF;
    num = ((num << 11) ^ num) & 0xFFFFFF;
    return num;
  }

public:
  explicit Monkey(int n) : secret(n) {}

  int generate(BidSet &all_bids) {
    int prices[2000];
    int n = secret;
    for(int i = 0; i < 2000; ++i) {
      n = next(n);
      prices[i] = n % 10;
    }
    for(int i = 4; i < 2000; ++i) {
      DiffArray diff = { prices[i - 3] - prices[i - 4],
                         prices[i - 2] - prices[i - 3],
                         prices[i - 1] - prices[i - 2],
                         prices[i] - prices[i - 1] };
      bids.try_emplace(diff, prices[i]);                  
      all_bids.insert(diff);              
    }
    return n;
  }

  int bid(const DiffArray& diff) const {
    auto it = bids.find(diff);
    if (it != bids.end())
      return it->second;

    return 0;
  }

  size_t size() const { return bids.size(); }
};

template <typename T>
inline bool update_max(std::atomic<T>& target, const T value) {
  T current = target.load();
  while (value > current) {
    if (target.compare_exchange_weak(current, value))
      return true;
    // current is implicitly updated
  }
  return false;
}

int main(int argc, char **argv) {
  if (argc < 2) {
    std::cerr << "usage: " << argv[0] << " infile" << std::endl;
    return 1;
  }

  std::vector<Monkey> monkeys;
  std::ifstream infile(argv[1]);
  int n;
  while(infile >> n) {
    monkeys.emplace_back(Monkey(n));
  }
  std::cerr << "Read " << monkeys.size() << " monkeys." << std::endl;

  long total = 0;
  BidSet bids;
  for(auto &monkey : monkeys){
    total += monkey.generate(bids);
  }
  std::cout << total << std::endl;
  std::cerr << bids.size() << " distinct possible bids" << std::endl;
  
  // parallel execution requires a random-access iterator to divvy up the work
  std::vector<DiffArray> bid_vec;
  bid_vec.reserve(bids.size());
  bid_vec.insert(bid_vec.end(), bids.begin(), bids.end());

  std::mutex output_mtx;
  std::atomic<int> best = 0;
  std::for_each(std::execution::par, bid_vec.begin(), bid_vec.end(), [&](const DiffArray& bid) {
    int bananas = 0;
    for(const auto &monkey : monkeys) {
      bananas += monkey.bid(bid);
    }
    if (update_max(best, bananas)) {
      std::lock_guard<std::mutex> lock(output_mtx);      
      std::cerr << bid[0] << "," << bid[1] << "," << bid[2] << "," << bid[3] << " -> " << best << std::endl;
    }
  });
  
  std::cout << best << std::endl;
  return 0;
}
