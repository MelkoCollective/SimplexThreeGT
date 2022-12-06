using OMEinsum

# exp(beta * σ₁σ₂σ₃σ₄σ₅σ₆)
function transfer_tensor(::Type{Eltype}, ndims::Int, beta::Real, spins) where {Eltype}
    d = length(spins)
    dims = ntuple(_->d, ndims)
    T = Array{Eltype}(undef, dims)
    for indices in CartesianIndices(dims)
        E = beta * mapreduce(*, Tuple(indices)) do idx
            spins[idx]
        end
        T[indices] = exp(E)
    end
    return T
end

transfer_tensor(ndims::Int, beta=1.0, spins=(-1, 1)) = transfer_tensor(Float64, ndims, beta, spins)

T = transfer_tensor(4)

ein"ijkl,mnpj->imnpkl"(T, T)
@ein C[1,5,6,7,3,4] := T[1,2,3,4] * T[5,6,7,2]

function contract_row(n::Int, T)
    if n == 2
        LHS = reshape(permutedims(T, (1, 2, 4, 3)), 8, 2)
    else
        LHS = contract_row(n-1, T)
    end
    L = LHS * reshape(T, 2, 8)
    # move right most leg to next leg to be contracted
    L = permutedims(reshape(L, (2^(2n-1), 2, 2, 2)), (1, 2, 4, 3))
    return reshape(L, 2^(2n+1), 2)
end

reshape(contract_row(10, T), 2, 2^(20), 2)
