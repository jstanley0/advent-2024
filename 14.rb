w, h = ARGV.map(&:to_i)

Robot = Struct.new(:x, :y, :dx, :dy)
robots = $stdin.readlines.map { Robot.new(*_1.scan(/-?\d+/).map(&:to_i)) }

100.times do
  robots.each do |robot|
    robot.x += robot.dx
    robot.y += robot.dy
    robot.x += w while robot.x < 0
    robot.x -= w while robot.x >= w
    robot.y += h while robot.y < 0
    robot.y -= h while robot.y >= h
  end
end

mx = w / 2
my = h / 2
quadrants = [0] * 4
robots.each do |robot|
  quadrants[0] += 1 if robot.x < mx && robot.y < my
  quadrants[1] += 1 if robot.x > mx && robot.y < my
  quadrants[2] += 1 if robot.x < mx && robot.y > my
  quadrants[3] += 1 if robot.x > mx && robot.y > my
end

puts quadrants.inject(:*)
