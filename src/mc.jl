function energy(csp::CubicSpinMap, spins::Vector{Int})
    return sum(values(csp.cube_to_spin)) do cube_spins
        -prod(cube_spins) do j
            @inbounds spins[j]
        end
    end
end

Base.@propagate_inbounds function local_energy(csp::CubicSpinMap, cube_idx::Int, spins::Vector{Int})
    @boundscheck cube_idx ≤ length(csp.cube_to_spin)
    cube_spins = csp.cube_to_spin[cube_idx]
    return -prod(cube_spins) do j
        @inbounds spins[j]
    end
end

function energy_diff(csp::CubicSpinMap, spins, spin_idx)
    effected_cubes = csp.spin_to_cube[spin_idx]
    E_old = -sum(effected_cubes) do cube_idx
        @inbounds local_energy(csp, cube_idx, spins)
    end
    spins[spin_idx] = -spins[spin_idx]

    E_new = -sum(effected_cubes) do cube_idx
        @inbounds local_energy(csp, cube_idx, spins)
    end
    return E_new - E_old
end

function metropolis_accept(rng::AbstractRNG, delta_E, T)
    delta_E ≤ 0 && return true
    exp(-delta_E/T) > rand(rng) && return true
    return false
end

function mcmc_step!(rng::AbstractRNG, spins::Vector{Int},
        csp::CubicSpinMap, T::Real, E::Real)
    spin_idx = rand(rng,1:length(spins))
    delta_E = energy_diff(csp, spins, spin_idx)  #flips spin
    if metropolis_accept(rng, delta_E, T)
        E += delta_E
    else
        @inbounds spins[spin_idx] = -spins[spin_idx]  #flip the spin back
    end
    return E
end

function mcmc(rng::AbstractRNG, csp::CubicSpinMap, Ts; nburns::Int=10_000, nsamples::Int=200_000)
    spins = rand(rng,(-1, 1), nspins(csp))
    E = energy(csp, spins)
    Es = Float64[]
    Cvs = Float64[]
    for T in Ts
        #Equilibriate
        for _ in 1:nburns
            E = mcmc_step!(rng, spins, csp, T, E)
        end #Equilibrate

        E2 = 0.0
        E_avg = 0.0
        for _ in 1:nsamples
            E = mcmc_step!(rng, spins, csp, T, E)
            E_avg += E
            E2 += E^2
        end
        Cv = E2/nsamples- (E_avg/nsamples)^2
        push!(Es, E_avg/nsamples/nspins(csp))
        push!(Cvs, Cv/nspins(csp)/T/T)
        println(T," ",E_avg/nsamples/nspins(csp)," ",Cv/nspins(csp)/T/T)
    end
    return Es, Cvs
end
