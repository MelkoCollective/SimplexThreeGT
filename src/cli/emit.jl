"""
emit task toml files
"""
@cast module Emit

using Comonicon
using SimplexThreeGT.Jobs

"""
emit annealing task toml files from job specification.

# Options

- `--job <toml file>`: the job toml file.
"""
@cast function annealing(;job::AnnealingJob)
    Jobs.emit(job)
    return
end

"""
emit resample task toml files from job specification.

# Options

- `--job <toml file>`: the job toml file.
"""
@cast function resample(;job::ResampleJob)
    Jobs.emit(job)
    return
end

"""
emit annealing and resample task toml files from job specification.

# Options

- `--job <toml file>`: the job toml file.
"""
@cast function simu(;job::SimulationJob)
    Jobs.emit(job)
    return
end

end # module
