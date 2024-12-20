#include <iostream>
#include <algorithm>
#include <ranges>
#include <execution>

constexpr uint64_t ITERATIONS_PER_CHUNK = 0x40000000ULL;

template <typename T>
void atomic_min(std::atomic<T>& target, T value) {
    T current = target.load();
    while (value < current && !target.compare_exchange_weak(current, value));
}

bool run(uint64_t a) {
  uint64_t b, r = 0;
  while (a != 0) {
    b = (a & 7) ^ 1;
    b ^= (a >> b) ^ 4;
    a >>= 3;
    r = (r << 3) | b & 7;
  }
  return r == 02411754603145530ULL;
}

int main()
{
  std::atomic<uint64_t> result{std::numeric_limits<uint64_t>::max()};

  for(uint64_t a = 201972175280682ULL;; a += ITERATIONS_PER_CHUNK) {
    auto range = std::views::iota(a, a + ITERATIONS_PER_CHUNK);
    std::for_each(std::execution::par, range.begin(), range.end(), [&](uint64_t v) {
      if (run(v))
        atomic_min(result, v);
    });

    if (result.load() != std::numeric_limits<uint64_t>::max())
      break;

    std::cout << "> " << std::hex << (a + ITERATIONS_PER_CHUNK) << std::endl;
  }

  std::cout << result.load() << std::endl;
  return 0;
}
