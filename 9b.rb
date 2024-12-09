require 'byebug'

disk_map = ARGF.read.strip.chars.map(&:to_i).each_slice(2).to_a

Extent = Struct.new(:pos, :size, :file_id, :prev, :next)

class ExtentList
  attr_accessor :file_index

  def initialize
    self.file_index = {}

    @placeholder = Extent.new(-1, -1, -1)
    @front = @back = @placeholder
  end

  def front
    @placeholder.next
  end

  def append(extent)
    @back.next = extent
    extent.prev = @back
    @back = extent

    file_index[extent.file_id] = extent if extent.file_id
    extent
  end

  def free(extent)
    raise "extent already free" if extent.file_id.nil?

    file_index.delete(extent.file_id)
    extent.file_id = nil

    # consolidate right
    if extent.next && extent.next.file_id.nil?
      extent.size += extent.next.size
      extent.next = extent.next.next
      extent.next.prev = extent if extent.next
    end

    # consolidate left
    if extent.prev.file_id.nil?
      extent.prev.size += extent.size
      extent.prev.next = extent.next
      extent = extent.prev
      extent.next.prev = extent if extent.next
    end

    extent
  end

  def allocate(extent, file_size, file_id)
    raise "extent in use" unless extent.file_id.nil?
    raise "extent too small" if extent.size < file_size

    new_extent = if extent.size == file_size
      # easy case, file exactly fits; repurpose the free extent
      extent.file_id = file_id
      extent
    else
      # insert the file, shrinking and pushing the free extent back
      file = Extent.new(extent.pos, file_size, file_id, extent.prev, extent)
      extent.prev.next = file
      extent.prev = file
      extent.pos += file_size
      extent.size -= file_size
      file
    end

    file_index[file_id] = new_extent
  end

  def print
    extent = front
    while extent
      Kernel.print (extent.file_id&.to_s || ".") * extent.size
      extent = extent.next
    end
    puts
  end

  def checksum
    sum = 0
    extent = front
    while extent
      sum += extent.file_id * extent.size * (2 * extent.pos + extent.size - 1) / 2 if extent.file_id
      extent = extent.next
    end
    sum
  end
end

file_id = 0
pos = 0
disk = ExtentList.new
disk_map.each do |data, slack|
  raise "empty extent!" unless data > 0
  disk.append(Extent.new(pos, data, file_id))
  file_id += 1
  pos += data

  if slack.to_i > 0
    disk.append(Extent.new(pos, slack, nil))
    pos += slack
  end
end
file_id -= 1

min = {}
while file_id > 0
  file = disk.file_index[file_id]
  raise "can't find file #{file_id}" unless file

  # find an empty extent big enough to contain the file
  space = min[file.size] || disk.front
  until space.nil? || space.pos >= file.pos || space.file_id.nil? && space.size >= file.size
    space = space.next
  end

  if space && space.file_id.nil?
    size = file.size
    disk.free(file)
    min[size] = disk.allocate(space, size, file_id)
  end
  # disk.print

  file_id -= 1
end

puts disk.checksum
