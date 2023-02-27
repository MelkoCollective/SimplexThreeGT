module MonteCarlo

using DocStringExtensions
using GarishPrint: pprint_struct
using Random: AbstractRNG, Xoshiro
using Configurations: Maybe
using UUIDs: UUID, uuid1
using ProgressLogging: @progress
using ..Homology: CellMap, nspins, cell_map
using ..Spec: TaskInfo, ShapeInfo, SamplingInfo, Schedule, temperatures, fields, task_dir
using ..Checkpoint: Checkpoint, find_checkpoint, write_checkpoint
using ..SimplexThreeGT: with_path_log

function with_task_log(f, task::TaskInfo, name::String)
    with_path_log(f, task_dir(task, "logs"), name)
end

include("spins.jl")
include("types.jl")
include("status.jl")
include("update.jl")
include("serialize.jl")
include("sample.jl")

end # module MonteCarlo
