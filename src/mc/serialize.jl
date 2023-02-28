function Checkpoint.write_checkpoint(io::IO, mc::MarkovChain)
    write_checkpoint(io, mc.state.temp, mc.state.spins)
    flush(io) # always flush after writing, so we can recover from a crash
    return
end

function checkpoint(f, mc::MarkovChain, task::TaskInfo)
    path = task_dir(task, "checkpoints")
    ispath(path) || mkpath(path)
    checkpoint_file = task_dir(task, "checkpoints", "$(mc.uuid).checkpoint")
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

            print(storage_io, mcmc.state.field, ",", mcmc.state.temp)
            for obs in mcmc.obs
                print(storage_io, ",", obs.value)
            end
            println(storage_io)
            flush(storage_io) # always flush after sampling
        end
        f(agent) # sampling process
    end
end

function save_task_image(task::TaskInfo, uuid::UUID, tag::String="task")
    let path = task_dir(task, "$(tag)_images")
        ispath(path) || mkpath(path)
    end
    to_toml(task_dir(task, "$(tag)_images", "$(uuid).toml"), task)
end

function read_checkpoint(task::TaskInfo, seed=task.seed)
    isnothing(task.uuid) && error("expect a task uuid of preivous run")

    cm = cell_map(task.shape, (task.shape.ndims-1, task.shape.ndims))
    checkpoints = let checkpoints_dir = task_dir(task, "checkpoints")
        ispath(checkpoints_dir) || error("no checkpoint file found")
        checkpoint_file = task_dir(task, "checkpoints", "$(task.uuid).checkpoint")
        isfile(checkpoint_file) || error("checkpoint file not found")
        open(task_dir(task, "checkpoints", checkpoint_file), "r") do f
            find_checkpoint(f, temperatures(task), nspins(cm))
        end
    end

    # create MarkovChain for each temperature
    rng = Xoshiro(seed)
    mcmcs = Dict{Float64,MarkovChain}()
    for (temp, spins) in checkpoints
        mc = MarkovChain(task;
            rng=Xoshiro(rand(rng, UInt)),
            cm,
            # uuid should be different for each MarkovChain
            # so there is no race condition when running
            # multiple MarkovChain in parallel
            uuid=uuid1(),
            spins,
        )
        mc.state.temp = temp
        mcmcs[temp] = mc
    end
    return mcmcs
end
