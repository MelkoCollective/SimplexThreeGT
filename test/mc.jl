using CSV
using Plots
using Random
using DataFrames
using Configurations
using SimplexThreeGT

ENV["JULIA_DEBUG"] = "SimplexThreeGT"

task = TaskInfo(;
    shape = ShapeInfo(;
        ndims=3,
        size=4
    ),
    sample = SamplingInfo(;
        nburns=10_000,
        nsamples=500_000,
        nthrows=10,
        observables=["E", "E^2"]
    ),
    temperature = Schedule(;
        start=4.6,
        step=-0.01,
        stop=0.1
    )
)
from_toml(ChainTaskInfo, pkgdir(SimplexThreeGT, "scripts", "3d4L.toml"))
to_toml(pkgdir(SimplexThreeGT, "scripts", "3d4L.toml"), task)

chain = ChainTaskInfo(task)
mcmc = SimplexMCMC(chain)
annealing!(mcmc, chain)
resample(chain; seed=rand(UInt))
using SimplexThreeGT: sample!

@profview annealing!(mcmc, chain)

df = collect_samples(chain; extra=false)
specific_heat!(df, chain)
plot_specific_heat(df)

df = collect_samples(chain; extra=true)
specific_heat!(df, chain)
plot_specific_heat(df)
