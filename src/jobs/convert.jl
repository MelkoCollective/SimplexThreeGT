function Configurations.from_dict(::Type{<:Info}, ::Type{TOMLRange}, x::AbstractDict{String})
    TOMLRange(x["start"], x["stop"], x["step"])
end

function Configurations.to_dict(::Type{<:Info}, x::TOMLRange)
    Dict("start" => x.start, "stop" => x.stop, "step" => x.step)
end

function Configurations.from_dict(::Type{<:Info}, ::Type{UpdateOrder}, x::String)
    if x == "random"
        return Random
    elseif x == "typewriter"
        return TypeWriter
    elseif x == "checkerboard"
        return CheckerBoard
    else
        throw(ArgumentError("unknown update order: $x"))
    end
end

function Configurations.to_dict(::Type{<:Info}, x::UpdateOrder)
    if x == Random
        return "random"
    elseif x == TypeWriter
        return "typewriter"
    elseif x == CheckerBoard
        return "checkerboard"
    else
        throw(ArgumentError("unknown update order: $x"))
    end
end

function Configurations.from_dict(::Type{<:Info}, ::Type{UUID}, x::String)
    UUID(x)
end

function Configurations.to_dict(::Type{<:Info}, x::UUID)
    string(x)
end
