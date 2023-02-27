"""
    $(SIGNATURES)

Sum the spins from a vector of spins.
"""
sum_spins(spins::AbstractVector{Int}) = sum(spins)

function sum_spins(spins::BitVector)
    2 * sum(spins) - length(spins)
end

"""
    $(SIGNATURES)

Return a random spin configuration.
"""
function rand_spins(rng, nspins)
    return BitVector(rand(rng, Bool, nspins))
end
