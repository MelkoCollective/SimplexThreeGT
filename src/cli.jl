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
    @info "annealing starts" task
    with_logger(TerminalLogger()) do
        annealing!(mcmc, task)
    end
    return
end

@cast function resample(;task::ChainTaskInfo)
    @info "resample starts" task
    with_logger(TerminalLogger()) do
        SimplexThreeGT.resample(task)
    end
    return
end

@main

end # CLI
