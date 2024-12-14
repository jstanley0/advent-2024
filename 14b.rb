require_relative "skim"

W = 101
H = 103

Robot = Struct.new(:x, :y, :dx, :dy)
robots = ARGF.readlines.map { Robot.new(*_1.scan(/-?\d+/).map(&:to_i)) }

n = 0
loop do
  robots.each do |robot|
    robot.x += robot.dx
    robot.y += robot.dy
    robot.x += W while robot.x < 0
    robot.x -= W while robot.x >= W
    robot.y += H while robot.y < 0
    robot.y -= H while robot.y >= H
  end
  n += 1

  pic = Skim.new(W, H, ' ')
  robots.each do |robot|
    pic[robot.x, robot.y] = '*'
  end
  if pic.data.any? { _1.join.include?("********") }
    puts n
    pic.print
    break
  end
end
