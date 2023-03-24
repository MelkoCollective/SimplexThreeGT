module MonteCarlo

using DocStringExtensions
using GarishPrint: pprint_struct
using Random: AbstractRNG, Xoshiro
using Configurations: Maybe, to_toml
using Serialization: serialize, deserialize
using UUIDs: UUID, uuid1
using ProgressLogging: @progress, @withprogress, @logprogress
using Distributed
using Printf
using ..Homology: CellMap, nspins, spin_map, gauge_map
using ..Jobs
using ..Checkpoint: Checkpoint, Row
using ..SimplexThreeGT: with_log

function nothing_or(f, x)
    isnothing(x) ? nothing : f(x)
end

include("spins.jl")
include("types.jl")
include("status.jl")
include("update.jl")
include("serialize.jl")
include("sample.jl")
include("obs.jl")

end # module MonteCarlo
