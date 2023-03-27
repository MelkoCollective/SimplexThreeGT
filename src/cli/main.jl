
"""
run annealing task.

# Options

- `--job <uuid>`: the job name.
- `--task <int>`: the task id.
- `--path <path>`: the path to the storage.
- `--tags <tags>`: the tags of the storage.
"""
@cast function annealing(; job::String, task::Int, path::String="data", tags::String="")
    storage = StorageInfo(path, tags)
    an_file = Jobs.image_dir(storage, "temp", job, "annealing", "$(task).toml")
    task = from_toml(AnnealingOptions, an_file)
    @info "annealing starts" task
    MonteCarlo.annealing(task)
    return
end

"""
run resample task.

# Options

- `--job <uuid>`: the job name.
- `--task <int>`: the task id.
- `--path <path>`: the path to the storage.
- `--tags <tags>`: the tags of the storage.
"""
@cast function resample(; job::String, task::Int, path::String="data", tags::String="")
    storage = StorageInfo(path, tags)
    rs_file = Jobs.image_dir(storage, "temp", job, "resample", "$(task).toml")
    task = from_toml(ResampleOptions, rs_file)
    @info "resample starts" task
    MonteCarlo.resample(task)
    return
end

"""
run cellmap task.

# Options

- `--job <uuid>`: the job name.
- `--path <path>`: the path to the storage.
- `--tags <tags>`: the tags of the storage.
"""
@cast function cellmap(; job::String, path::String="data", tags::String="")
    storage = StorageInfo(path, tags)
    cm_file = Jobs.image_dir(storage, "temp", job, "cellmap.toml")
    task = from_toml(CellMapOptions, cm_file)
    @info "cellmap starts" task
    Homology.cell_map(task)
    return
end

"""
clean up the temporary files and logs.

# Options

- `--path <path>`: the path to the storage.
- `--tags <tags>`: the tags of the storage
"""
@cast function clean(; path::String="data", tags::String="")
    storage = StorageInfo(path, tags)
    @info "clean up" storage
    rm(Jobs.image_dir(storage, "temp"), recursive=true, force=true)
    rm(Jobs.checkpoint_dir(storage, "temp"), recursive=true, force=true)
    rm(Jobs.log_dir(storage), recursive=true, force=true)
    return
end

"""
watch a log file.

# Args

- `path`: the path to the log file.

# Options

- `--ms <int>`: the interval in milliseconds.
"""
@cast function watch(path::String; ms::Int=5)
    Base.exit_on_sigint(false)
    try
        open(path) do io
            max_width = 0
            local line
            while !eof(io)
                line = readline(io)
                max_width = max(max_width, length(line))
                if occursin("ETA", line)
                    print('\r', line, ' '^(max_width - length(line)))
                else
                    println(line)
                end
            end

            if line == "done"
                println('\n', done)
                return
            end

            while true
                if !eof(io)
                    line = readline(io)
                    line == "done" && break
                    print('\r', line, ' '^(max_width - length(line)))
                end
                sleep(ms / 1000)
            end
        end # open
    catch e
        if e isa InterruptException
            println("\ninterrupted")
            return
        else
            throw(Comonicon.cmd_error(string(e), 1))
        end
    end
end
