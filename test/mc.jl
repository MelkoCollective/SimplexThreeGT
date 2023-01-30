using Test
using SimplexThreeGT
using SimplexThreeGT: energy, local_energy, gauge_flip!, cell_topology

@testset "energy D=2" begin
    cm = CellMap(2, 3, (1, 2))
    gauge_cm = CellMap(2, 3, (0, 1))
    spins = falses(18)
    @test energy(cm, spins) == -9
    gauge_flip!(spins, gauge_cm, 1)
    @test energy(cm, spins) == -9
end # energy

@testset "energy D=3" begin
    cm = CellMap(3, 3, (2, 3))
    gauge_cm = CellMap(3, 3, (1, 2))
    spins = falses(nspins(cm))
    @test energy(cm, spins) == -27
    gauge_flip!(spins, gauge_cm, 1)
    @test energy(cm, spins) == -27
end

task = TaskInfo(
    seed=1334,
    shape = ShapeInfo(
        ndims = 3,
        size  = 4,
    ),
    sample = SamplingInfo(
        nburns=50_000,
        nsamples=5_000_000,
        nthrows=1,
        observables = ["E", "E^2"],
    ),
    temperature = Schedule(
        start=4.6,
        step=0.05,
        stop=0.05,
    )
)

mcmc = SimplexMCMC(task)
annealing!(mcmc, task)

task = TaskInfo(
    seed=1334,
    shape = ShapeInfo(
        ndims = 4,
        size  = 4,
    ),
    sample = SamplingInfo(
        nburns=2000,
        nsamples=20000,
        nthrows=324÷2,
        observables = ["E", "E^2"],
    ),
    temperature = Schedule(
        start=1.4,
        step=0.01,
        stop=0.99,
    )
)


mcmc = SimplexMCMC(task)
annealing!(mcmc, task)
