using CSV
using Plots
using Random
using DataFrames
using Configurations
using SimplexThreeGT

spin_idx = 1
csm = CellMap(3, 2=>3, 4)

ENV["JULIA_DEBUG"] = "SimplexThreeGT"

task = TaskInfo(;
    seed=1334,
    shape = ShapeInfo(;
        ndims=3,
        size=4
    ),
    sample = SamplingInfo(;
        nburns=50_000,
        nsamples=5_000_000,
        nthrows=1,
        observables=["E", "E^2"]
    ),
    temperature = Schedule(;
        start=30.0,
        step=-0.05,
        stop=0.1
    )
)
from_toml(ChainTaskInfo, pkgdir(SimplexThreeGT, "scripts", "3d4L.toml"))
to_toml(pkgdir(SimplexThreeGT, "scripts", "3d4L.toml"), task)
task
mcmc = SimplexMCMC(task)
annealing!(mcmc, task)
