require_relative "skim"

DIRS = {
  ?^ => [ 0,-1],
  ?< => [-1, 0],
  ?> => [ 1, 0],
  ?v => [ 0, 1]
}

def apply_path(x, y, path)
  path.each_char { |c| x += DIRS[c][0]; y += DIRS[c][1] }
  [x, y]
end

def vcomp(y0, y1)
  if y0 < y1
    'v' * (y1 - y0)
  else
    '^' * (y0 - y1)
  end
end

def hcomp(x0, x1)
  if x0 < x1
    '>' * (x1 - x0)
  else
    '<' * (x0 - x1)
  end
end

def find_path(keypad, x0, y0, to)
  x1, y1 = keypad.find_coords(to)
  if x0 == x1
    vcomp(y0, y1)
  elsif y0 == y1
    hcomp(x0, x1)
  else
    comps = [vcomp(y0, y1), hcomp(x0, x1)]
    comps.reverse! if x1 < x0
    comps.reverse! if keypad[*apply_path(x0, y0, comps.first)] == '#'
    comps.join
  end
end

def find_code_path(keypad, code)
  path = ""
  x, y = keypad.find_coords('A')

  code.each_char do |c|
    path_seg = find_path(keypad, x, y, c)
    path += path_seg + "A"
    x, y = apply_path(x, y, path_seg)
  end
  path
end

numpad = Skim.from_concise_string("789/456/123/#0A")
dpad = Skim.from_concise_string("#^A/<v>")

sc = 0
codes = ARGF.readlines.map(&:strip)
codes.each do |code|
  puts code

  path = find_code_path(numpad, code)
  puts path

  2.times do |n|
    path = find_code_path(dpad, path)
    puts "#{n}: #{path.size}"
  end

  complexity = path.size * code.to_i
  puts "#{path.size} * #{code.to_i} = #{complexity}\n\n"
  sc += complexity
end

puts sc
