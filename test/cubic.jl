using Plots
using Random
using SimplexThreeGT
using Combinatorics
using Serialization
using SimplexThreeGT: mcmc, mcmc_threaded, nspins, cubes, faces, energy, mcmc_step!, local_energy
using BenchmarkTools

Ts = 10:-0.01:0.01
csm = CubicSpinMap(4, 6; nthreads=4)
# serialize("csm.jls", csm)
# csm = deserialize("csm.jls")

Es, Cvs = mcmc_threaded(
    csm, Ts;
    seed=1234,
    nsamples=100_000, nburns=10_000,
    nthrows=50, nthreads=8
)

# d=6 T_c = 2.2693
plot(Ts, Cvs;
    xlabel="T", ylabel="Cv", title="Cv vs T",
    xticks=0:0.5:10
)

_, idx = findmax(Cvs)
Ts[idx]


csp = CubicSpinMap(6, 6)
rng = MersenneTwister(1234)
spins = rand(rng,(-1, 1), nspins(csp))
E = energy(csp, spins)
E = mcmc_step!(rng, spins, csp, T, E)
coords = (1, 2, 3)
cubes(coords, (4, 5, 6), 6)
length(combinations(1:6, 3))
Iterators.product(ntuple(_->0:5, 3)...)|>length
216 * 20 * 216