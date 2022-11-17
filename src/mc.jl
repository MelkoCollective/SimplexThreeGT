function energy(cfs::CubicFaceSites, spins::AbstractVector)
    return sum(axes(cfs.labels, 1)) do i
        -prod(1:ndims(cfs.hypercube)) do j
            spins[cfs.labels[i, j]]
        end
    end    
end

Base.@propagate_inbounds function local_energy(cfs::CubicFaceSites, cube_idx::Int, spins)
    @boundscheck cube_idx ≤ size(cfs.labels, 1)
    return prod(1:ndims(cfs.hypercube)) do j
        spins[cfs.labels[cube_idx, j]]
    end
end

function energy_diff(cfs::CubicFaceSites, spins, spin_idx)
    cube_1 = cfs.inverse[spin_idx, 1]
    cube_2 = cfs.inverse[spin_idx, 2]

    E_old = -local_energy(cfs, cube_1, spins) -
        local_energy(cfs, cube_2, spins)
    spins[spin_idx] = -spins[spin_idx]
    E_new = -local_energy(cfs, cube_1, spins) -
        local_energy(cfs, cube_2, spins)
    return E_new - E_old
end

function metropolis_accept(rng::AbstractRNG, delta_E, T)
    delta_E ≤ 0 && return true
    exp(-delta_E/T) > rand(rng) && return true
    return false    
end

function mcmc_step!(rng::AbstractRNG, spins, cfs::CubicFaceSites, T::Real, E::Real)
    spin_idx = rand(rng,1:nspins(cfs))
    delta_E = energy_diff(cfs, spins, spin_idx)  #flips spin
    if metropolis_accept(rng, delta_E, T)
        E += delta_E
    else
        spins[spin_idx] = -spins[spin_idx]  #flip the spin back
    end
    return E
end

function mcmc(rng::AbstractRNG, cfs::CubicFaceSites, Ts; nburns::Int=10_000, nsamples::Int=200_000)
    spins = rand(rng,(-1, 1), nspins(cfs))
    E = energy(cfs, spins)
    Es = Float64[]
    Cvs = Float64[]
    for T in Ts
        #Equilibriate
        for _ in 1:nburns
            E = mcmc_step!(rng, spins, cfs, T, E)
        end #Equilibrate

        E2 = 0.0
        E_avg = 0.0
        for _ in 1:nsamples
            E = mcmc_step!(rng, spins, cfs, T, E)
            E_avg += E
            E2 += E^2
        end
        Cv = E2/nsamples- (E_avg/nsamples)^2
        push!(Es, E_avg/nsamples/nspins(cfs))
        push!(Cvs, Cv/nspins(cfs)/T/T)
        println(T," ",E_avg/nsamples/nspins(cfs)," ",Cv/nspins(cfs)/T/T)
    end
    return Es, Cvs
end
