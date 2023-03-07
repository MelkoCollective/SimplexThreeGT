using Test
using SimplexThreeGT.Checkpoint: Checkpoint, Row
using SimplexThreeGT.Spec: task_dir

@testset "write" begin
    open("test.checkpoint", "w") do io
        for h in 0.0:0.1:0.2, T in 10:-0.1:0.1
            write(io, Row(h, T, BitVector(rand(Bool, 10))))
        end
    end
end # write

@testset "read" begin
    results = Checkpoint.read_all_records("test.checkpoint")
    count = 0
    for h in 0.0:0.1:0.2, T in 10:-0.1:0.1
        count += 1
        @test results[count].temp == T
        @test results[count].field == h
    end
end

@testset "find checkpoint" begin
    for row in Checkpoint.find("test.checkpoint"; temps=[0.1, 0.2], fields=[0.0])
        @test row.temp in [0.1, 0.2]
        @test row.field == 0.0
    end
end # find checkpoint

rm("test.checkpoint")
