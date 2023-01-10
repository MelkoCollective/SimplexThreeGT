struct CellMap
    ndims::Int
    L::Int
    p::Pair{Int, Int}

    shape_attach::Dict{Int, Vector{Int}}
    attach_shape::Dict{Int, Vector{Int}}
end

function CellMap(
        ndims::Int, p::Pair{Int, Int}, L::Int,
        topo::Topology = cell_topology(p.second)
    )

    p_attach, p_shape = p
    shapes = cell_points(ndims, p_shape, L)
    shape_labels = Dict{Vector{Point{ndims}}, Int}()
    for (i, shape) in enumerate(shapes)
        shape_labels[shape] = i
    end

    attach_id_count = 0
    attach_set = topo.sets[p_attach+1]
    shape_attach_map = Dict{Int, Vector{Int}}()
    attach_shape_map = Dict{Int, Vector{Int}}()
    attach_labels = Dict{Vector{Point{ndims}}, Int}()

    @withprogress name="generate cell map" begin
        for shape in shapes
            shape_id = shape_labels[shape]
            for attach in attach_set
                attach_points = shape[attach]
                if haskey(attach_labels, attach_points)
                    attach_id = attach_labels[attach_points]
                else
                    attach_id_count += 1
                    attach_id = attach_labels[attach_points] = attach_id_count
                end
                push!(get!(shape_attach_map, shape_id, Int[]), attach_id)
                push!(get!(attach_shape_map, attach_id, Int[]), shape_id)
            end

            @logprogress 1/length(shapes)
        end
    end # withprogress
    return CellMap(ndims, L, p, shape_attach_map, attach_shape_map)
end

nspins(cm::CellMap) = length(cm.attach_shape)
face_cube_map(n::Int, L::Int) = CellMap(n, 2=>3, L)

function Base.show(io::IO, ::MIME"text/plain", cm::CellMap)
    println(io, "CellMap ", cm.p.first, " <-> ", cm.p.second, ":")
    println(io, "  ndims: ", cm.ndims)
    println(io, "  L: ", cm.L)
    println(io, "  $(cm.p.first)-cells: ", length(cm.attach_shape))
    print(io, "  $(cm.p.second)-cells: ", length(cm.shape_attach))
end
