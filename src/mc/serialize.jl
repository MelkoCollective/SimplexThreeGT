Checkpoint.Row(mc::MarkovChain) = Row(;mc.state.field, mc.state.temp, mc.state.spins)

function write_checkpoint(io::IO, mc::MarkovChain)
    write(io, Row(mc))
    flush(io) # always flush after writing, so we can recover from a crash
    return
end

function checkpoint(f, mc::MarkovChain, task::AnnealingOptions)
    return open(checkpoint_file(task), "a+") do io
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

function read_checkpoint(task::ResampleOptions)
    cm = spin_map(task.storage, task.shape)
    gauge = nothing_or(task.sample.option.gauge) do
        gauge_map(task.storage, task.shape)
    end
    rng = Xoshiro(task.seed)

    # create a seperate chain for each selected
    # row in the checkpoint file
    return map(read_checkpoint_raw(task)) do row
        # each chain has the same uuid so we can write
        # to the same sample file
        MarkovChain(;
            rng = Xoshiro(rand(rng, UInt)),
            uuid = task.uuid,
            cm,
            gauge,
            state = State(;
                row.spins,
                row.temp,
                row.field,
                energy = energy(cm, row.spins, row.field),
            ),
            obs = ntuple(length(task.sample.observables)) do i
                name = task.sample.observables[i]
                Observable(name)
            end,
        )
    end # map
end

function read_checkpoint_raw(task::ResampleOptions)
    file = checkpoint_file(task)
    isfile(file) || error("checkpoint file not found")
    return open(file, "r") do f
        Checkpoint.find(f; task.matrix)
    end
end
