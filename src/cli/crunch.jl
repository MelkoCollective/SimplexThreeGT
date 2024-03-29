@cast module Crunch

using Logging: with_logger
using TerminalLoggers: TerminalLogger
using Comonicon
using SimplexThreeGT.Jobs
using SimplexThreeGT.Checkpoint
using SimplexThreeGT.PostProcess

"""
crunch checkpoint files generated by the annealing task into one file.

# Options

- `--job <uuid>`: the job name.
- `--path <path>`: the path to the storage.
- `--tags <tags>`: the tags of the storage.
"""
@cast function checkpoint(;job::String, path::String="data", tags::String="")
    storage = StorageInfo(path, tags)
    target = Jobs.checkpoint_dir(storage, "$(job).checkpoint")
    temp_checkpoint_dir(xs...) = Jobs.checkpoint_dir(storage, "temp", job, xs...)
    rows = Checkpoint.Row[]
    for each in readdir(temp_checkpoint_dir())
        append!(rows, Checkpoint.read_all_records(temp_checkpoint_dir(each)))
    end
    Checkpoint.write(target, unique(rows))
    rm(temp_checkpoint_dir(); recursive=true, force=true)
    return
end

"""
crunch the sample data.

# Options

- `--job <uuid>`: the job name.
- `--path <path>`: the path to the storage.
- `--tags <tags>`: the tags of the storage.
"""
@cast function sample(;job::String, path::String="data", tags::String="")
    storage = StorageInfo(path, tags)
    with_logger(TerminalLogger()) do
        PostProcess.postprocess(storage, job)
    end
    return
end

end # module
