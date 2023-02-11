export Schedule
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

export StorageInfo
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
@option struct ShapeInfo
    ndims::Int
    size::Int
    storage::StorageInfo = StorageInfo()
end

function shape_name(shape::ShapeInfo)
    return "cm-$(shape.ndims)d-$(shape.size)"
end

function shape_dir(shape::ShapeInfo, xs...)
    guarantee_dir(data_dir(shape.storage, "shape"))
    return data_dir(shape.storage, "shape", xs...)
end

function shape_file(shape::ShapeInfo)
    shape_dir(shape, shape_name(shape) * ".jls")
end

export SamplingInfo
@option struct SamplingInfo
    nburns::Maybe{Int}
    nsamples::Int = 50_000
    nthrows::Int = 10
    gauge::Bool = true
    gauge_nthrows::Int = 10
    observables::Vector{String} = ["E", "E^2"]
end

export TaskInfo
@option struct TaskInfo
    seed::Int = Int(rand(UInt32))
    uuid::Maybe{UUID} # UUID of the corresponding mcmc chain
    repeat::Maybe{Int} # number of times to repeat the task
    shape::ShapeInfo
    sample::SamplingInfo = SamplingInfo()
    temperature::Schedule = Schedule()
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

function temperatures(task::TaskInfo)
    return temperatures(task.temperature)
end

function Configurations.to_dict(::Type{TaskInfo}, x::UUID)
    return string(x)
end

function Configurations.from_dict(
        ::Type{<:TaskInfo}, ::OptionField{:uuid}, ::Type{UUID}, x::String)
    return UUID(x)
end
