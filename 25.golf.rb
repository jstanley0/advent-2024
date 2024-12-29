l,k=$<.read.split("\n\n").map{_1.split.map(&:chars).transpose}.partition{_1[0][0]==?#}
p l.product(k).count{|l,k|l.zip(k).all?{(_1+_2).count(?#)<8}}
