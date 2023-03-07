using Test
using SimplexThreeGT
using Combinatorics
using SimplexThreeGT.Homology: cell_topology, insert_dims

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
