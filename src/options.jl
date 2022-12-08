export Schedule
@option struct Schedule
    start::Float64 = 10.0
    step::Float64 = -0.1
    stop::Float64 = 0.1
end

function temperatures(t::Schedule)
    return t.start:t.step:t.stop
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
    return "simplex-$(shape.ndims)d-$(shape.size)"
end

function shape_dir(shape::ShapeInfo, xs...)
    guarantee_dir(data_dir(shape.storage, shape_name(shape)))
    return data_dir(shape.storage, shape_name(shape), xs...)
end

export SamplingInfo
@option struct SamplingInfo
    nburns::Int = 50_000
    nsamples::Int = 50_000
    nthrows::Int = 10
    observables::Vector{String} = ["E", "E^2"]
end

export ChainTaskInfo
@option struct ChainTaskInfo
    uuid::UUID = uuid1()
    seed::UInt = rand(UInt)
    showprogress::Bool = false
    shape::ShapeInfo
    sample::SamplingInfo = SamplingInfo()
    temperature::Schedule = Schedule()

    function ChainTaskInfo(
        uuid::UUID,
        seed::UInt,
        showprogress::Bool,
        shape::ShapeInfo,
        sample::SamplingInfo,
        temperature::Schedule
    )
        task = new(
            uuid,
            seed,
            showprogress,
            shape,
            sample,
            temperature
        )
        # save sampling info
        # we don't allow mix data with different
        # sampling size
        sample_toml = task_dir(task, "sample.toml")
        if isfile(sample_toml)
            sample_info = from_toml(SamplingInfo, sample_toml)
            task.sample == sample_info || error("sample info mismatch")
        else
            to_toml(sample_toml, task.sample)
        end
        return task
    end
end

function task_dir(task::ChainTaskInfo, xs...)
    path = guarantee_dir(shape_dir(task.shape,
        string(task.uuid)
    ))
    return joinpath(path, xs...)
end

export TaskInfo
@option struct TaskInfo
    seed::UInt = rand(UInt)
    showprogress::Bool = false
    shape::ShapeInfo
    sample::SamplingInfo = SamplingInfo()
    temperature::Schedule = Schedule()
end

function ChainTaskInfo(task::TaskInfo, uuid::UUID = uuid1())
    return ChainTaskInfo(
        uuid,
        task.seed,
        task.showprogress,
        task.shape,
        task.sample,
        task.temperature
    )
end

function Base.show(io::IO, ::MIME"text/plain", options::Union{ChainTaskInfo, TaskInfo})
    GarishPrint.pprint_struct(io, options)
end

function guarantee_dir(path::String)
    isdir(path) || mkpath(path)
    return path
end

function temperatures(task::Union{ChainTaskInfo, TaskInfo})
    return temperatures(task.temperature)
end

function Configurations.to_dict(::Type{ChainTaskInfo}, x::UUID)
    return string(x)
end

function Configurations.from_dict(
        ::Type{<:ChainTaskInfo}, ::OptionField{:uuid}, ::Type{UUID}, x::String)
    return UUID(x)
end
