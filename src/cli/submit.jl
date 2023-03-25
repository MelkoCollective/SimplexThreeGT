"""
submit slurm jobs
"""
@cast module Submit

using Comonicon
using SimplexThreeGT.Jobs

"""
submit annealing task to slurm.

# Options

- `--job <toml file>`: the job toml file.
"""
@cast function annealing(;job::AnnealingJob)
    Jobs.submit(job)
    return
end

"""
submit resample task to slurm.

# Options

- `--job <toml file>`: the job toml file.
"""
@cast function resample(;job::ResampleJob)
    Jobs.submit(job)
    return
end

"""
submit annealing and resample task to slurm.

# Options

- `--job <toml file>`: the job toml file.
"""
@cast function simu(;job::SimulationJob)
    Jobs.submit(job)
    return
end

end # module
