#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <sstream>
#include <algorithm>
#include <unordered_map>
#include <unordered_set>
#include <ranges>
#include <execution>
#include <atomic>

struct PackedDiff
{
  int v;

  PackedDiff(int d0, int d1, int d2, int d3) : v((d0 + 9) << 24 | (d1 + 9) << 16 | (d2 + 9) << 8 | (d3 + 9)) {}
  bool operator==(PackedDiff rhs) const { return v == rhs.v; }

  friend std::ostream& operator<<(std::ostream& os, const PackedDiff& obj) {
    return os << (obj.v >> 24) - 9 << ","
     << ((obj.v >> 16) & 0xFF) - 9 << ","
     << ((obj.v >> 8) & 0xFF) - 9 << ","
     << (obj.v & 0xFF) - 9;
  }
};

namespace std {
    template <>
    struct hash<PackedDiff> {
        size_t operator()(const PackedDiff& key) const {
            return std::hash<int>()(key.v);
        }
    };
}

typedef std::unordered_set<PackedDiff> BidSet;

class Monkey {
  int secret;
  std::unordered_map<PackedDiff, int> bids;

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
      PackedDiff diff{ prices[i - 3] - prices[i - 4],
                       prices[i - 2] - prices[i - 3],
                       prices[i - 1] - prices[i - 2],
                       prices[i] - prices[i - 1] };
      bids.try_emplace(diff, prices[i]);                  
      all_bids.insert(diff);              
    }
    return n;
  }

  int bid(PackedDiff diff) const {
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
  std::vector<PackedDiff> bid_vec;
  bid_vec.reserve(bids.size());
  bid_vec.insert(bid_vec.end(), bids.begin(), bids.end());

  std::mutex output_mtx;
  std::atomic<int> best = 0;
  std::for_each(std::execution::par, bid_vec.begin(), bid_vec.end(), [&](PackedDiff bid) {
    int bananas = 0;
    for(const auto &monkey : monkeys) {
      bananas += monkey.bid(bid);
    }
    if (update_max(best, bananas)) {
      std::lock_guard<std::mutex> lock(output_mtx);      
      std::cerr << bid << " -> " << best << std::endl;
    }
  });
  
  std::cout << best << std::endl;
  return 0;
}
