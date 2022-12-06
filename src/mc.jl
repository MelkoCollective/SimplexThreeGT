function energy(csp::CubicSpinMap, spins::Vector{Int})
    return sum(values(csp.cube_to_spin)) do cube_spins
        return local_energy(cube_spins, spins)
    end
end

function energy(csp::CubicSpinMap, spins::BitVector)
    return sum(values(csp.cube_to_spin)) do cube_spins
        return local_energy(cube_spins, spins)
    end
end

function local_energy(cube_spins, spins::Vector{Int})
    return -prod(cube_spins) do j
        @inbounds spins[j]
    end
end

function local_energy(cube_spins, spins::BitVector)
    up_spins = sum(cube_spins) do j
        @inbounds spins[j]
    end
    return isodd(up_spins) ? 1 : -1
end

Base.@propagate_inbounds function flip_spin!(spins::Vector{Int}, idx::Int)
    spins[idx] = -spins[idx]
    return spins
end

Base.@propagate_inbounds function flip_spin!(spins::BitVector, idx::Int)
    spins[idx] = !spins[idx]
    return spins
end

function energy_diff(csp::CubicSpinMap, spins, spin_idx)
    effected_cubes = csp.spin_to_cube[spin_idx]
    E_old = -sum(effected_cubes) do cube_idx
        cube_spins = csp.cube_to_spin[cube_idx]
        local_energy(cube_spins, spins)
    end
    @inbounds flip_spin!(spins, spin_idx)
    E_new = -sum(effected_cubes) do cube_idx
        cube_spins = csp.cube_to_spin[cube_idx]
        local_energy(cube_spins, spins)
    end
    return E_new - E_old
end

function metropolis_accept(rng::AbstractRNG, delta_E, T)
    delta_E ≤ 0 && return true
    exp(-delta_E/T) > rand(rng) && return true
    return false
end

function mcmc_step!(rng::AbstractRNG, spins,
        csp::CubicSpinMap, T::Real, E::Real)
    spin_idx = rand(rng,1:length(spins))
    delta_E = energy_diff(csp, spins, spin_idx)  #flips spin
    if metropolis_accept(rng, delta_E, T)
        E += delta_E
    else
        @inbounds flip_spin!(spins, spin_idx) #flip the spin back
    end
    return E
end

function mcmc_loop(f, rng, csm, spins, T, E, niterations::Int)
    for i in 1:niterations
        E = mcmc_step!(rng, spins, csm, T, E)
        f(E)
    end
    return spins, E
end

function mcmc_estimate(rng::AbstractRNG, csm::CubicSpinMap, spins,
        T::Real, E::Real, nburns::Int, nsamples::Int, nthrows::Int)
    for _ in 1:nburns
        E = mcmc_step!(rng, spins, csm, T, E)
    end

    E2 = 0.0
    E_avg = 0.0
    for _ in 1:nsamples
        for _ in 1:nthrows
            E = mcmc_step!(rng, spins, csm, T, E)
        end
        E_avg += E
        E2 += E^2
    end
    Cv = E2/nsamples- (E_avg/nsamples)^2
    Cv = Cv/nspins(csm)/T^2
    E = E_avg/nsamples/nspins(csm)
    return E, Cv
end

function mcmc(csm::CubicSpinMap, Ts;
        seed::Int=1234,
        nburns::Int=1000,
        nsamples::Int=20_000,
        nthrows::Int=10,
        showprogress::Bool=false,
    )

    rng = MersenneTwister(seed)
    spins = rand(rng, (-1,1), nspins(csm))
    E = energy(csm, spins)
    Es = Vector{Float64}(undef, length(Ts))
    Cvs = Vector{Float64}(undef, length(Ts))
    if showprogress
        @progress name="mcmc $(Threads.threadid())" for (T_idx, T) in enumerate(Ts)
            E, Cv = mcmc_estimate(rng, csm, spins, T, E, nburns, nsamples, nthrows)
            Es[T_idx] = E; Cvs[T_idx] = Cv
        end
    else
        for (T_idx, T) in enumerate(Ts)
            E, Cv = mcmc_estimate(rng, csm, spins, T, E, nburns, nsamples, nthrows)
            Es[T_idx] = E; Cvs[T_idx] = Cv
        end
    end
    return Es, Cvs
end

function mcmc_threaded(csm::CubicSpinMap, Ts;
        seed::Int=1234,
        nburns::Int=10_000, nsamples::Int=200_000,
        nthrows::Int=50, nthreads::Int=Threads.nthreads()
    )

    Es = Vector{Vector{Float64}}(undef, nthreads)
    Cvs = Vector{Vector{Float64}}(undef, nthreads)

    @sync for thread_idx in 1:nthreads
        nsamples_thread = nsamples ÷ nthreads
        Threads.@spawn begin
            Es_, Cvs_ = mcmc(csm, Ts;
                seed=seed+thread_idx, nburns,
                nsamples=nsamples_thread, nthrows,
                showprogress=thread_idx in (1, 3, nthreads-2, nthreads),
            )
            Es[thread_idx] = Es_
            Cvs[thread_idx] = Cvs_
        end
    end
    Es = sum(Es); Cvs = sum(Cvs)
    return Es./nthreads, Cvs./nthreads
end
