function sum_spins(spins::BitVector)
    2 * sum(spins) - length(spins)
end

function sum_spins(spins::Vector{Int})
    sum(spins)
end

function rand_spins(rng, nspins)
    return BitVector(rand(rng, Bool, nspins))
end
