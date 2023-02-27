module Spec

using DocStringExtensions
using GarishPrint: GarishPrint
using UUIDs: UUID
using ..SimplexThreeGT: SimplexThreeGT
using Configurations: Configurations, @option, Maybe, OptionField

export Schedule

"""
    $(TYPEDEF)

Options for the schedule.

### Fields

- `start::Float64`: The starting temperature, defaults to `10.0`.
- `step::Float64`: The temperature step, defaults to `0.1`.
- `stop::Float64`: The stopping temperature, defaults to `0.1`.
"""
@option struct Schedule
    start::Float64 = 10.0
    step::Float64 = 0.1
    stop::Float64 = 0.1

    function Schedule(start, step, stop)
        start > stop || throw(ArgumentError("start must be greater than stop"))
        step > 0 || throw(ArgumentError("step must be positive"))
        return new(start, step, stop)
    end
end

function temperatures(t::Schedule)
    return t.start:-t.step:t.stop
end

function fields(t::Schedule)
    return t.start:-t.step:t.stop
end

export StorageInfo

"""
    $(TYPEDEF)

Options for storage.

### Fields

- `data_dir::String`: The directory to store data in, defaults to `"data"`.
- `checkpoint::String`: The name of the checkpoint file, defaults to `"checkpoint.txt"`.
- `tags::Vector{String}`: Tags to add to the data directory, defaults to `String[]`.
"""
@option struct StorageInfo
    data_dir::String = "data"
    checkpoint::String = "checkpoint.txt"
    tags::Vector{String} = String[]
end

function data_dir(st::StorageInfo, xs...)
    path = pkgdir(SimplexThreeGT, st.data_dir, join(st.tags, "-"))
    return joinpath(guarantee_dir(path), xs...)
end

export ShapeInfo

"""
    $(TYPEDEF)

Options for the shape of the lattice.

### Fields

- `ndims::Int`: Number of dimensions.
- `size::Int`: Size of the lattice.
- `storage::StorageInfo`: Options for storage, defaults to `StorageInfo()`.
"""
@option struct ShapeInfo
    ndims::Int
    size::Int
    storage::StorageInfo = StorageInfo()
end

function shape_name(shape::ShapeInfo)
    return "cm-$(shape.ndims)d-$(shape.size)L"
end

function shape_dir(shape::ShapeInfo, xs...)
    guarantee_dir(data_dir(shape.storage, "shape"))
    return data_dir(shape.storage, "shape", xs...)
end

function shape_file(shape::ShapeInfo)
    shape_dir(shape, shape_name(shape) * ".jls")
end

export SamplingInfo

"""
    $(TYPEDEF)

Options for sampling.

### Fields

- `nburns::Maybe{Int}`: Number of burn-in samples, defaults to `nothing`.
- `nsamples::Int`: Number of samples to take, defaults to `50_000`.
- `nthrows::Maybe{Int}`: Number of throws to take, defaults to `nothing`.
- `gauge::Bool`: Whether to gauge the lattice, defaults to `true`.
- `gauge_nthrows::Maybe{Int}`: Number of throws to take when gauging, defaults to `nothing`.
- `observables::Vector{String}`: List of observables to take, defaults to `["E", "E^2"]`.
"""
@option struct SamplingInfo
    nburns::Maybe{Int}
    nsamples::Int = 50_000
    nthrows::Maybe{Int}
    gauge::Bool = true
    gauge_nthrows::Maybe{Int}
    observables::Vector{String} = ["E", "E^2"]
end

export TaskInfo

"""
    $(TYPEDEF)

Options for a single task.

### Fields

- `seed::Int`: Random seed for the task, defaults to a random value.
- `uuid::Maybe{UUID}`: UUID of the corresponding mcmc chain,
    defaults to `nothing`. If `nothing`, a new UUID will be every time the task is run.
- `repeat::Maybe{Int}`: Number of times to repeat the task, defaults to `nothing`.
- `shape::ShapeInfo`: Shape of the lattice.
- `sample::SamplingInfo`: Sampling options, defaults to `SamplingInfo()`.
- `temperature::Schedule`: Temperature schedule, defaults to `Schedule()`.
- `extern_field::Maybe{Schedule}`: External field schedule, defaults to `nothing`.
"""
@option struct TaskInfo
    seed::Int = Int(rand(UInt32))
    uuid::Maybe{UUID} # UUID of the corresponding mcmc chain
    repeat::Maybe{Int} # number of times to repeat the task
    shape::ShapeInfo
    sample::SamplingInfo = SamplingInfo()
    temperature::Schedule = Schedule()
    extern_field::Maybe{Schedule}
end

function task_dir(task::TaskInfo, xs...)
    path = guarantee_dir(data_dir(
        task.shape.storage,
        shape_name(task.shape),
    ))
    return joinpath(path, xs...)
end

function Base.show(io::IO, ::MIME"text/plain", options::TaskInfo)
    GarishPrint.pprint_struct(io, options)
end

function guarantee_dir(path::String)
    isdir(path) || mkpath(path)
    return path
end

temperatures(task::TaskInfo) = temperatures(task.temperature)
fields(task::TaskInfo) = fields(task.extern_field)

function Configurations.to_dict(::Type{TaskInfo}, x::UUID)
    return string(x)
end

function Configurations.from_dict(
        ::Type{<:TaskInfo}, ::OptionField{:uuid}, ::Type{UUID}, x::String)
    return UUID(x)
end

end # module Spec
