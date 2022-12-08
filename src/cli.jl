module CLI

using Comonicon
using Configurations
using TerminalLoggers: TerminalLogger
using Logging: with_logger
using ..SimplexThreeGT:
    SimplexThreeGT,
    ChainTaskInfo, TaskInfo,
    ShapeInfo, SamplingInfo, Schedule,
    shape_dir, task_dir,
    SimplexMCMC, annealing!

@cast function annealing(;task::ChainTaskInfo)
    mcmc = SimplexMCMC(task)
    log_file = task_dir(task, "annealing.log")
    open(log_file, "w") do io
        with_logger(TerminalLogger(io; always_flush=true)) do
            @info "annealing starts" task
            annealing!(mcmc, task)
        end
    end
    return
end

@cast function resample(;task::ChainTaskInfo)
    log_file = task_dir(task, "annealing.log")
    open(log_file, "w") do io
        with_logger(TerminalLogger(io; always_flush=true)) do
            @info "resample starts" task
            SimplexThreeGT.resample(task)
        end
    end
    return
end

@main

end # CLI
