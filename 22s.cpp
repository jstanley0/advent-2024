#include <iostream>
#include <fstream>
#include <vector>

class Monkey {
  int secret, size;
  int prices[2000];

  int next(int num) {
    num = ((num << 6) ^ num) & 0xFFFFFF;
    num = ((num >> 5) ^ num) & 0xFFFFFF;
    num = ((num << 11) ^ num) & 0xFFFFFF;
    return num;
  }

public:
  explicit Monkey(int n) : secret(n), size(0) {}

  int generate() {
    int n = secret;
    while(size < 2000) {
      n = next(n);
      prices[size++] = n % 10;
    }
    return n;
  }

  int bid(int d0, int d1, int d2, int d3) const {
    for(int i = 1; i < size - 4; ++i) {
      if (prices[i] - prices[i - 1] == d0 &&
          prices[i + 1] - prices[i] == d1 &&
          prices[i + 2] - prices[i + 1] == d2 &&
          prices[i + 3] - prices[i + 2] == d3)
      {
        return prices[i + 3];
      }
    }
    return 0;
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
    monkeys.emplace_back(Monkey(n));
  }
  std::cerr << "Read " << monkeys.size() << " monkeys." << std::endl;

  long total = 0;
  for(auto &monkey : monkeys){
    total += monkey.generate();
  }
  std::cout << total << std::endl;

  int best = 0;
  for(int d0 = -9; d0 <= 9; ++d0) {
    for(int d1 = -9; d1 <= 9; ++d1) {
      for(int d2 = -9; d2 <= 9; ++d2) {
        for(int d3 = -9; d3 <= 9; ++d3) {
          int bid = 0;
          for(const auto &monkey : monkeys) {
            bid += monkey.bid(d0, d1, d2, d3);
          }
          if (bid > best) {
            best = bid;
            std::cerr << d0 << "," << d1 << "," << d2 << "," << d3 << " -> " << best << std::endl;
          }
        }
      }
    }
  }
  std::cout << best << std::endl;

  return 0;
}
