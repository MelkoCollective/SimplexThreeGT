using Test
using LinearAlgebra
using CSV, DataFrames
using SimplexThreeGT: SimplexThreeGT
using SimplexThreeGT.Spec
using SimplexThreeGT.Spec: temperatures, fields
using SimplexThreeGT.Homology: CellMap, nspins
using SimplexThreeGT.MonteCarlo: MonteCarlo, MarkovChain, burn!, sample!, annealing!, resample, energy
using SimplexThreeGT.Exact
using SimplexThreeGT.Checkpoint
using Random

Random.seed!(1234)

@testset "sample" begin
    task = TaskInfo(;
        shape=ShapeInfo(
            ndims=2,
            size=2,
        ),
        sample=SamplingInfo(
            nburns=1000,
            nsamples=10000,
            nthrows=1000,
            gauge=false,
            observables=["E", "E^2"],
        ),
        temperature=Schedule(
            start=1.0,
            stop=0.1,
            step=0.1,
        ),
    )

    mc = MarkovChain(task)
    burn!(mc, task)
    sample!(mc, task)
    E = Exact.energy(mc.cm, mc.state.temp, mc.state.field)
    @test mc.obs[1].value ≈ E rtol=1e-2

    task = TaskInfo(;
        shape=ShapeInfo(
            ndims=2,
            size=2,
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

    mc = MarkovChain(task)
    burn!(mc, task)
    sample!(mc, task)
    @test mc.obs[1].value ≈ E rtol=1e-2

    task = TaskInfo(;
        shape=ShapeInfo(
            ndims=2,
            size=2,
        ),
        sample=SamplingInfo(
            nburns=1000,
            nsamples=10000,
            observables=["E", "E^2"],
        ),
        temperature=Schedule(
            start=1.0,
            stop=0.1,
            step=0.1,
        ),
    )

    mc = MarkovChain(task)
    burn!(mc, task)
    sample!(mc, task)
    @test mc.obs[1].value ≈ E rtol=1e-2

    task = TaskInfo(;
        shape=ShapeInfo(
            ndims=2,
            size=2,
        ),
        sample=SamplingInfo(
            nburns=1000,
            nsamples=10000,
            observables=["E", "E^2"],
        ),
        temperature=Schedule(
            start=1.0,
            stop=0.1,
            step=0.1,
        ),
        extern_field=Schedule(
            start=1.0,
            stop=0.1,
            step=0.1,
        )
    )

    mc = MarkovChain(task)
    E = Exact.energy(mc.cm, mc.state.temp, mc.state.field)
    burn!(mc, task)
    sample!(mc, task)
    @test mc.obs[1].value ≈ E rtol=1e-2
end # testset

@testset "annealing" begin
    task = TaskInfo(;
        shape=ShapeInfo(
            ndims=2,
            size=2,
            storage=StorageInfo(
                data_dir=pkgdir(SimplexThreeGT, "test", "data"),
            )
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
    mc = MarkovChain(task)
    annealing!(mc, task)
    Es = [Exact.energy(mc.cm, T, mc.state.field) for T in reverse(0.1:0.1:1.0)]

    file = Spec.task_dir(task, "annealing", "$(mc.uuid).csv")
    @test isfile(file)
    data = CSV.read(file, DataFrame)

    @testset "energy T=$T" for (i, T) in enumerate(0.1:0.1:1.0)
        @test data.E[i] ≈ Es[i] rtol=1e-2
    end # testset

    task = TaskInfo(;
        uuid = mc.uuid,
        repeat = 3,
        shape=ShapeInfo(
            ndims=2,
            size=2,
            storage=StorageInfo(
                data_dir=pkgdir(SimplexThreeGT, "test", "data"),
            )
        ),
        sample=SamplingInfo(
            nsamples=10000,
            nthrows=1000,
            gauge=true,
            observables=["E", "E^2"],
        ),
        temperature=Schedule(
            start=0.3,
            stop=0.1,
            step=0.2,
        ),
    )

    resample(task)
    dir = Spec.task_dir(task, "resample", "$(task.uuid)")
    file = joinpath(dir, first(readdir(dir)))
    data = CSV.read(file, DataFrame)
    Es = [Exact.energy(mc.cm, T, mc.state.field) for T in temperatures(task)]
    @test data.E[findfirst(isequal(0.1), data.temp)] ≈ Es[2] rtol=1e-3
    @test data.E[findfirst(isequal(0.3), data.temp)] ≈ Es[1] rtol=1e-3
    @test count(isequal(0.1), data.temp) == 3
    @test count(isequal(0.3), data.temp) == 3
end # testset
