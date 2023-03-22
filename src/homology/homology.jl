module Homology

using ProgressLogging: @withprogress, @logprogress
using ..Jobs
using Serialization: deserialize, serialize
using Combinatorics: combinations
using ..SimplexThreeGT: with_path_log

export CellMap, nspins, cell_map, gauge_map

function with_shape_log(f, storage::StorageInfo, shape::ShapeInfo, name::String)
    with_path_log(f, log_dir(storage, shape), name)
end

include("cells.jl")
include("cellmap.jl")

end # module Homology
