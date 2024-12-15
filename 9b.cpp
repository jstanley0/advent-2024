#include <list>
#include <vector>
#include <iostream>

struct Extent {
  long pos;
  int size;
  int file_id;
};

int main(int argc, char **argv) {
  std::list<Extent> disk;
  int file_id = 0;
  long pos = 0;
  bool space = false;
  int c;
  while(EOF != (c = std::cin.get()) && std::isdigit(c)) {
    int size = c - '0';
    disk.emplace_back(pos, size, space ? -1 : file_id);
    if ((space = !space))
      ++file_id;
    pos += size;
  }
  --file_id;

  std::vector<std::list<Extent>::iterator> sits(10, disk.begin());
  auto fit = std::prev(disk.end());
  for(;;) {
    while (fit != disk.begin() && fit->file_id != file_id)
      --fit;
    if (fit == disk.begin())
      break;
    
    auto &sit = sits[fit->size];
    for(; sit != disk.end() && sit->pos < fit->pos && (sit->file_id >= 0 || sit->size < fit->size); ++sit);
    if (sit != disk.end() && sit->pos < fit->pos) {
      auto np = fit->pos;
      auto nx = std::next(fit);
      
      // move file to new position, displacing and shrinking space extent
      disk.splice(sit, disk, fit);
      fit->pos = sit->pos;
      sit->pos += fit->size;
      sit->size -= fit->size;

      // insert space extent in file's old location and consolidate
      nx = disk.insert(nx, Extent{np, fit->size, -1});
      auto right = std::next(nx);
      if (right != disk.end() && right->file_id < 0) {
        nx->size += right->size;
        disk.erase(right);
      }
      auto left = std::prev(nx);
      if (left->file_id < 0) {
        left->size += nx->size;
        disk.erase(nx);
        nx = left;
      }
      fit = nx;
    }
   
    --file_id;
  }

  long sum = 0;
  for(auto &extent : disk) {
    if (extent.file_id >= 0) {
      sum += extent.file_id * extent.size * (2 * extent.pos + extent.size - 1) / 2;
    }
  }
  std::cout << sum << std::endl;

  return 0;
}