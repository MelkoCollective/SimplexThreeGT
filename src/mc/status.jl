"""
    cubic_energy(cube_spin_ids, spins)

Return the energy of a given cube.

```math
E = -\\prod_{face \\in \\text{cube}} \\sigma_{face}
```
"""
function cubic_energy end

function cubic_energy(cube_spin_ids, spins::Vector{Int})
    return -prod(cube_spin_ids) do j
        @inbounds spins[j]
    end
end

function cubic_energy(cube_spin_ids, spins::BitVector)
    up_spins = sum(cube_spin_ids) do j
        @inbounds spins[j]
    end
    return isodd(up_spins) ? 1 : -1
end

"""
    energy(mc::MarkovChain)

Return the energy of the current state of the Markov chain.

```math
E = -\\sum_{cube} \\prod_{face \\in \\text{cube}} \\sigma_{face} - \\lambda \\sum_{face} \\sigma_{face}
```
"""
function energy(mc::MarkovChain)
    return energy(mc.cm, mc.state.spins, mc.state.field)
end

"""
    energy(cm::CellMap, spins, field::Real)

Return the energy of the system. The field is the external magnetic field.
"""
function energy(cm::CellMap, spins, field::Real)
    system_energy(cm, spins) - field * sum_spins(spins)
end

"""
    system_energy(cm::CellMap, spins)

Return the energy of the system.

```math
E = -\\sum_{cube} \\prod_{face \\in \\text{cube}} \\sigma_{face}
```
"""
function system_energy(cm::CellMap, spins)
    return sum(values(cm.p2p1)) do cube_spin_ids
        return cubic_energy(cube_spin_ids, spins)
    end
end

"""
    local_energy(mc::MarkovChain, face::Int, effected_cubes = mcmc.cm.p1p2[face])

Return the local energy of the current state of the Markov chain.

```math
E = -\\prod_{f \\in \\text{cube(face)}} \\sigma_{f} - \\lambda \\sigma_{face}
```

where `cube` is the cube attached to provided `face`.
"""
@inline function local_energy(mc::MarkovChain, face::Int, effected_cubes = mc.cm.p1p2[face])
    E = sum(effected_cubes) do cube_idx
        cube_spins = mc.cm.p2p1[cube_idx]
        cubic_energy(cube_spins, mc.state.spins)
    end
    return E - mc.state.field * mc.state.spins[face]
end
