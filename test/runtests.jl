using Test
using SimplexThreeGT

@testset "checkpoint" begin
    include("checkpoint.jl")
end

@testset "cell" begin
    include("cells.jl")
    include("cellmap.jl")
end

@testset "mc" begin
    include("mc.jl")
end
