struct CellMap
    ndims::Int
    L::Int
    p::Tuple{Int, Int}

    p1p2::Dict{Int, Vector{Int}}
    p2p1::Dict{Int, Vector{Int}}
end

function Base.show(io::IO, ::MIME"text/plain", cm::CellMap)
    println(io, "CellMap ", cm.p[1], " <-> ", cm.p[2], ":")
    println(io, "  ndims: ", cm.ndims)
    println(io, "  L: ", cm.L)
    println(io, "  $(cm.p[1])-cells: ", length(cm.p2p1))
    print(io,   "  $(cm.p[2])-cells: ", length(cm.p1p2))
end

function CellMap(
        ndims::Int, L::Int, (p1, p2)::Tuple{Int, Int},
    )

    topo = cell_topology(p2)
    p1p2 = Dict{Int, Vector{Int}}()
    p2p1 = Dict{Int, Vector{Int}}()
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

    p1p2 = Dict{Int, Vector{Int}}()
    p2p1 = Dict{Int, Vector{Int}}()
    @withprogress name="generate cell map" begin
        for p2_cell in p2_points
            p2_id = p2_labels[p2_cell]
            for p1_topo in topo.sets[p1+1]
                p1_cell = p2_cell[p1_topo]
                p1_id = p1_labels[p1_cell]
                push!(get!(p1p2, p1_id, Int[]), p2_id)
                push!(get!(p2p1, p2_id, Int[]), p1_id)
            end
            @logprogress 1/length(p2_points)
        end
    end # withprogress
    return CellMap(ndims, L, (p1, p2), p1p2, p2p1)
end

nspins(cm::CellMap) = length(cm.p1p2)
face_cube_map(n::Int, L::Int) = CellMap(n, 2=>3, L)
