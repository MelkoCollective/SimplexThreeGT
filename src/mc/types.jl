mutable struct MCMCState
    spins::BitVector
    temp::Float64
    energy::Float64
end

mutable struct SimplexMCMC{RNG, Observables <: Tuple}
    rng::RNG
    uuid::UUID
    cm::CellMap
    gauge::Maybe{CellMap}
    state::MCMCState
    obs::Observables
end


function SimplexMCMC(;
        cm::CellMap,
        guage::Maybe{CellMap} = nothing,
        uuid::UUID = uuid1(),
        task::TaskInfo,
        temp::Real = task.temperature.start,
        seed::Integer = task.seed,
        rng::AbstractRNG = Xoshiro(seed),
        spins = rand_spins(rng, nspins(cm)),
    )

    state = MCMCState(spins, temp, energy(cm, spins))
    obs = ntuple(length(task.sample.observables)) do i
        Observable(task.sample.observables[i])
    end
    return SimplexMCMC(rng, uuid, cm, guage, state, obs)
end

function SimplexMCMC(task::TaskInfo)
    cm = cell_map(task.shape, (2, 3)) # face <-> cube
    gauge = task.sample.gauge ? cell_map(task.shape, (1, 2)) : nothing
    return SimplexMCMC(;cm, gauge, task)
end

function Base.show(io::IO, ::MIME"text/plain", mcmc::SimplexMCMC)
    println(io, "SimplexMCMC:")
    println(io, "  UUID: $(mcmc.uuid)")
    println(io, "  State:")
    println(io, "    temperature: $(mcmc.state.temp)")
    println(io, "    energy: $(mcmc.state.energy)")
    show(IOContext(io, :indent=>2), MIME"text/plain"(), mcmc.cm)
end
