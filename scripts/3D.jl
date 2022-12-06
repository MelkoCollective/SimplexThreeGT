using Random: MersenneTwister
using SimplexThreeGT: CubicFaceSites, mcmc, nspins, energy, local_energy

E2 = 0.0
E_avg = 0.0
nburns = 10_000
nsamples = 200_000
cfs = CubicFaceSites(4, 4, 4, 4, 4, 4)
rng = MersenneTwister(1334)
spins = rand(rng,(-1, 1), nspins(cfs))
E = energy(cfs, spins)
local_energy(cfs, 1, spins)
# @show sum(spins)
Es, Cvs = mcmc(rng, cfs, 10:-0.2:0.2; nburns, nsamples)

findmax(Cvs)
(10:-0.2:0.2)[46]

using DelimitedFiles
writedlm("Cvs.txt", reverse(Cvs))
