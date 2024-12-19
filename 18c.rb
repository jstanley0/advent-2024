require "byebug"
require "curses"
require_relative "search"

START = 1024
STEP = 4

class Memory
  attr_accessor :w, :h, :drops, :obstacles

  def initialize
    rows = ARGF.readlines
    self.w, self.h, _ = rows.shift.split.map(&:to_i)
    self.drops = rows.map.with_index { |row, i| [i, row.split(?,).map(&:to_i)] }.to_h
    self.obstacles = drops.invert
  end

  def obstacle?(x, y, t)
    o = obstacles[[x, y]]
    return false unless o

    o < t
  end
end

class SearchNode < Search::Node
  attr_accessor :memory, :x, :y, :t

  def initialize(memory, x, y, t)
    self.memory = memory
    self.x = x
    self.y = y
    self.t = t
  end

  def to_s
    "#{x},#{y},#{t}"
  end

  def hash
    to_s.hash
  end

  def enum_edges
    return if t > memory.drops.size

    yield 1, SearchNode.new(memory, x - 1, y, t + STEP) unless x == 0 || memory.obstacle?(x - 1, y, t + STEP)
    yield 1, SearchNode.new(memory, x + 1, y, t + STEP) unless x == memory.w || memory.obstacle?(x + 1, y, t + STEP)
    yield 1, SearchNode.new(memory, x, y - 1, t + STEP) unless y == 0 || memory.obstacle?(x, y - 1, t + STEP)
    yield 1, SearchNode.new(memory, x, y + 1, t + STEP) unless y == memory.h || memory.obstacle?(x, y + 1, t + STEP)
  end

  def goal?
    x == memory.w && y == memory.h
  end
end

def plot_char(char, x, y, i)
  color = (char == '#') ? i : i + 8
  Curses.attron(Curses.color_pair(color)) do
    Curses.setpos y + 1, x + 1
    Curses.addch char
  end
end

memory = Memory.new
cost, path = Search::bfs(SearchNode.new(memory, 0, 0, START))

begin
  Curses.init_screen
  Curses.curs_set 0
  Curses.start_color
  Curses.init_color(17, 0, 50, 30)
  8.times do |i|
    Curses.init_color(i + 1, 200 + 35 * i, 200 + 35 * i, 220 + 35 * i)
    Curses.init_pair(i, i + 1, 17)
    Curses.init_color(i + 9, 300 + 50 * i, 400 + 70 * i, 500 + 70 * i)
    Curses.init_pair(i + 8, i + 9, 17)
  end
  Curses.clear
  (memory.h+1).times do |row|
    Curses.attron(Curses.color_pair(1)) do
      Curses.setpos row + 1, 1
      Curses.addstr " " * (memory.w+1)
    end
  end
  START.times do |t|
    x, y = memory.drops[t]
    plot_char('#', x, y, 1)
  end
  plot_char('O', 0, 0, 7)
  Curses.refresh

  sleep 10

  plots = []
  (START..path.last.t).each do |t|
    x, y = memory.drops[t]
    plots << ['#', x, y, 7]

    if t > path.first.t
      plots << ['O', path.first.x, path.first.y, 7]
      path.shift
    end

    plots.each_index do |n|
      plot_char(*plots[n])
      plots[n][-1] -= 1
    end

    plots.reject! { |plot| plot.last == 0 }

    Curses.refresh
    sleep 0.01
  end
  plot_char('O', path.last.x, path.last.y, 7)

  Curses.refresh
  Curses.getch
ensure
  Curses.close_screen
end
