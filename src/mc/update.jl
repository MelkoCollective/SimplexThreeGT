Base.@propagate_inbounds function flip_spin!(spins::Vector{Int}, idx::Int)
    spins[idx] = -spins[idx]
    return spins
end

Base.@propagate_inbounds function flip_spin!(spins::BitVector, idx::Int)
    spins[idx] = !spins[idx]
    return spins
end

Base.@propagate_inbounds function gauge_flip!(spins, cm::CellMap, edge_idx::Int)
    for attach_spin in cm.p1p2[edge_idx]
        flip_spin!(spins, attach_spin)
    end
    return spins
end

energy_diff!(mc::MarkovChain, face::Int) = energy_diff!(mc.state.spins, mc.cm, face, mc.state.field)

function metropolis_accept!(mc::MarkovChain, delta_E)
    delta_E ≤ 0 && return true
    exp(-delta_E/mc.state.temp) > rand(mc.rng) && return true
    return false
end

function mcmc_step!(mc::MarkovChain)
    face_idx = rand(mc.rng, 1:nspins(mc.cm))
    delta_E = energy_diff!(mc, face_idx) #flips spin
    if metropolis_accept!(mc, delta_E)
        mc.state.energy += delta_E
    else
        @inbounds flip_spin!(mc.state.spins, face_idx) #flip the spin back
    end
    return mc
end

function gauge_step!(mc::MarkovChain)
    edge_idx = rand(mc.rng, 1:length(mc.gauge.p1p2))
    delta_E = sum(mc.cm.p1p2[edge_idx]) do spin_idx
        energy_diff!(mc, spin_idx) #flips spin
    end

    if metropolis_accept!(mc, delta_E)
        mc.state.energy += delta_E
    else
        @inbounds gauge_flip!(mc.state.spins, mc.cm, edge_idx) #flip the spin back
    end
    return mc
end
