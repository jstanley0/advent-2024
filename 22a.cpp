#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <algorithm>
#include <unordered_map>
#include <unordered_set>

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

typedef std::unordered_map<PackedDiff, int> BidMap;

class Monkey {
  int secret;

  int next(int num) {
    num = ((num << 6) ^ num) & 0xFFFFFF;
    num = ((num >> 5) ^ num) & 0xFFFFFF;
    num = ((num << 11) ^ num) & 0xFFFFFF;
    return num;
  }

public:
  explicit Monkey(int n) : secret(n) {}

  int generate(BidMap &all_bids) {
    int prices[2000];
    int n = secret;
    for(int i = 0; i < 2000; ++i) {
      n = next(n);
      prices[i] = n % 10;
    }
    std::unordered_set<PackedDiff> my_bids;
    for(int i = 4; i < 2000; ++i) {
      PackedDiff diff{ prices[i - 3] - prices[i - 4],
                       prices[i - 2] - prices[i - 3],
                       prices[i - 1] - prices[i - 2],
                       prices[i] - prices[i - 1] };
      if (my_bids.insert(diff).second) {
        all_bids[diff] += prices[i];      
      }
    }
    return n;
  }
};

int main(int argc, char **argv) {
  if (argc < 2) {
    std::cerr << "usage: " << argv[0] << " infile" << std::endl;
    return 1;
  }

  std::vector<Monkey> monkeys;
  std::ifstream infile(argv[1]);
  int n;
  while(infile >> n) {
    monkeys.emplace_back(n);
  }
  std::cerr << "Read " << monkeys.size() << " monkeys." << std::endl;

  long total = 0;
  BidMap bids;
  for(auto &monkey : monkeys){
    total += monkey.generate(bids);
  }
  std::cout << total << std::endl;

  auto best = std::max_element(bids.begin(), bids.end(), [](const auto &lhs, const auto &rhs) {
    return lhs.second < rhs.second;
  });
  std::cout << best->first << " " << best->second << std::endl;

  return 0;
}
