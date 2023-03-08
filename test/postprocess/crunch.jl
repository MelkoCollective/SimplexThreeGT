using CSV
using Test
using DataFrames
using SimplexThreeGT
using Configurations
using SimplexThreeGT.MonteCarlo
using SimplexThreeGT.PostProcess
using SimplexThreeGT.Spec
using SimplexThreeGT.CLI
using Statistics

@testset "crunch" begin
    data_dir=pkgdir(SimplexThreeGT, "test", "data")
    task = TaskInfo(;
        shape=ShapeInfo(
            ndims=2,
            size=2,
            storage=StorageInfo(;data_dir)
        ),
        sample=SamplingInfo(
            nburns=1000,
            nsamples=10000,
            nthrows=1000,
            gauge=true,
            observables=["E", "E^2"],
        ),
        temperature=Schedule(
            start=1.0,
            stop=0.1,
            step=0.1,
        ),
    )
    mc = MonteCarlo.annealing(task)
    CLI.resample(data_dir; ndims=2, size=2, uuid=string(mc.uuid), repeat=3)
    CLI.resample(data_dir; ndims=2, size=2, uuid=string(mc.uuid), repeat=5)
    CLI.crunch(data_dir; ndims=2, size=2, uuid=string(mc.uuid))

    df = DataFrame(CSV.File(Spec.task_dir(task, "crunch", "$(mc.uuid).csv")))
    @test length(df.temp) == 10
    @test length(df.field) == 10
    @test df."E(std)"[end] ≈ 0.0
end # testset
