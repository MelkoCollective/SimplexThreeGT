Checkpoint.Row(mc::MarkovChain) = Row(;mc.state.field, mc.state.temp, mc.state.spins)

function write_checkpoint(io::IO, mc::MarkovChain)
    write(io, Row(mc))
    flush(io) # always flush after writing, so we can recover from a crash
    return
end

function checkpoint(f, mc::MarkovChain, job::AnnealingJob)
    checkpoint_file = checkpoint_dir(job, "$(mc.uuid).checkpoint")
    return open(checkpoint_file, "a+") do io
        function agent()
            write_checkpoint(io, mc)
        end
        f(agent)
    end
end

function record(f, data_file::String)
    require_header = !isfile(data_file)
    open(data_file, "a+") do storage_io
        function agent(mcmc::MarkovChain)
            if require_header
                println(storage_io, "field,temp,", join(observable_names(mcmc), ","))
                require_header = false
            end

            print(storage_io, isnothing(mcmc.state.field) ? "0" : mcmc.state.field)
            print(storage_io, ",", mcmc.state.temp)
            for obs in mcmc.obs
                print(storage_io, ",", obs.value)
            end
            println(storage_io)
            flush(storage_io) # always flush after sampling
        end
        f(agent) # sampling process
    end
end

function save_task_image(job::AnnealingJob)
    to_toml(task_image_dir(job, "$(job.uuid).toml"), job)
end

function read_checkpoint(task::TaskInfo, seed=task.seed)
    cm = cell_map(task.shape, (task.shape.ndims-1, task.shape.ndims))
    # create MarkovChain for each temperature
    rng = Xoshiro(seed)
    return map(read_checkpoint_raw(task)) do row
        MarkovChain(task;
            # give each MarkovChain a different rng
            # so they can run in parallel
            rng=Xoshiro(rand(rng, UInt)),
            cm,
            # uuid should be different for each MarkovChain
            # so there is no race condition when running
            # multiple MarkovChain in parallel
            uuid=uuid1(),
            row.spins,
            row.temp,
            row.field,
        )
    end
end

function read_checkpoint_raw(task::TaskInfo)
    isnothing(task.uuid) && error("expect a task uuid of preivous run")
    checkpoints_dir = task_dir(task, "checkpoints")
    ispath(checkpoints_dir) || error("no checkpoint file found")
    checkpoint_file = task_dir(task, "checkpoints", "$(task.uuid).checkpoint")
    isfile(checkpoint_file) || error("checkpoint file not found")
    return open(task_dir(task, "checkpoints", checkpoint_file), "r") do f
        Checkpoint.find(f; fields=fields(task), temps=temperatures(task))
    end
end
