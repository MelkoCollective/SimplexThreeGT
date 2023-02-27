"""
    $(TYPEDEF)

An observable.

### Fields

- `value::Float64`: The current value of the observable.
- `final::Bool`: Whether the observable is final.

### Type Parameters

- `Tag`: The name of the observable.
"""
mutable struct Observable{Tag}
    value::Float64
    final::Bool
end

Observable(name::String) = Observable(Symbol(name))

"""
    Observable(name::Symbol) -> Observable{name}

Create a new observable with the given name.
"""
Observable(name::Symbol) = Observable{name}(0.0, false)

"""
    observable_name(::Observable{Tag}) where Tag -> Symbol

Get the name of an observable.
"""
observable_name(::Observable{Tag}) where Tag = Tag

Base.@kwdef mutable struct State
    spins::BitVector
    temp::Float64
    energy::Float64
    field::Float64
end

"""
    $(TYPEDEF)

A Markov chain.

### Fields

- `rng::AbstractRNG`: The random number generator to use.
- `uuid::UUID`: The UUID of the Markov chain.
- `cm::CellMap`: The cell map to use.
- `gauge::Maybe{CellMap}`: The gauge to use.
- `state::State`: The current state of the Markov chain.
- `obs::Observables`: The observables to track.
"""
Base.@kwdef struct MarkovChain{RNG <: AbstractRNG, Observables <: Tuple}
    rng::RNG
    uuid::UUID
    cm::CellMap
    gauge::Maybe{CellMap}
    state::State
    obs::Observables
end

"""
    observable_names(mc::MarkovChain) -> NTuple{N, Symbol}

Get the names of the observables in a Markov chain.
"""
observable_names(mc::MarkovChain) = map(observable_name, mc.obs)

"""
    $(SIGNATURES)

Create a new Markov chain from a task.

### Arguments

- `task::TaskInfo`: The task to create the Markov chain from.

### Keyword Arguments

- `rng::AbstractRNG = Xoshiro(task.seed)`: The random number generator to use.
- `uuid::UUID = isnothing(task.uuid) ? uuid1() : task.uuid`: The UUID of the Markov chain.
- `cm::CellMap = cell_map(task.shape, (2, 3))`: The cell map to use.
- `gauge::Maybe{CellMap} = task.sample.gauge ? cell_map(task.shape, (1, 2)) : nothing`: The gauge cell map to use.
- `spins::BitVector = rand_spins(rng, nspins(cm))`: The initial spins to use.
"""
function MarkovChain(
        task::TaskInfo;
        rng::AbstractRNG = Xoshiro(task.seed),
        uuid::UUID = isnothing(task.uuid) ? uuid1() : task.uuid,
        cm::CellMap = cell_map(task.shape, (2, 3)),
        gauge::Maybe{CellMap} = task.sample.gauge ? cell_map(task.shape, (1, 2)) : nothing,
        spins::BitVector = rand_spins(rng, nspins(cm)),
    )

    field = if isnothing(task.extern_field)
        0.0
    else
        task.extern_field.first
    end

    state = State(;
        spins,
        field,
        temp = task.temperature.start,
        energy = energy(cm, spins, field),
    )

    obs = ntuple(length(task.sample.observables)) do i
        Observable(task.sample.observables[i])
    end

    return MarkovChain(
        rng,
        uuid,
        cm,
        gauge,
        state,
        obs,
    )
end

function Base.show(io::IO, mime::MIME"text/plain", mc::MarkovChain)
    println(io, "MarkovChain{", typeof(mc.rng), "}:")
    println(io, "  uuid   = \"", mc.uuid, "\"")

    print(io, "  obs    = ")
    join(io, observable_names(mc), ", ")
    println(io)

    print(io, "  ")
    show(IOContext(io, :indent=>2), mime, mc.cm)

    if !isnothing(mc.gauge)
        println(io)
        print(io, "  Gauge:")
        println(io)
        print(io, " "^4)
        show(IOContext(io, :indent=>4), mime, mc.gauge)
    end

    println(io)
    println(io, "  State:")
    println(io, "    temp   = ", mc.state.temp)
    println(io, "    field  = ", mc.state.field)
    print(io, "    energy = ", mc.state.energy)
end
