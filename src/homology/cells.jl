const Point{N} = NTuple{N, Int}

function moveby(base::Vector{NTuple{D, T}}, by::NTuple{D, T}, L::Int) where {D, T}
    return map(base) do point
        mod.(point .+ by, L)
    end
end

function insert_dims(coords::Tuple, dims, indices)
    ret = coords
    for (d, i) in zip(dims, indices)
        ret = (ret[1:d-1]..., i, ret[d:end]...)
    end
    return ret
end

function cell_points(coords::NTuple{N, T}, dims, L::Int, base::Vector{NTuple{D, T}}) where {N, D, T}
    @assert length(dims) == D "length(dims) must be equal to $D"
    cells = Vector{NTuple{N+D, T}}[]
    for vec in Iterators.product(ntuple(_->0:L-1, D)...)
        cell = map(moveby(base, vec, L)) do point
            insert_dims(coords, dims, point)
        end
        push!(cells, cell)
    end
    return cells
end

function cell_points(ndims::Int, p::Int, L::Int)
    ndims ≥ p || error("ndims must be greater than or equal to p")
    base = vec(collect(Iterators.product(ntuple(_->0:1, p)...)))
    ret = Vector{Point{ndims}}[]
    for dims in combinations(1:ndims, p)
        for coords in Iterators.product(ntuple(_->0:L-1, ndims-p)...)
            append!(ret, cell_points(coords, dims, L, base))
        end
    end
    return ret
end

struct Topology
    sets::Vector{Vector{Vector{Int}}}
end

"""
    cell_topology(p::Int)

Returns the topology sets of p-cell given arbitrary
points.
"""
function cell_topology(p::Int)
    points = vec(collect(Iterators.product(ntuple(_->0:1, p)...)))    
    point_indices = Dict{Point{p}, Int}()
    for (i, point) in enumerate(points)
        point_indices[point] = i
    end

    sets = map(0:p) do i
        map(basic_cell_points(p, i)) do shape
            map(shape) do point
                point_indices[point]
            end
        end
    end
    return Topology(sets)
end

function basic_cell_points(ndims::Int, p::Int)
    base = vec(collect(Iterators.product(ntuple(_->0:1, p)...)))
    ret = Vector{Point{ndims}}[]
    for dims in combinations(1:ndims, p)
        for coord in Iterators.product(ntuple(_->0:1, ndims-p)...)
            elem = map(base) do point
                insert_dims(coord, dims, point)
            end
            push!(ret, elem)
        end
    end
    return ret
end
