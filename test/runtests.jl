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

@testset "postprocess" begin
    include("postprocess/crunch.jl")
end

@testset "misc" begin
    include("log.jl")
end
