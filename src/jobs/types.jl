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

export SamplingInfo
@option struct SamplingInfo <: Info
    # resample needs this to reduce
    # correlation between chains.
    nburns::Int
    order::UpdateOrder
    gauge::Maybe{Gauge}
end


export AnnealingJob
@option struct AnnealingJob <: Info
    uuid::UUID
    njobs::Int

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
@option struct ResampleJob <: Info
    uuid::UUID
    parent::UUID # previous job uuid
    njobs::Int
    shape::ShapeInfo
    storage::StorageInfo
    sample::ResampleInfo
    fields::TOMLRange
    temperatures::TOMLRange
end

export CellMapOption
@option struct CellMapOption <: Info
    shape::ShapeInfo
    gauge::Bool
end

export AnnealingOptions
@option struct AnnealingOptions <: Info
    uuid::UUID # task uuid
    seed::UInt

    shape::ShapeInfo
    storage::StorageInfo
    sample::SamplingInfo

    temperatures::TOMLRange
    fields::Vector{Float64}
end

export ResampleMatrix
@option struct ResampleMatrix
    fields::Vector{Float64}
    temperatures::Vector{Float64}
end

export ResampleOptions
@option struct ResampleOptions <: Info
    seed::UInt # global seed to generate each resample chain
    uuid::UUID
    parent::UUID # previous job uuid
    shape::ShapeInfo
    storage::StorageInfo
    sample::ResampleInfo

    matrix::ResampleMatrix
end
