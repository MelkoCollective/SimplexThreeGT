module CLI

using Comonicon
using Serialization
using Configurations
using TerminalLoggers: TerminalLogger
using Logging: with_logger
using ..SimplexThreeGT:
    CubicSpinMap,
    SimplexThreeGT,
    ChainTaskInfo, TaskInfo,
    ShapeInfo, SamplingInfo, Schedule,
    shape_dir, task_dir,
    SimplexMCMC, annealing!


function with_task_log(f, task::ChainTaskInfo, name::String)
    log_file = task_dir(task, "$name.log")
    open(log_file, "w") do io
        with_logger(f, TerminalLogger(io; always_flush=true))
    end
    return
end

@cast function annealing(;task::ChainTaskInfo)
    with_task_log(task, "annealing") do
        @info "annealing starts" task
        mcmc = SimplexMCMC(task)
        annealing!(mcmc, task)
    end
    return
end

@cast function resample(;task::ChainTaskInfo)
    with_task_log(task, "resample") do
        @info "resample starts" task
        SimplexThreeGT.resample(task)
    end
    return
end

@cast function csm(;task::ChainTaskInfo)
    csm_cache = shape_dir(task.shape, "csm.jls")
    if isfile(csm_cache)
        @info "csm file exists" task
        return
    end

    with_task_log(task, "csm") do
        @info "csm generating starts" task
        csm = CubicSpinMap(task.shape)
        serialize(csm_cache, csm)
    end
    return
end

@main

end # CLI
