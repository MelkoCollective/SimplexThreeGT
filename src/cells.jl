function insert_2_dims(coords, (d1, d2), (i, j))
    return (coords[1:d1-1]..., i, coords[d1:d2-2]..., j, coords[d2-1:end]...)
end

function insert_3_dims(coords, (d1, d2, d3), (i, j, k))
    return (coords[1:d1-1]..., i,
        coords[d1:d2-2]..., j,
        coords[d2-1:d3-3]..., k,
        coords[d3-2:end]...)
end
# d1 < d2
faces((d1, d2)::Tuple{Int, Int}, L::Int) = faces((), (d1, d2), L)
cubes((d1, d2, d3)::Tuple{Int, Int, Int}, L) = cubes((), (d1, d2, d3), L)

function faces(coords::NTuple{N, Int}, (d1, d2)::Tuple{Int, Int}, L::Int) where {N}
    faces = Set(Set{NTuple{N+2, Int}}[])
    for i in 0:L-1, j in 0:L-1
        x1 = insert_2_dims(coords, (d1, d2), (i, j))
        x2 = insert_2_dims(coords, (d1, d2), (i, mod(j+1, L)))
        x3 = insert_2_dims(coords, (d1, d2), (mod(i+1, L), j))
        x4 = insert_2_dims(coords, (d1, d2), (mod(i+1, L), mod(j+1, L)))
        push!(faces, Set((x1, x2, x3, x4)))
    end
    return faces
end

function cubes(coords::NTuple{N, Int}, (d1, d2, d3)::NTuple{3, Int}, L::Int) where {N}
    cubes = Set(Set{NTuple{N+3, Int}}[])
    for i in 0:L-1, j in 0:L-1, k in 0:L-1
        x1 = insert_3_dims(coords, (d1, d2, d3), (i, j, k))
        x2 = insert_3_dims(coords, (d1, d2, d3), (i, j, mod(k+1, L)))
        x3 = insert_3_dims(coords, (d1, d2, d3), (i, mod(j+1, L), k))
        x4 = insert_3_dims(coords, (d1, d2, d3), (i, mod(j+1, L), mod(k+1, L)))
        x5 = insert_3_dims(coords, (d1, d2, d3), (mod(i+1, L), j, k))
        x6 = insert_3_dims(coords, (d1, d2, d3), (mod(i+1, L), j, mod(k+1, L)))
        x7 = insert_3_dims(coords, (d1, d2, d3), (mod(i+1, L), mod(j+1, L), k))
        x8 = insert_3_dims(coords, (d1, d2, d3), (mod(i+1, L), mod(j+1, L), mod(k+1, L)))
        push!(cubes, Set((x1, x2, x3, x4, x5, x6, x7, x8)))
    end
    return cubes
end

function faces(n::Int, L::Int)
    ret = Set(Set{NTuple{n, Int}}[])
    @progress name="generating faces" for coords in Iterators.product(ntuple(_->0:L-1, n-2)...)
        for dims in combinations(1:n, 2)
            d1,d2 = dims
            for each in faces(coords, (d1,d2), L)
                push!(ret, each)
            end
        end
    end
    return ret
end

function cubes(n::Int, L::Int)
    ret = Set(Set{NTuple{n, Int}}[])
    @progress name="generating cubes" for coords in Iterators.product(ntuple(_->0:L-1, n-3)...)
        for dims in combinations(1:n, 3)
            d1,d2,d3 = dims
            for each in cubes(coords, (d1,d2,d3), L)
                push!(ret, each)
            end
        end
    end
    return ret
end

function cube_labels(cubes::Set{Set{NTuple{N, Int}}}) where {N}
    ret = Dict{Set{NTuple{N, Int}}, Int}()
    for (i, cube) in enumerate(cubes)
        ret[cube] = i
    end
    return ret
end

function spin_labels(faces::Set{Set{NTuple{N, Int}}}) where N
    ret = Dict{Set{NTuple{N, Int}}, Int}()
    for (i, face) in enumerate(faces)
        ret[face] = i
    end
    return ret
end

function spin_cube_map(spin_labels, cube_labels, faces, cubes)
    spin_to_cube = Dict{Int, Set{Int}}()
    cube_to_spin = Dict{Int, Set{Int}}()

    for f in faces
        neighbors = filter(cubes) do cube
            all(x->x in cube, f)
        end
        spin_to_cube[spin_labels[f]] = Set([cube_labels[c] for c in neighbors])

        for cube in neighbors
            cube_spins = get!(cube_to_spin, cube_labels[cube]) do
                Set(Int[])
            end
            push!(cube_spins, spin_labels[f])
        end
    end
    return spin_to_cube, cube_to_spin
end

function spin_cube_map(n::Int, L::Int)
    f = faces(n, L)
    c = cubes(n, L)
    spin_to_cube, cube_to_spin = spin_cube_map(spin_labels(f), cube_labels(c), f, c)
    return spin_to_cube, cube_to_spin
end

struct CubicSpinMap
    spin_to_cube::Dict{Int, Set{Int}}
    cube_to_spin::Dict{Int, Set{Int}}
end

CubicSpinMap(n::Int, L::Int) = CubicSpinMap(spin_cube_map(n, L)...)
nspins(csp::CubicSpinMap) = length(csp.spin_to_cube)
