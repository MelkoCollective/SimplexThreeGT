"""
    $(SIGNATURES)

Return the energy of a given cube.

```math
E = -\\prod_{face \\in \\text{cube}} \\sigma_{face}
```
"""
function cubic_energy end

function cubic_energy(cube_spin_ids, spins::Vector{Int})
    ret = -prod(cube_spin_ids) do j
        @inbounds spins[j]
    end
    return Float64(ret)
end

function cubic_energy(cube_spin_ids, spins::BitVector)
    up_spins = sum(cube_spin_ids) do j
        @inbounds spins[j]
    end
    return isodd(up_spins) ? 1.0 : -1.0
end

"""
    $(SIGNATURES)

Return the energy of the current state of the Markov chain.

```math
E = -\\sum_{cube} \\prod_{face \\in \\text{cube}} \\sigma_{face} - \\lambda \\sum_{face} \\sigma_{face}
```
"""
function energy(mc::MarkovChain)
    return energy(mc.cm, mc.state.spins, mc.state.field)
end

"""
    $(SIGNATURES)

Return the energy of the system. The field is the external magnetic field.
"""
function energy(cm::CellMap, spins, field::Real)
    energy(cm, spins) - field * sum_spins(spins)
end


"""
    $(SIGNATURES)

Return the energy of the system.

```math
E = -\\sum_{cube} \\prod_{face \\in \\text{cube}} \\sigma_{face}
```
"""
function energy(cm::CellMap, spins)
    return sum(values(cm.p2p1)) do cube_spin_ids
        return cubic_energy(cube_spin_ids, spins)
    end
end

"""
    $(SIGNATURES)

Return the local energy of the current state of the Markov chain.

```math
E = -\\prod_{f \\in \\text{cube(face)}} \\sigma_{f}
```

where `cube` is the cube attached to provided `face`.
"""
@inline function local_energy(mc::MarkovChain, effected_cubes)
    local_energy(mc.cm, mc.state.spins, effected_cubes)
end

@inline function local_energy(cm::CellMap, spins, effected_cubes)
    return sum(effected_cubes) do cube_idx
        cube_spins = cm.p2p1[cube_idx]
        cubic_energy(cube_spins, spins)
    end
end

"""
    $(SIGNATURES)

Return the energy difference of flipping the spin of the given face.
"""
function energy_diff!(spins, cm::CellMap, face::Int, field::Real)
    delta = energy_diff!(spins, cm, face)
    iszero(field) && return delta
    if spins[face] # new spin is up
        return delta - 2 * field
    else
        return delta + 2 * field
    end
end

"""
    $(SIGNATURES)

Return the energy difference of flipping the spin of the given face.
"""
function energy_diff!(spins, cm::CellMap, face::Int)
    effected_cubes = cm.p1p2[face]
    E_old = local_energy(cm, spins, effected_cubes)
    @inbounds flip_spin!(spins, face)
    E_new = local_energy(cm, spins, effected_cubes)
    return E_new - E_old
end
