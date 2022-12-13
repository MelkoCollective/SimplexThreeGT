module CLI

using Comonicon
using Serialization
using Configurations
using TerminalLoggers: TerminalLogger
using Logging: with_logger
using ..SimplexThreeGT:
    CubicSpinMap,
    SimplexThreeGT,
    TaskInfo,
    ShapeInfo, SamplingInfo, Schedule,
    shape_dir, task_dir,
    SimplexMCMC, annealing!,
    obtain_csm

function with_task_log(f, task::TaskInfo, name::String)
    log_file = task_dir(task, "$name.log")
    open(log_file, "w") do io
        with_logger(f, TerminalLogger(io; always_flush=true))
    end
    return
end

@cast function annealing(;task::TaskInfo)
    @info "annealing starts" task
    mcmc = SimplexMCMC(task)
    annealing!(mcmc, task)
    return
end

@cast function resample(;task::TaskInfo)
    @info "resample starts" task
    SimplexThreeGT.resample(task)
    return
end

@cast function csm(;task::ShapeInfo)
    @info "csm generating starts" task
    obtain_csm(task)
    return
end

@main

end # CLI
