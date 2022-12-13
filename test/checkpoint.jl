using Test
using SimplexThreeGT: write_checkpoint, read_checkpoint, find_checkpoint, task_dir

cp = "data/simplex-3d-4/769b77c6-7760-11ed-27b8-d750ade06f5f.checkpoint"
f = open(cp)
read_checkpoint(f, 4^3)

d = Dict()
for T in 10:-0.1:0.1
    d[T] = BitVector(rand(Bool, 10))
end

open("test.checkpoint", "w+") do f
    for T in 10:-0.1:0.1
        write_checkpoint(f, T, d[T])
    end
end

@testset "find_checkpoint" begin
    for T in 10:-0.1:0.1
        temp, spins = open("test.checkpoint", "r") do f
            find_checkpoint(f, T, 10)
        end
        @test d[temp] == spins
    end
end

@testset "read_checkpoint" begin
    open("test.checkpoint", "r") do f
        while !eof(f)
            temp, spins = read_checkpoint(f, 10)
            @test temp in keys(d)
            @test d[temp] == spins
        end
    end
end

rm("test.checkpoint")
