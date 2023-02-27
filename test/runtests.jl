using Test

@testset "checkpoint" begin
    include("checkpoint.jl")
end

@testset "cell" begin
    include("homology/homology.jl")
end

@testset "mc" begin
    include("mc/mc.jl")
end
