#include <iostream>
#include <fstream>
#include <ranges>
#include <vector>
#include <string>
#include <set>

static const int DX[] = {0, 1, 0, -1};
static const int DY[] = {-1, 0, 1, 0};

class Maze {
  std::vector<std::string> maze;
  int w, h, start_x, start_y;

public:
  Maze(std::istream& stream) {
    for(const auto& line : std::ranges::istream_view<std::string>(stream)) {
      auto pos = line.find("^");
      if (pos != std::string::npos) {
        start_x = pos;
        start_y = maze.size();
      }
      maze.push_back(line);
    }
    w = maze[0].size();
    h = maze.size();
  }

  // part 1
  // return distinct cells visited, excepting the start node
  std::set<std::pair<int, int>> run() const {
    int dir = 0;
    int x = start_x, y = start_y;
    
    std::set<std::pair<int, int>> visited;
    for(;;) {
      visited.insert(std::make_pair(x, y));

      int nx = x + DX[dir];
      int ny = y + DY[dir];
      if (nx < 0 || nx >= w || ny < 0 || ny >= h) {
        visited.erase(std::make_pair(start_x, start_y));
        return visited;
      }

      if (maze[ny][nx] == '#') {
        dir = (dir + 1) & 3;
      } else {
        x = nx;
        y = ny;
      }
    }
  }

  // part 2
  // insert timey-wimey obstacle and detect cycles
  // return true if looped
  bool run(int ox, int oy) const {
    int dir = 0;
    int x = start_x, y = start_y;

    std::set<int> visited;
    while(visited.insert((dir << 24) | (y << 12) | x).second) {
      int nx = x + DX[dir];
      int ny = y + DY[dir];
      if (nx < 0 || nx >= w || ny < 0 || ny >= h)
        return false;

      if ((nx == ox && ny == oy) || maze[ny][nx] == '#') {
        dir = (dir + 1) & 3;
      } else {
        x = nx;
        y = ny;
      }
    }

    return true;
  }
};

int main(int argc, char **argv) {
  if (argc < 2) {
    std::cerr << "usage: " << argv[0] << " input-file" << std::endl;
    return 1;
  }

  std::ifstream file(argv[1]);
  Maze maze(file);
  
  auto path = maze.run();
  std::cout << path.size() + 1 << std::endl;

  int n = 0;
  for(auto coord : path) {
    if (maze.run(coord.first, coord.second))
      ++n;
  }
  std::cout << n << std::endl;
  
  return 0;
}
