#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <bitset>
#include <algorithm>

struct PackedDiff
{
  int v;

  explicit PackedDiff(int index) : v(index) {}
  PackedDiff(int d0, int d1, int d2, int d3) : v((d0 + 9) * 6859 + (d1 + 9) * 361 + (d2 + 9) * 19 + (d3 + 9)) {}
  inline int index() const { return v; }

  friend std::ostream& operator<<(std::ostream& os, const PackedDiff& obj) {
    return os << (obj.v / 6859) - 9 << ","
     << ((obj.v / 361) % 19) - 9 << ","
     << ((obj.v / 19) % 19) - 9 << ","
     << (obj.v % 19) - 9;
  }
};

struct BidMap
{
  std::array<int, 130321> bids;

  BidMap() { std::fill(bids.begin(), bids.end(), 0); }
  
  int operator[](const PackedDiff& pd) const { return bids[pd.index()]; }
  PackedDiff best_index() const {
    auto it = std::max_element(bids.begin(), bids.end());
    return PackedDiff(it - bids.begin());
  }

  int add(const PackedDiff& pd, int val) { return bids[pd.index()] += val; }
};

class Monkey {
  int secret;

  int next(int num) {
    num = ((num << 6) ^ num) & 0xFFFFFF;
    num = ((num >> 5) ^ num);
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
    std::bitset<130321> my_bids;
    for(int i = 4; i < 2000; ++i) {
      PackedDiff diff{ prices[i - 3] - prices[i - 4],
                       prices[i - 2] - prices[i - 3],
                       prices[i - 1] - prices[i - 2],
                       prices[i] - prices[i - 1] };
      if (my_bids[diff.index()] == 0) {
        my_bids.set(diff.index());
        all_bids.add(diff, prices[i]);
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

  PackedDiff best = bids.best_index();
  std::cout << best << " " << bids[best] << std::endl;

  return 0;
}
