#include <iostream>
#include <fstream>
#include <vector>
#include <algorithm>
#include <ranges>
#include <execution>
#include <atomic>

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
  for(auto &monkey : monkeys){
    total += monkey.generate();
  }
  std::cout << total << std::endl;

  std::mutex output_mtx;
  std::atomic<int> best = 0;
  auto range = std::views::iota(0, 19 * 19 * 19 * 19);
  std::for_each(std::execution::par, range.begin(), range.end(), [&](int n) {
    int d0 = (n / (19 * 19 * 19)) - 9;
    int d1 = ((n / (19 * 19)) % 19) - 9;
    int d2 = ((n / 19) % 19) - 9;
    int d3 = (n % 19) - 9;
    int bid = 0;
    for(const auto &monkey : monkeys) {
      bid += monkey.bid(d0, d1, d2, d3);
    }
    if (update_max(best, bid)) {
      std::lock_guard<std::mutex> lock(output_mtx);
      std::cerr << d0 << "," << d1 << "," << d2 << "," << d3 << " -> " << best << std::endl;
    }
  });

  std::cout << best << std::endl;

  return 0;
}
