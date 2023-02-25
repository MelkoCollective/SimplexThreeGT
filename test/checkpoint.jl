using Test
using SimplexThreeGT.Checkpoint: write_checkpoint, read_checkpoint, find_checkpoint
using SimplexThreeGT.Spec: task_dir

@testset "h=$h" for h in 0.0:0.1:0.2
    d = Dict()
    for T in 10:-0.1:0.1
        d[T] = BitVector(rand(Bool, 10))
    end

    open("test.checkpoint", "w+") do f
        for T in 10:-0.1:0.1
            write_checkpoint(f, T, d[T], h)
        end
    end

    @testset "find_checkpoint" begin
        for T in 10:-0.1:0.1
            temp, spins = open("test.checkpoint", "r") do f
                find_checkpoint(f, T, 10, h)
            end
            @test d[temp] == spins
        end
    end

    @testset "read_checkpoint" begin
        open("test.checkpoint", "r") do f
            while !eof(f)
                temp, field, spins = read_checkpoint(f, 10)
                @test field == h
                @test temp in keys(d)
                @test d[temp] == spins
            end
        end
    end

    rm("test.checkpoint")
end # for h
