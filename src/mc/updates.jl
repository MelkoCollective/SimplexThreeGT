function energy(cm::CellMap, spins::Vector{Int})
    return sum(values(cm.p2p1)) do attach_spins
        return local_energy(attach_spins, spins)
    end
end

function energy(cm::CellMap, spins::BitVector)
    return sum(values(cm.p2p1)) do attach_spins
        return local_energy(attach_spins, spins)
    end
end

function local_energy(attach_spins, spins::Vector{Int})
    return -prod(attach_spins) do j
        @inbounds spins[j]
    end
end

function local_energy(attach_spins, spins::BitVector)
    up_spins = sum(attach_spins) do j
        @inbounds spins[j]
    end
    return isodd(up_spins) ? 1 : -1
end

Base.@propagate_inbounds function flip_spin!(spins::Vector{Int}, idx::Int)
    spins[idx] = -spins[idx]
    return spins
end

Base.@propagate_inbounds function flip_spin!(spins::BitVector, idx::Int)
    spins[idx] = !spins[idx]
    return spins
end

Base.@propagate_inbounds function gauge_flip!(spins, cm::CellMap, edge_idx::Int)
    for attach_spin in cm.p1p2[edge_idx]
        flip_spin!(spins, attach_spin)
    end
    return spins
end

function rand_spins(rng, nspins)
    return BitVector(rand(rng, Bool, nspins))
end

energy(mcmc::SimplexMCMC) = energy(mcmc.cm, mcmc.spins)

function energy_diff!(mcmc::SimplexMCMC, spin_idx::Int)
    effected_cubes = mcmc.cm.p1p2[spin_idx]
    E_old = sum(effected_cubes) do cube_idx
        cube_spins = mcmc.cm.p2p1[cube_idx]
        local_energy(cube_spins, mcmc.state.spins)
    end

    @inbounds flip_spin!(mcmc.state.spins, spin_idx)

    E_new = sum(effected_cubes) do cube_idx
        cube_spins = mcmc.cm.p2p1[cube_idx]
        local_energy(cube_spins, mcmc.state.spins)
    end

    return E_new - E_old
end

function metropolis_accept!(mcmc::SimplexMCMC, delta_E)
    delta_E ≤ 0 && return true
    exp(-delta_E/mcmc.state.temp) > rand(mcmc.rng) && return true
    return false
end

function mcmc_step!(mcmc::SimplexMCMC)
    spin_idx = rand(mcmc.rng, 1:nspins(mcmc.cm))
    delta_E = energy_diff!(mcmc, spin_idx) #flips spin
    if metropolis_accept!(mcmc, delta_E)
        mcmc.state.energy += delta_E
    else
        @inbounds flip_spin!(mcmc.state.spins, spin_idx) #flip the spin back
    end
    return mcmc
end

function gauge_step!(mcmc::SimplexMCMC)
    edge_idx = rand(mcmc.rng, 1:nedges(mcmc.cm))
    delta_E = sum(mcmc.cm.p1p2[edge_idx]) do spin_idx
        energy_diff!(mcmc, spin_idx) #flips spin
    end

    if metropolis_accept!(mcmc, delta_E)
        mcmc.state.energy += delta_E
    else
        @inbounds gauge_flip!(mcmc.state.spins, mcmc.cm, edge_idx) #flip the spin back
    end
    return mcmc
end

function burn!(mcmc::SimplexMCMC, task::TaskInfo)
    for _ in 1:task.sample.nburns
        mcmc_step!(mcmc)
    end
    return mcmc
end

function sample!(mcmc::SimplexMCMC, task::TaskInfo)
    init!(mcmc)

    for _ in 1:task.sample.nsamples
        for _ in 1:nspins(mcmc.cm)÷2
            mcmc_step!(mcmc)
        end

        task.sample.gauge && for _ in 1:nspins(mcmc.gauge)÷2
            gauge_step!(mcmc)
        end
        collect!(mcmc)
    end

    finalize!(mcmc, task.sample.nsamples)
    return mcmc
end

function write_checkpoint(io::IO, mcmc::SimplexMCMC)
    write_checkpoint(io, mcmc.state.temp, mcmc.state.spins)
    flush(io) # always flush after writing, so we can recover from a crash
    return
end

function checkpoint(f, mcmc::SimplexMCMC, task::TaskInfo)
    path = task_dir(task, "checkpoints")
    ispath(path) || mkpath(path)
    checkpoint_file = task_dir(task, "checkpoints", "$(mcmc.uuid).checkpoint")
    return open(checkpoint_file, "a+") do io
        function agent()
            write_checkpoint(io, mcmc)
        end
        f(agent)
    end
end

function record(f, data_file::String)
    require_header = !isfile(data_file)
    open(data_file, "a+") do storage_io
        function agent(mcmc)
            if require_header
                println(storage_io, "temp,", join(obs_names(mcmc), ","))
                require_header = false
            end

            print(storage_io, mcmc.state.temp)
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

function annealing!(mcmc::SimplexMCMC, task::TaskInfo)
    isnothing(task.uuid) || error("annealing task should not have a uuid")
    isnothing(task.repeat) || error("annealing task should not have a repeat")
    isnothing(task.sample.nburns) && error("annealing task should have nburns")

    save_task_image(task, mcmc.uuid)
    ispath(task_dir(task, "annealing")) || mkpath(task_dir(task, "annealing"))
    data_file = task_dir(task, "annealing", "$(mcmc.uuid).csv")

    with_task_log(task, "annealing-$(mcmc.uuid)") do
        checkpoint(mcmc, task) do checkpoint_agent
            # NOTE: make sure the data is written to different
            # files under same directory for different runs
            record(data_file) do record_agent
                @progress name="annealing" for T in temperatures(task)
                    mcmc.state.temp = T
                    @debug "Temperature: $T"
                    burn!(mcmc, task)
                    sample!(mcmc, task)

                    record_agent(mcmc)
                    checkpoint_agent()
                end
            end
        end
    end # with_task_log
    return mcmc
end

function read_checkpoint(task::TaskInfo, seed=task.seed)
    isnothing(task.uuid) && error("expect a task uuid of preivous run")

    cm_cache = shape_file(task.shape)
    isfile(cm_cache) || error("cell map cache not found")
    cm = deserialize(cm_cache)

    checkpoints = let checkpoints_dir = task_dir(task, "checkpoints")
        ispath(checkpoints_dir) || error("no checkpoint file found")
        checkpoint_file = task_dir(task, "checkpoints", "$(task.uuid).checkpoint")
        isfile(checkpoint_file) || error("checkpoint file not found")
        open(task_dir(task, "checkpoints", checkpoint_file), "r") do f
            find_checkpoint(f, temperatures(task), nspins(cm))
        end
    end

    # create SimplexMCMC for each temperature
    rng = Xoshiro(seed)
    mcmcs = Dict{Float64,SimplexMCMC}()
    for (temp, spins) in checkpoints
        mcmcs[temp] = SimplexMCMC(;
            rng=Xoshiro(rand(rng, UInt)),
            cm,
            spins,
            temp,
            task,
        )
    end
    return mcmcs
end

function resample(task::TaskInfo)
    isnothing(task.repeat) && error("expect nrepeat specified")
    isnothing(task.uuid) && error("expect uuid specified")
    isnothing(task.sample.nburns) || error("resample task should not have nburns")

    seed = task.seed::Int; nrepeat = task.repeat::Int;

    # save resample task configuration
    uuid = uuid1()
    save_task_image(task, uuid, "resample")

    mcmc_points = read_checkpoint(task, seed)
    # NOTE: no need to checkpoint here, since we are already
    # at the equilibrium state.
    guarantee_dir(task_dir(task, "resample"))
    data_file = task_dir(task, "resample", "$(uuid).csv")

    with_task_log(task, "resample-$uuid") do
        @info "Resampling $(length(mcmc_points)) chains" nrepeat seed
        record(data_file) do record_agent
            @progress name="resample" for _ in 1:nrepeat
                for temp in temperatures(task)
                    @debug "Temperature: $(temp)"
                    mcmc = mcmc_points[temp]
                    sample!(mcmc, task)
                    record_agent(mcmc)
                end
            end
        end
    end # with_task_log
    return
end
