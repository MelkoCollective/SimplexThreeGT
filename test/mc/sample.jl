using Test
using SimplexThreeGT.Spec
using SimplexThreeGT.MonteCarlo: MarkovChain, burn!

task = TaskInfo(;
    shape=ShapeInfo(
        ndims=3,
        size=3,
    ),
    sample=SamplingInfo(
        nburns=100,
        nsamples=1000,
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
mc.obs[1]
