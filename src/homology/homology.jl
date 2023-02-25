module Homology

using ProgressLogging: @withprogress, @logprogress
using ..Spec: ShapeInfo, shape_name
using Serialization: deserialize, serialize
using Combinatorics: combinations
using ..SimplexThreeGT: with_path_log

export CellMap, nspins

function with_shape_log(f, shape::ShapeInfo, name::String)
    with_path_log(f, shape_dir(shape, "logs"), name)
end

include("cells.jl")
include("cellmap.jl")

end # module Homology
