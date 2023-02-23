mutable struct Observable{Tag}
    value::Float64
end

Observable(name::String) = Observable(Symbol(name))
Observable(name::Symbol) = Observable{name}(0.0)
obs_name(::Observable{Tag}) where Tag = Tag
init!(obs::Observable) = (obs.value = 0.0; return obs)
collect!(::Observable{T}, ::SimplexMCMC) where T = error("Observable $(T) not implemented")

obs_names(mcmc::SimplexMCMC) = map(obs_name, mcmc.obs)

function init!(mcmc::SimplexMCMC)
    for obs in mcmc.obs
        init!(obs)
    end
    return mcmc
end

function collect!(mcmc::SimplexMCMC)
    for obs in mcmc.obs
        collect!(obs, mcmc)
    end
    return mcmc
end

function finalize!(mcmc::SimplexMCMC, nsamples::Int)
    for obs in mcmc.obs
        obs.value /= nsamples
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

