struct MinPlus{T <: Real} <: Number
    value::T
end

Base.:+(x::MinPlus, y::MinPlus) = MinPlus(min(x.value, y.value))
Base.:*(x::MinPlus, y::MinPlus) = MinPlus(x.value + y.value)

Base.show(io::IO, x::MinPlus) = print(io, x.value, "ₘᵢₙ")

macro mp_str(s::String)
    return :(MinPlus($(Meta.parse(s))))
end

MinPlus(2.0) + MinPlus(3.2) * MinPlus(2.1)
mp"2.0" + mp"3.2" * mp"2.1"

A = MinPlus.(rand(2, 2))

A[1, 1] = Inf
