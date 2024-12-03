puts ARGF.read.scan(/mul\((\d{1,3}),(\d{1,3})\)/).sum { _1.map(&:to_i).inject(:*) }
