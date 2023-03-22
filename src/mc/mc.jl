module MonteCarlo

using DocStringExtensions
using GarishPrint: pprint_struct
using Random: AbstractRNG, Xoshiro
using Configurations: Maybe, to_toml
using Serialization: serialize, deserialize
using UUIDs: UUID, uuid1
using ProgressLogging: @progress
using Distributed
using ..Homology: CellMap, nspins, cell_map, gauge_map
using ..Jobs
using ..Checkpoint: Checkpoint, Row
using ..SimplexThreeGT: with_path_log

function with_task_log(f, storage::StorageInfo, shape::ShapeInfo, name::String)
    with_path_log(f, log_dir(storage, shape), name)
end

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
