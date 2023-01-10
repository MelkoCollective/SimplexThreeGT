using Test
using SimplexThreeGT
using Combinatorics
using SimplexThreeGT: insert_dims, cell_points, Point, cell_topology

fs = cell_points(3, 3, 2)
topo = cell_topology(3)
[fs[2][topo[3][i]] for i in 1:6]


using SimplexThreeGT: CellMap

