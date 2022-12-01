using Test
using SimplexThreeGT


l = Hypercube(2, 3, 4)
A = reshape(collect(1:24), (2, 3, 4))

for i in 1:24
    coord = l.coords[i]
    @test A[coord] == i
    @test l[coord] == A[coord]
end

using SimplexThreeGT: Hypercube, CubicFaceSites, fix_dims, cube_labels, site_label_to_cube
l = Hypercube(2, 3, 4, 5)
cube_labels(l)
site_label_to_cube(l, cube_labels(l))

CubicFaceSites(2, 3, 4)