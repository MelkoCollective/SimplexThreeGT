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
    mc.state.nsteps += 1
    if delta_E ≤ 0 || exp(-delta_E/mc.state.temp) > rand(mc.rng)
        mc.state.accept += 1
        return true
    else
        return false
    end
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

function typewriter_step!(mc::MarkovChain)
    for face_idx in 1:nspins(mc.cm)
        delta_E = energy_diff!(mc, face_idx) #flips spin
        if metropolis_accept!(mc, delta_E)
            mc.state.energy += delta_E
        else
            @inbounds flip_spin!(mc.state.spins, face_idx) #flip the spin back
        end
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

"""
    $(SIGNATURES)

Wolff single cluster update for p-cell model.

This is a single cluster update for the p-cell model. The cluster is defined by the
following algorithm:

1. Choose a random p-cell `f_0`.
2. Iterate the (p+1)-cell attached to `f_0`, if the rest spin of the
    (p+1)-cell is the same as `f_0`, add it to the cluster with probability
    `1 - exp(-2/T)` and name it `c_i`.
3. Iterate the neighbors of `c_i` as `c_j`, if spins of `c_j` is the same
    as `f_0`, add it to the cluster with probability `1 - exp(-2/T)`.
4. Repeat step 3 until no more neighbors can be added to the cluster.

Note this update is not ergodic, need to combine with other
updates to make it ergodic.
"""
function wolff_step!(mc::MarkovChain)
    error("not implemented")
end
