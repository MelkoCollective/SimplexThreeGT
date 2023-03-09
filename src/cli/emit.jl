"""
emit task toml files at `scripts/tasks`
"""
@cast module Emit

using Comonicon
using SimplexThreeGT: SimplexThreeGT
using SimplexThreeGT.CLI: CLI, foreach_shape, foreach_field
using Configurations
using SimplexThreeGT.Spec: TaskInfo, ShapeInfo, SamplingInfo, Schedule, guarantee_dir

function csm_task(d::Int, L::Int, p::Int)
    guarantee_dir(CLI.task_dir())
    task = ShapeInfo(;ndims=d, size=L, p)
    to_toml(CLI.task_dir("csm-$(d)d$(L)L.toml"), task)
    return
end

@cast function csm()
    foreach_shape() do d, L
        csm_task(d, L, 3)
    end
    return
end

function annealing_task(d::Int, L::Int, h_start::Float64, h_stop::Float64)
    guarantee_dir(CLI.task_dir())
    task = TaskInfo(;
        shape = ShapeInfo(;
            ndims=d,
            size=L
        ),
        sample = SamplingInfo(;
            nburns=50_000,
            nsamples=500_000,
            nthrows=10,
            observables=["E", "E^2"]
        ),
        temperature = Schedule(;
            start=50.0,
            step=0.01,
            stop=0.1
        ),
        extern_field = Schedule(;
            start=h_start,
            step=0.01,
            stop=h_stop
        )
    )

    file = CLI.task_dir("annealing-$(d)d$(L)L-$(h_start)h.toml")
    @info "emit annealing task for $(d)d$(L)L, $(h_start)h" path=file
    to_toml(file, task)
    return
end

@cast function annealing()
    @info "emit annealing tasks"
    foreach_shape() do d, L
        foreach_field() do h_start, h_stop
            annealing_task(d, L, h_start, h_stop)
        end
    end
    return
end


end # module
