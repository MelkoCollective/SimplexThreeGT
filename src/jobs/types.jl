abstract type Info end

export StorageInfo
@option struct StorageInfo <: Info
    path::String
    tags::Vector{String}
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

export CellMapInfo
@option struct CellMapInfo <: Info
    shape::ShapeInfo
    # the p-cell <-> (p-1)-cell map
    # for gauge updates.
    gauge::Bool
    nthreads::Int
end

export SamplingInfo
@option struct SamplingInfo <: Info
    # resample needs this to reduce
    # correlation between chains.
    nburns::Int
    nthrows::Int
    nsamples::Int
    order::UpdateOrder
    gauge::Maybe{Gauge}
    observables::Vector{String}
end

export ResampleTask
@option struct ResampleTask <: Info
    seed::UInt
    uuid::UUID
    temperatures::Vector{Float64}
end

export ResampleInfo
@option struct ResampleInfo <: Info
    nrepeat::Int # number of times to repeat the resampling
    sample::SamplingInfo
    tasks::Vector{ResampleTask}
end

export AnnealingTask
@option struct AnnealingTask <: Info
    uuid::UUID # task uuid
    field::Float64
    resample::ResampleInfo
end

export FieldResample
@option struct FieldResample <: Info
    field::Float64
    resample::ResampleInfo
end

export AnnealingJob
@option struct AnnealingJob <: Info
    uuid::UUID
    cellmap::CellMapInfo
    storage::StorageInfo

    seed::UInt
    # Annealing do not produce
    # any observable data.
    nburns::Int
    order::UpdateOrder
    temperature::TOMLRange
    tasks::Vector{AnnealingTask}
end

export ResampleJob
@option struct ResampleJob <: Info
    uuid::UUID # previous job uuid
    seed::UInt # global seed to generate each resample chain
    storage::StorageInfo
    tasks::Vector{FieldResample}
end


@option struct AnnealingOptions <: Info
    uuid::UUID # task uuid
    seed::UInt

    cellmap::ShapeInfo
    storage::StorageInfo
    # Annealing do not produce
    # any observable data.
    nburns::Int
    order::UpdateOrder
    gauge::Maybe{Gauge}

    temperature::TOMLRange
    field::Float64
end

@option struct ResampleOptions <: Info
    seed::UInt # global seed to generate each resample chain
    uuid::UUID
    parent::UUID # previous job uuid
    cellmap::ShapeInfo
    storage::StorageInfo
    sample::SamplingInfo

    nrepeat::Int # number of times to repeat the resampling
    fields::Vector{Float64}
    temperatures::Vector{Float64}
end
