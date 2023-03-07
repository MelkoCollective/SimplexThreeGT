function init!(obs::Observable)
    obs.value = 0.0
    obs.final = false
    return obs
end

function safe_collect!(ob::Observable{Name}, mc::MarkovChain) where {Name}
    ob.final && error("Observable $Name already finalized")
    return collect!(ob, mc)
end

collect!(::Observable{T}, ::MarkovChain) where T = error("Observable $(T) not implemented")

function finalize!(ob::Observable, ::MarkovChain, nsamples::Int)
    ob.value /= nsamples
    ob.final = true
    return ob
end

function init!(mc::MarkovChain)
    for obs in mc.obs
        init!(obs)
    end
    return mc
end

function collect!(mc::MarkovChain)
    for obs in mc.obs
        safe_collect!(obs, mc)
    end
    return mc
end

function finalize!(mc::MarkovChain, nsamples::Int)
    for obs in mc.obs
        finalize!(obs, mc, nsamples)
    end
    return mc
end

function collect!(ob::Observable{:E}, mc::MarkovChain)
    ob.value += mc.state.energy
    return ob
end

function collect!(ob::Observable{Symbol("E^2")}, mc::MarkovChain)
    ob.value += mc.state.energy^2
    return ob
end

function collect!(ob::Observable{:M}, mc::MarkovChain)
    ob.value += sum_spins(mc.state.spins)
    return ob
end

function collect!(ob::Observable{Symbol("M^2")}, mc::MarkovChain)
    ob.value += sum_spins(mc.state.spins)^2
    return ob
end
