# TODOs:
# - [ ] acceptance rate
struct TOMLRange <: AbstractRange{Float64}
    start::Float64
    stop::Float64
    step::Float64
    range::StepRangeLen{Float64, Base.TwicePrecision{Float64}, Base.TwicePrecision{Float64}, Int64}

    function TOMLRange(start, stop, step)
        new(start, stop, step, start:step:stop)
    end
end

Base.length(r::TOMLRange) = length(r.range)
Base.first(r::TOMLRange) = first(r.range)
Base.last(r::TOMLRange) = last(r.range)
Base.step(r::TOMLRange) = step(r.range)
Base.eltype(r::TOMLRange) = eltype(r.range)
Base.iterate(r::TOMLRange) = iterate(r.range)
Base.iterate(r::TOMLRange, state) = iterate(r.range, state)
Base.convert(::Type{TOMLRange}, r::AbstractRange) = TOMLRange(first(r), last(r), step(r))

# disambiguate due to AbstractRange <: AbstractVector
function Configurations.from_dict(
    ::Type{OptionType}, of::OptionField, ::Type{T}, x::AbstractDict{String}
) where {OptionType,T<:TOMLRange}
    TOMLRange(x["start"], x["stop"], x["step"])
end
