set = rs.conf()

set.members[0].priority = 1
set.members[1].priority = 0.5
set.members[2].priority = 0.5
set.members[3].priority = 0

rs.reconfig(set)
