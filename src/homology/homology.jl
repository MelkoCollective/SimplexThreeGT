module Homology

using ProgressLogging: @withprogress, @logprogress
using ..Jobs
using Serialization: deserialize, serialize
using Combinatorics: combinations
using ..SimplexThreeGT: with_log

export CellMap, nspins, cell_map, spin_map, gauge_map

include("cells.jl")
include("cellmap.jl")

end # module Homology
