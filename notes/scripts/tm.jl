# transfer matrix of p-cell

# E(σ₁, σ₂, ..., σₖ)

# plaquette
# 1 => e^β
# -1 => e^{-β}
T = zeros(2, 2, 2, 2)
for s in Iterators.product(ntuple(_->[-1, 1], 4)...)
    T[((s .+ 1) .÷2 .+ 1)...] = prod(s)
end

using LinearAlgebra
# using SymbolicUtils
# @syms a::Real b::Real
using SymEngine
@vars a b λ

sT = Array{Num}(undef, 2, 2, 2, 2)
for idx in eachindex(T)
    if T[idx] > 0
        sT[idx] = a
    else
        sT[idx] = b
    end
end

det(reshape(sT, 4, 4) - λ * I)