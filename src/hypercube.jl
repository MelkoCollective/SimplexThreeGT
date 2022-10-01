struct Hypercube{N}
    dims::Dims{N}
    strides::Dims{N}
    ncubes::Int
    coords::Vector{CartesianIndex{N}} # label => coords
end

Hypercube(dims::Int...) = Hypercube(dims)

function Hypercube(dims::Dims{N}) where N
    strides = Base.size_to_strides(1, dims...)
    ncubes = prod(dims)
    cartesian = CartesianIndices(map(k->1:k, dims))
    coords = map(1:ncubes) do id
        cartesian[id]
    end
    return Hypercube{N}(dims, strides, ncubes, coords)
end

Base.ndims(::Hypercube{N}) where N = N
Base.size(l::Hypercube) = l.dims
Base.size(l::Hypercube, k::Int) = l.dims[k]
Base.length(l::Hypercube) = l.ncubes

# return the label of each cube
function Base.getindex(cube::Hypercube{N}, inds::Vararg{Int, N}) where N
    return mapreduce((i,s)->(i-1)*s, +, inds, cube.strides)+1
end

function Base.getindex(cube::Hypercube{N}, inds::CartesianIndex{N}) where N
    return cube[inds.I...]
end

function Base.show(io::IO, cube::Hypercube)
    print(io, "Hypercube(")
    join(io, cube.dims, ", ")
    print(io, ")")
end

struct CubicFaceSites{N}
    hypercube::Hypercube{N}
    labels::Matrix{Int}
    inverse::Matrix{Int}
end

function CubicFaceSites(dims::Int...)
    hypercube = Hypercube(dims)
    labels = cube_labels(hypercube)
    inverse = site_label_to_cube(hypercube, labels)
    return CubicFaceSites(hypercube, labels, inverse)
end


ncubes(cfs::CubicFaceSites) = ncubes(cfs.hypercube)
ncubes(hypercube::Hypercube) = hypercube.ncubes

nspins(cfs::CubicFaceSites) = nspins(cfs.hypercube)
function nspins(hypercube::Hypercube)
    return ncubes(hypercube) * ndims(hypercube)
end

function Base.show(io::IO, ::MIME"text/plain", x::CubicFaceSites)
    print(io, "CubicFaceSites(")
    join(io, size(x.hypercube), ", ")
    print(io, ")")
end

function cube_labels(l::Hypercube)
    labels = Array{Int}(undef, l.ncubes, 2 * ndims(l))
    # labels = fill(-1, l.ncubes, 2 * ndims(l))

    site_count = 1
    for k in 1:ndims(l)
        fix_dims(size(l), k) do prev, rest
            for idx in 1:size(l, k)
                cube_idx = l[prev..., idx, rest...]
                labels[cube_idx, k] = site_count

                if idx != size(l, k)
                    labels[cube_idx, k+ndims(l)] = site_count+1
                else
                    first_cube_idx = l[prev..., 1, rest...]
                    labels[cube_idx, k+ndims(l)] = labels[first_cube_idx, k]
                end
                site_count += 1
            end
        end
    end
    return labels
end

function site_label_to_cube(l::Hypercube, labels::Matrix{Int})
    inverse = zeros(Int, ndims(l) * l.ncubes, 2)
    for (face_idx, row) in enumerate(eachrow(labels))
        for site in row
            if iszero(inverse[site, 1])
                inverse[site, 1] = face_idx
            elseif iszero(inverse[site, 2])
                inverse[site, 2] = face_idx
            else
                error("invalid site label matrix")
            end
        end
    end
    return inverse
end

function fix_dims(f, dims::Dims, k::Int)
    if k == 1
        for rest in Iterators.product(map(d->1:d, dims[2:end])...)
            f((), rest)
        end
    else
        prev = Iterators.product(map(d->1:d, dims[1:k-1])...)
        rest = Iterators.product(map(d->1:d, dims[k+1:end])...)
        for (prev_coords, rest_coords) in Iterators.product(prev, rest)
            f(prev_coords, rest_coords)
        end
    end
    return
end
