abstract type Info end

export StorageInfo
@option struct StorageInfo <: Info
    path::String
    tags::Vector{String}
end

function StorageInfo(path::String, tags::String)
    return StorageInfo(
        path,
        isempty(tags) ? String[] : split(tags, ',')
    )
end

export ShapeInfo
@option struct ShapeInfo <: Info
    ndims::Int
    size::Int
    p::Int
end

export Gauge
@option struct Gauge <: Info
    steps::Int
end

export UpdateOrder, Random, TypeWriter, CheckerBoard
@enum UpdateOrder begin
    Random
    TypeWriter
    CheckerBoard
end

export SamplingInfo
@option struct SamplingInfo <: Info
    # resample needs this to reduce
    # correlation between chains.
    nburns::Int
    order::UpdateOrder
    gauge::Maybe{Gauge}
end

abstract type Job <: Info end

export AnnealingJob
@option struct AnnealingJob <: Job
    uuid::UUID = uuid1()
    njobs::Int
    walltime::String = "1-00:00:00" # slurm walltime default 1 day

    shape::ShapeInfo
    storage::StorageInfo
    # Annealing do not produce
    # any observable data.
    sample::SamplingInfo
    temperatures::TOMLRange
    fields::TOMLRange
end

export ResampleInfo
@option struct ResampleInfo <: Info
    nrepeat::Int # number of times to repeat the resampling
    nthrows::Int
    nsamples::Int
    option::SamplingInfo
    observables::Vector{String}
end

export ResampleJob
@option struct ResampleJob <: Job
    uuid::UUID = uuid1()
    parent::UUID # previous job uuid
    njobs::Int
    walltime::String = "1-00:00:00" # slurm walltime default 1 day
    shape::ShapeInfo
    storage::StorageInfo
    sample::ResampleInfo
    fields::TOMLRange
    temperatures::TOMLRange
end

# AnnealingJob + ResampleJob
export SimulationJob
@option struct SimulationJob <: Job
    uuid::UUID = uuid1() # task uuid
    seed::UInt
    njobs::Int # number of resample jobs to run
    walltime::String = "1-00:00:00" # slurm walltime default 1 day

    shape::ShapeInfo
    storage::StorageInfo
    sample::ResampleInfo

    temperatures::TOMLRange
    fields::TOMLRange
end

function AnnealingJob(job::SimulationJob)
    AnnealingJob(;
        # use the same uuid
        # because it's generated from the
        # simulation job
        job.uuid,
        job.njobs,
        job.walltime,
        job.shape,
        job.storage,
        sample=job.sample.option,
        job.temperatures,
        job.fields,
    )
end

function ResampleJob(job::SimulationJob)
    ResampleJob(;
        # use the same uuid
        # because it's generated from the
        # simulation job
        job.uuid,
        parent = job.uuid,
        job.njobs,
        job.walltime,
        job.shape,
        job.storage,
        job.sample,
        job.fields,
        job.temperatures,
    )
end

abstract type SimulationTask <: Info end

export CellMapOptions
@option struct CellMapOptions <: SimulationTask
    storage::StorageInfo
    shape::ShapeInfo
    gauge::Bool
end

# this is main for having field after temp
@option struct FieldList
    list::Vector{Float64}
end

Base.length(f::FieldList) = length(f.list)
Base.eltype(f::FieldList) = eltype(f.list)
Base.getindex(f::FieldList, i::Int) = f.list[i]
Base.iterate(f::FieldList, state::Int = 1) = iterate(f.list, state)
Base.convert(::Type{FieldList}, f::Vector{Float64}) = FieldList(f)
Base.convert(::Type{FieldList}, f::TOMLRange) = FieldList(collect(f))
Base.convert(::Type{FieldList}, f::Float64) = FieldList([f])
Base.convert(::Type{Vector{T}}, f::FieldList) where {T} = convert(Vector{T}, f.list)

export AnnealingOptions
@option struct AnnealingOptions <: SimulationTask
    job::UUID # job uuid
    uuid::UUID # task uuid
    seed::UInt

    shape::ShapeInfo
    storage::StorageInfo
    sample::SamplingInfo

    temperatures::TOMLRange
    fields::FieldList
end

export ResampleOptions
@option struct ResampleOptions <: SimulationTask
    seed::UInt # global seed to generate each resample chain
    uuid::UUID
    parent::UUID # previous job uuid
    shape::ShapeInfo
    storage::StorageInfo
    sample::ResampleInfo

    fields::TOMLRange
    temperatures::TOMLRange
end
