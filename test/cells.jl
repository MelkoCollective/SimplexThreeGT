using Test
using SimplexThreeGT
using Combinatorics
using SimplexThreeGT: Cell

Cell(3)

@testset "insert_dims(_, ::Dims{2}, _)" begin
    for dims in combinations(1:5, 2)
        coords = insert_dims((1,2,3), (dims...,), (:a,:b))
        @test coords[dims] == (:a,:b)
    end
end

@testset "insert_dims(_, ::Dims{3}, _)" begin
    for dims in combinations(1:6, 3)
        coords = insert_dims((1,2,3), (dims...,), (:a,:b,:c))
        @test coords[dims] == (:a,:b,:c)
    end
end


function naive_cubes_3d(L::Int)
    ret = Set(Set{NTuple{3, Int}}[])
    for x in 0:L-1, y in 0:L-1, z in 0:L-1
        cube = Set{NTuple{3, Int}}()
        for dx in 0:1, dy in 0:1, dz in 0:1
            push!(cube, (mod(x+dx, L), mod(y+dy, L), mod(z+dz, L)))
        end
        push!(ret, cube)
    end
    return ret
end

function naive_faces_2d(L::Int)
    ret = Set(Set{NTuple{2, Int}}[])
    for x in 0:L-1, y in 0:L-1
        face = Set{NTuple{2, Int}}()
        for dx in 0:1, dy in 0:1
            push!(face, (mod(x+dx, L), mod(y+dy, L)))
        end
        push!(ret, face)
    end
    return ret
end

@testset "p-cell L=$L" for L in 2:4
    @test cells(2, 2, L) == naive_faces_2d(L)
    @test cells(3, 3, L) == naive_cubes_3d(L)
end

c = Cell(3)
c = embed(c, (1, 2), (2, 2))
moveby(c, (1, 1, 1), 3)

fcm = face_cube_map(3, 2)

fs = cells(3, 2, 2)
cs = cells(3, 3, 2)

findall(cs) do c
    issubset(fs[1].points, c.points)
end
fs[1].points
cs[1].points

fcm.parent_child[8]

moveby(fs[1], (0, 0, 2), 2)
