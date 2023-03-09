using Test
using SimplexThreeGT.Spec
using SimplexThreeGT.Spec: shape_dir
using SimplexThreeGT.MonteCarlo: MarkovChain

@testset "MarkovChain(task) d=$d" for d in 3:4
    task = TaskInfo(;
        shape=ShapeInfo(
            ndims=d,
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
    @test isfile(shape_dir(task.shape, "cm-$(d)d-3L-1-2.jls"))
    @test isfile(shape_dir(task.shape, "cm-$(d)d-3L-2-3.jls"))
    show(devnull, MIME"text/plain"(), mc)
end # testset
