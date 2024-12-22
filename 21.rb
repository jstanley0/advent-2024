require_relative "skim"

DIRS = {
  '^' => [ 0,-1],
  '<' => [-1, 0],
  '>' => [ 1, 0],
  'v' => [ 0, 1]
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

def find_code_path(numpad, code)
  path = ""
  x, y = numpad.find_coords('A')

  code.each_char do |c|
    path_seg = find_path(numpad, x, y, c)
    path += path_seg + "A"
    x, y = apply_path(x, y, path_seg)
  end
  path
end

def count_dpad_segments(dpad, path_segs)
  next_segs = Hash.new(0)
  path_segs.each do |seg, count|
    x0, y0 = dpad.find_coords('A')
    syms = seg.chars
    until syms.empty?
      x, y = x0, y0
      part = ""
      loop do
        raise ":(" if syms.empty?
        ps = find_path(dpad, x, y, syms.shift)
        part += ps + "A"
        x, y = apply_path(x, y, ps)
        break if x == x0 && y == y0
      end
      next_segs[part] += count
    end
  end

  next_segs
end

numpad = Skim.from_concise_string("789/456/123/#0A")
dpad = Skim.from_concise_string("#^A/<v>")

codes = ARGF.readlines.map(&:strip)
sc = codes.sum do |code|
  puts code

  path = find_code_path(numpad, code)
  puts path
  path_segs = { path => 1 }
  path_size = nil
  25.times do |n|
    path_segs = count_dpad_segments(dpad, path_segs)
    path_size = path_segs.sum{|k, v| k.size * v}
    puts "#{n + 1}: #{path_size}"
  end

  complexity = path_size * code.to_i
  puts "#{path_size} * #{code.to_i} = #{complexity}\n\n"
  complexity
end

puts sc
