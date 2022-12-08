using UUIDs
using Configurations
using SimplexThreeGT

for d in 3:6, L in 4:2:16
    task = ChainTaskInfo(;
        seed=UInt(1234),
        shape = ShapeInfo(;
            ndims=d,
            size=L
        ),
        sample = SamplingInfo(;
            nburns=10_000,
            nsamples=500_000,
            nthrows=10,
            observables=["E", "E^2"]
        ),
        temperature = Schedule(;
            start=10.0,
            step=-0.01,
            stop=0.1
        )
    )
    to_toml(pkgdir(SimplexThreeGT, "task", "$(d)d$(L)L.toml"), task)
end
