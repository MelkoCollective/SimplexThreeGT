mutable struct Observable{Tag}
    value::Float64
    final::Bool
end

Observable(name::String) = Observable(Symbol(name))
Observable(name::Symbol) = Observable{name}(0.0, false)
obs_name(::Observable{Tag}) where Tag = Tag

function init!(obs::Observable)
    obs.value = 0.0
    obs.final = false
    return obs
end

function safe_collect!(ob::Observable, mcmc::SimplexMCMC)
    ob.final && error("Observable $(obs_name(ob)) already finalized")
    return collect!(ob, mcmc)
end

collect!(::Observable{T}, ::SimplexMCMC) where T = error("Observable $(T) not implemented")

function finalize!(ob::Observable, ::SimplexMCMC, nsamples::Int)
    ob.value /= nsamples
    ob.final = true
    return ob
end

obs_names(mcmc::SimplexMCMC) = map(obs_name, mcmc.obs)

function init!(mcmc::SimplexMCMC)
    for obs in mcmc.obs
        init!(obs)
    end
    return mcmc
end

function collect!(mcmc::SimplexMCMC)
    for obs in mcmc.obs
        safe_collect!(obs, mcmc)
    end
    return mcmc
end

function finalize!(mcmc::SimplexMCMC, nsamples::Int)
    for obs in mcmc.obs
        finalize!(obs, mcmc, nsamples)
    end
    return mcmc
end

function collect!(ob::Observable{:E}, mcmc::SimplexMCMC)
    ob.value += mcmc.state.energy
    return ob
end

function collect!(ob::Observable{Symbol("E^2")}, mcmc::SimplexMCMC)
    ob.value += mcmc.state.energy^2
    return ob
end

function collect!(ob::Observable{:M}, mcmc::SimplexMCMC)
    ob.value += sum_spins(mcmc.state.spins)
    return ob
end

function collect!(ob::Observable{Symbol("M^2")}, mcmc::SimplexMCMC)
    ob.value += sum_spins(mcmc.state.spins)^2
    return ob
end

function sum_spins(spins::BitVector)
    2 * sum(spins) - length(spins)
end

function sum_spins(spins::Vector{Int})
    sum(spins)
end
