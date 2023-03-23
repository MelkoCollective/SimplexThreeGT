struct CellMap
    ndims::Int
    L::Int
    p::Tuple{Int, Int}

    p1p2::Dict{Int, Set{Int}}
    p2p1::Dict{Int, Set{Int}}
end

function Base.show(io::IO, ::MIME"text/plain", cm::CellMap)
    indent = get(io, :indent, 0)
    print(xs...) = Base.print(io, " "^indent, xs...)
    println(xs...) = Base.println(io, " "^indent, xs...)
    Base.println(io, "CellMap ", cm.p[1], " <-> ", cm.p[2], ":")
    println("  ndims: ", cm.ndims)
    println("  L: ", cm.L)
    println("  $(cm.p[1])-cells: ", length(cm.p1p2))
    print("  $(cm.p[2])-cells: ", length(cm.p2p1))
end

function Base.:(==)(lhs::CellMap, rhs::CellMap)
    lhs.ndims == rhs.ndims && lhs.L == rhs.L && lhs.p == rhs.p || return false
    return lhs.p1p2 == rhs.p1p2 && lhs.p2p1 == rhs.p2p1
end

"""
    CellMap(ndims, L, (p1, p2))

Return a `CellMap` object that maps between `p1`-cells and `p2`-cells.
See also [`cell_map`](@ref).

### Arguments

- `ndims`: number of dimensions
- `L`: size of each dimension
- `p1`: dimension of the `p1`-cells
- `p2`: dimension of the `p2`-cells

### Fields

- `ndims`: number of dimensions
- `L`: size of each dimension
- `p`: tuple of the dimensions of the `p1`- and `p2`-cells
- `p1p2`: dictionary mapping `p1`-cell indices to sets of `p2`-cell indices
- `p2p1`: dictionary mapping `p2`-cell indices to sets of `p1`-cell indices
"""
function CellMap(
        ndims::Int, L::Int, (p1, p2)::Tuple{Int, Int},
    )

    topo = cell_topology(p2)
    p1_labels = Dict{Vector{Point{ndims}}, Int}()
    p2_labels = Dict{Vector{Point{ndims}}, Int}()
    p1_points = cell_points(ndims, p1, L)
    p2_points = cell_points(ndims, p2, L)

    for (p1_id, p1_cell) in enumerate(p1_points)
        p1_labels[p1_cell] = p1_id
    end

    for (p2_id, p2_cell) in enumerate(p2_points)
        p2_labels[p2_cell] = p2_id
    end

    p1p2 = Dict{Int, Set{Int}}()
    p2p1 = Dict{Int, Set{Int}}()
    @withprogress name="generate cell map" begin
        for p2_cell in p2_points
            p2_id = p2_labels[p2_cell]
            for p1_topo in topo.sets[p1+1]
                p1_cell = p2_cell[p1_topo]
                p1_id = p1_labels[p1_cell]
                push!(get!(Set{Int}, p1p2, p1_id), p2_id)
                push!(get!(Set{Int}, p2p1, p2_id), p1_id)
            end
            @logprogress 1/length(p2_points)
        end
    end # withprogress
    return CellMap(ndims, L, (p1, p2), p1p2, p2p1)
end

nspins(cm::CellMap) = length(cm.p1p2)
face_cube_map(n::Int, L::Int) = cell_map(n, L, (2, 3))

"""
    cell_map(shape::ShapeInfo, (p1, p2))

Return a `CellMap` object that maps between `p1`-cells and `p2`-cells.
Serialize the result to a file in the cache directory if it does not
already exist. See also [`CellMap`](@ref).

### Arguments

- `shape`: a `ShapeInfo` object
- `p1`: dimension of the `p1`-cells
- `p2`: dimension of the `p2`-cells
"""
function cell_map(storage::StorageInfo, shape::ShapeInfo, p::Tuple{Int, Int})
    name = name(shape) * "-$(p[1])-$(p[2])"
    cache = topo_dir(storage, name * ".jls")
    isfile(cache) && return deserialize(cache)
    with_log(storage, name) do
        cm = CellMap(shape.ndims, shape.size, p)
        @debug "serializing cm to $cache"
        serialize(cache, cm)
        return cm
    end
end

function cell_map(storage::StorageInfo, job::CellMapOption)
    cell_map(storage, job.shape, (job.shape.p-1, job.shape.p))
end

function gauge_map(storage::StorageInfo, job::CellMapOption)
    job.gauge || return nothing
    return cell_map(storage, job.shape, (job.shape.p-2, job.shape.p-1))
end
