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
    if n > 3
        @progress name="generating cubes" for coords in Iterators.product(ntuple(_->0:L-1, n-3)...)
            for dims in combinations(1:n, 3)
                d1,d2,d3 = dims
                for each in cubes(coords, (d1,d2,d3), L)
                    push!(ret, each)
                end
            end
        end
    else
        for dims in combinations(1:n, 3)
            d1,d2,d3 = dims
            for each in cubes((), (d1,d2,d3), L)
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

function face_labels(faces::Set{Set{NTuple{N, Int}}}) where N
    ret = Dict{Set{NTuple{N, Int}}, Int}()
    for (i, face) in enumerate(faces)
        ret[face] = i
    end
    return ret
end

function thread_partition(nfaces::Int, nthreads::Int)
    d, r = divrem(nfaces, nthreads)
    sizes = map(1:nthreads) do idx
        idx ≤ r && return d+1
        return d
    end
    prev = 0; ranges = UnitRange{Int}[]
    for each in cumsum(sizes)
        push!(ranges, prev+1:each)
        prev = each
    end
    return ranges
end

#TODO: replace this with kd-tree
function spin_cube_map(face_labels, cube_labels, faces, cubes, nthreads::Int)
    threaded_spin_to_cube = [Dict{Int, Set{Int}}() for _ in 1:nthreads]
    threaded_cube_to_spin = [Dict{Int, Set{Int}}() for _ in 1:nthreads]
    faces = collect(faces); cubes = collect(cubes) # convert Set to Vector
    progress_counter = Threads.Atomic{Int}(0)
    @withprogress name="spin_cube_map" begin
        @sync begin
            Threads.@spawn begin
                while progress_counter[] < length(faces)
                    @logprogress progress_counter[]/length(faces)
                    sleep(0.1)
                end
            end
            for (thread_idx, range) in enumerate(thread_partition(length(faces), nthreads))
                Threads.@spawn let spin_to_cube = threaded_spin_to_cube[thread_idx],
                        cube_to_spin = threaded_cube_to_spin[thread_idx]

                    for f_idx in range
                        f = faces[f_idx]
                        Threads.atomic_add!(progress_counter, 1)
                        neighbors = filter(cubes) do cube
                            all(x->x in cube, f)
                        end
                        spin_to_cube[face_labels[f]] = Set([cube_labels[c] for c in neighbors])
                
                        for cube in neighbors
                            cube_spins = get!(cube_to_spin, cube_labels[cube]) do
                                Set(Int[])
                            end
                            push!(cube_spins, face_labels[f])
                        end
                    end
                end
            end
        end
    end

    spin_to_cube = Dict{Int, Set{Int}}()
    cube_to_spin = Dict{Int, Set{Int}}()
    for spin_to_cube_thread in threaded_spin_to_cube
        for (k, v) in spin_to_cube_thread
            spin_cubes = spin_to_cube[k] = get!(spin_to_cube, k) do
                Set(Int[])
            end
            union!(spin_cubes, v)
        end
    end

    for cube_to_spin_thread in threaded_cube_to_spin
        for (cube, spins) in cube_to_spin_thread
            cube_spins = cube_to_spin[cube] = get!(cube_to_spin, cube) do
                Set(Int[])
            end
            union!(cube_spins, spins)
        end
    end
    return spin_to_cube, cube_to_spin
end

function spin_cube_map_old(face_labels, cube_labels, faces, cubes, _::Int)
    spin_to_cube = Dict{Int, Set{Int}}()
    cube_to_spin = Dict{Int, Set{Int}}()

    @withprogress name="spin_cube_map" for (f_idx, f) in enumerate(faces)
        @logprogress f_idx/length(faces)
        neighbors = filter(cubes) do cube
            all(x->x in cube, f)
        end
        spin_to_cube[face_labels[f]] = Set([cube_labels[c] for c in neighbors])

        for cube in neighbors
            cube_spins = get!(cube_to_spin, cube_labels[cube]) do
                Set(Int[])
            end
            push!(cube_spins, face_labels[f])
        end
    end
    return spin_to_cube, cube_to_spin
end

function spin_cube_map(n::Int, L::Int, nthreads::Int)
    f = faces(n, L)
    c = cubes(n, L)
    spin_to_cube, cube_to_spin = spin_cube_map(
        face_labels(f), cube_labels(c), f, c, nthreads)
    return spin_to_cube, cube_to_spin
end

struct CubicSpinMap
    ndims::Int
    L::Int
    spin_to_cube::Vector{Set{Int}}
    cube_to_spin::Vector{Set{Int}}
end

CubicSpinMap(shape::ShapeInfo; kw...) = CubicSpinMap(shape.ndims, shape.size; kw...)

function CubicSpinMap(n::Int, L::Int; nthreads::Int=Threads.nthreads())
    spin_to_cube, cube_to_spin = spin_cube_map(n, L, nthreads)
    spin_to_cube_vec = Vector{Set{Int}}(undef, length(spin_to_cube))
    cube_to_spin_vec = Vector{Set{Int}}(undef, length(cube_to_spin))
    for (k, v) in spin_to_cube
        spin_to_cube_vec[k] = v
    end
    for (k, v) in cube_to_spin
        cube_to_spin_vec[k] = v
    end
    return CubicSpinMap(n, L, spin_to_cube_vec, cube_to_spin_vec)
end

nspins(csp::CubicSpinMap) = length(csp.spin_to_cube)

function Base.show(io::IO, ::MIME"text/plain", csm::CubicSpinMap)
    indent = get(io, :indent, 0)
    tab(n=0) = " "^(indent+n)
    print(xs...) = Base.print(io, tab(), xs...)
    println(xs...) = Base.println(io, tab(), xs...)

    println("CubicSpinMap with:")
    println("  ndims: ", csm.ndims)
    println("  L: ", csm.L)
    println("  spin_to_cube: ", length(csm.spin_to_cube), " spins")
    print(  "  cube_to_spin: ", length(csm.cube_to_spin), " cubes")
end

function obtain_csm(shape::ShapeInfo)
    csm_cache = shape_file(shape)
    isfile(csm_cache) && return deserialize(csm_cache)
    with_task_log(task, "csm-$(shape_name(shape))") do
        csm = CubicSpinMap(shape)
        serialize(csm_cache, csm)
        return csm
    end
end
