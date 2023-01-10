using Random
using SimplexThreeGT
using SimplexThreeGT: energy, local_energy, face_cube_map, CellMap, cell_points

rng = MersenneTwister(1334);

Dim = 3
L = 2

# cells(3, 3, 2)

# julia> Cube = Cube_Label_3D(Dim,L)  #One entry for every dimension
# 8×6 Matrix{Int64}:
#   1   2   3   4   8  15
#   4   5   6   1  11  18
#   7   8   9  10   2  21
#  10  11  12   7   5  24
#  13  14  15  16  20   3
#  16  17  18  13  23   6
#  19  20  21  22  14   9
#  22  23  24  19  17  12
cube = [1 2 3 4 8 15; 4 5 6 1 11 18; 7 8 9 10 2 21; 10 11 12 7 5 24; 13 14 15 16 20 3; 16 17 18 13 23 6; 19 20 21 22 14 9; 22 23 24 19 17 12]
csm = face_cube_map(Dim,L)

function remap_spin(csm, cube::Matrix)
    new_map = Dict{Int, Int}()
    for (shape, attach) in csm.shape_attach
        for (new, old) in zip(cube[shape, :], attach)
            if haskey(new_map, old)
                @show (shape, old, new)
                new_map[old] == new || error("Inconsistent remapping")
            end
            new_map[old] = new
        end
    end
    return new_map
end

remap_spin(csm, Cube)

function remap(csm, cube::Matrix)
    new_map = Dict{Int, Int}()
    for (row, (shape, attach)) in zip(eachrow(cube), csm.shape_attach)
        for (new, old) in zip(row, shape)
            if haskey(new_map, old)
                @show new_map[old], new
                new_map[old] == new || error("Inconsistent remapping")
            end
            new_map[old] = new
        end
    end

    new_shape_attach = Dict{Int, Vector{Int}}()
    for (shape, attach) in csm.shape_attach
        new_shape_attach[shape] = map(attach) do old
            haskey(new_map, old) && return new_map[old]
            return old
        end
    end

    new_attach_shape = Dict{Int, Vector{Int}}()
    for (shape, attach) in new_shape_attach
        for spin in attach
            push!(get!(new_attach_shape, spin, Int[]), shape)
        end
    end
    return CellMap(csm.ndims, csm.L, csm.p, new_shape_attach, new_attach_shape)
end

remap(csm, Cube).shape_attach
remap(csm, Cube).attach_shape

csm.shape_attach

spins = -ones(Int, nspins(csm))
# spins[1] = 1
# spins[10] = 1
# spins[11] = 1

sum(spins)
energy(csm, spins)

sum(values(csm.shape_attach)) do cube_spins
    local_energy(cube_spins, spins)
end
