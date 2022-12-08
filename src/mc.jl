function energy(csp::CubicSpinMap, spins::Vector{Int})
    return sum(values(csp.cube_to_spin)) do cube_spins
        return local_energy(cube_spins, spins)
    end
end

function energy(csp::CubicSpinMap, spins::BitVector)
    return sum(values(csp.cube_to_spin)) do cube_spins
        return local_energy(cube_spins, spins)
    end
end

function local_energy(cube_spins, spins::Vector{Int})
    return -prod(cube_spins) do j
        @inbounds spins[j]
    end
end

function local_energy(cube_spins, spins::BitVector)
    up_spins = sum(cube_spins) do j
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

mutable struct Observable{Tag}
    value::Float64
end

Observable(name::String) = Observable(Symbol(name))
Observable(name::Symbol) = Observable{name}(0.0)
obs_name(::Observable{Tag}) where Tag = Tag
init!(obs::Observable) = (obs.value = 0.0; return obs)

mutable struct MCMCState
    spins::Vector{Int}
    temp::Float64
    energy::Float64
end
mutable struct SimplexMCMC{RNG, Observables <: Tuple}
    rng::RNG
    csm::CubicSpinMap
    state::MCMCState
    obs::Observables
end

function SimplexMCMC(;
        csm::CubicSpinMap,
        task::ChainTaskInfo,
        temp::Real = task.temperature.start,
        seed::Integer = task.seed,
        rng::AbstractRNG = Xoshiro(seed),
        spins = rand(rng, (-1,1), nspins(csm)),
    )

    state = MCMCState(spins, temp, energy(csm, spins))
    obs = ntuple(length(task.sample.observables)) do i
        Observable(task.sample.observables[i])
    end
    return SimplexMCMC(rng, csm, state, obs)
end

function SimplexMCMC(task::ChainTaskInfo)
    csm_cache = shape_dir(task.shape, "csm.jls")
    if isfile(csm_cache)
        csm = deserialize(csm_cache)
    else
        csm = CubicSpinMap(task.shape)
        serialize(csm_cache, csm)
    end
    return SimplexMCMC(;csm, task)
end

function Base.show(io::IO, ::MIME"text/plain", mcmc::SimplexMCMC)
    println(io, "SimplexMCMC:")
    println(io, "  State:")
    println(io, "    temperature: $(mcmc.state.temp)")
    println(io, "    energy: $(mcmc.state.energy)")
    show(IOContext(io, :indent=>2), MIME"text/plain"(), mcmc.csm)
end

obs_names(mcmc::SimplexMCMC) = map(obs_name, mcmc.obs)

function init!(mcmc::SimplexMCMC)
    for obs in mcmc.obs
        init!(obs)
    end
    return mcmc
end

function collect!(mcmc::SimplexMCMC)
    for obs in mcmc.obs
        collect!(obs, mcmc)
    end
    return mcmc
end

collect!(::Observable{T}, ::SimplexMCMC) where T = error("Observable $(T) not implemented")

function collect!(ob::Observable{:E}, mcmc::SimplexMCMC)
    ob.value += mcmc.state.energy
    return ob
end

function collect!(ob::Observable{Symbol("E^2")}, mcmc::SimplexMCMC)
    ob.value += mcmc.state.energy^2
    return ob
end

function finalize!(mcmc::SimplexMCMC, nsamples::Int)
    for obs in mcmc.obs
        obs.value /= nsamples
    end
    return mcmc
end

energy(mcmc::SimplexMCMC) = energy(mcmc.csm, mcmc.spins)

function energy_diff!(mcmc::SimplexMCMC, spin_idx::Int)
    effected_cubes = mcmc.csm.spin_to_cube[spin_idx]
    E_old = sum(effected_cubes) do cube_idx
        cube_spins = mcmc.csm.cube_to_spin[cube_idx]
        local_energy(cube_spins, mcmc.state.spins)
    end

    @inbounds flip_spin!(mcmc.state.spins, spin_idx)

    E_new = sum(effected_cubes) do cube_idx
        cube_spins = mcmc.csm.cube_to_spin[cube_idx]
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
    spin_idx = rand(mcmc.rng, 1:nspins(mcmc.csm))
    delta_E = energy_diff!(mcmc, spin_idx) #flips spin
    if metropolis_accept!(mcmc, delta_E)
        mcmc.state.energy += delta_E
    else
        @inbounds flip_spin!(mcmc.state.spins, spin_idx) #flip the spin back
    end
    return mcmc
end

function burn!(mcmc::SimplexMCMC, task::ChainTaskInfo)
    for _ in 1:task.sample.nburns
        mcmc_step!(mcmc)
    end
    return mcmc
end

function sample!(mcmc::SimplexMCMC, task::ChainTaskInfo)
    init!(mcmc)

    for _ in 1:task.sample.nsamples
        for _ in 1:task.sample.nthrows
            mcmc_step!(mcmc)
        end
        collect!(mcmc)
    end

    finalize!(mcmc, task.sample.nsamples)
    return mcmc
end

function write_checkpoint(io::IO, mcmc::SimplexMCMC)
    print(io, mcmc.state.temp, ",")
    for s in mcmc.state.spins
        if s > 0
            print(io, '1')
        else
            print(io, '0')
        end
    end
    println(io)
    flush(io)
    return
end

function checkpoint(f, task::ChainTaskInfo)
    return open(task_dir(task, "checkpoint.txt"), "a+") do io
        function agent(mcmc::SimplexMCMC)
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

function annealing!(mcmc::SimplexMCMC, task::ChainTaskInfo)
    checkpoint(task) do checkpoint_agent
        # NOTE: make sure the data is written to different
        # files under same directory for different runs
        record(task_dir(task, "$(uuid1()).csv")) do record_agent
            @progress name="annealing" for T in temperatures(task)
                mcmc.state.temp = T
                @debug "Temperature: $T"
                burn!(mcmc, task)
                sample!(mcmc, task)

                record_agent(mcmc)
                checkpoint_agent(mcmc)
            end
        end
    end
    return mcmc
end

function read_checkpoint(task::ChainTaskInfo, seed=task.seed)
    csm_cache = shape_dir(task.shape, "csm.jls")
    isfile(csm_cache) || error("csm cache not found")
    csm = deserialize(csm_cache)

    rng = Xoshiro(seed)

    mcmcs = Dict{Float64, SimplexMCMC}()
    open(task_dir(task, "checkpoint.txt")) do io
        for line in eachline(io)
            temp, spins = split(line, ",")
            temp = parse(Float64, temp)
            spins = [s == '0' ? -1 : 1 for s in spins]
            # NOTE: seed needs to be different for each mcmc
            # otherwise the samples will be identical, thus
            # not useful for generating the distribution

            # NOTE: new checkpoint will be written to the same file
            # so that later checkpoint will replace the previous one
            mcmcs[temp] = SimplexMCMC(;
                rng=Xoshiro(rand(rng, UInt)),
                csm,
                spins,
                temp,
                task,
            )
        end
    end # checkpoint file

    # verify that we have all the temperatures
    for T in temperatures(task)
        haskey(mcmcs, T) || error("missing temperature: $T")
    end
    return mcmcs
end

function resample(task::ChainTaskInfo; seed = task.seed)
    mcmc_chains = read_checkpoint(task, seed)

    guarantee_dir(task_dir(task, "extra"))
    data_file = task_dir(task, "extra", "$(uuid1()).csv")

    # we need serialize the new checkpoint
    # so that next time resample produce
    # the new samples as if we running
    # a longer sampling process
    checkpoint(task) do checkpoint_agent
        @progress name="resample" for temp in temperatures(task)
            # NOTE: only re-sample temperatures we want
            mcmc = mcmc_chains[temp]
            @debug "Temperature: $(mcmc.state.temp)"
            record(data_file) do record_agent
                sample!(mcmc, task)
                record_agent(mcmc)
            end
            checkpoint_agent(mcmc)
        end # for
    end # checkpoint
    return
end
