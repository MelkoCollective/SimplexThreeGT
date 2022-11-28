using Plots
using Random
using SimplexThreeGT
using Combinatorics
using SimplexThreeGT: nspins, cubes, faces

Ts = 10:-0.1:0.2
Es, Cvs = mcmc(MersenneTwister(1234), CubicSpinMap(4, 8), Ts)
# d=6 T_c = 2.2693
plot(Ts, Cvs; xlabel="T", ylabel="Cv", title="Cv vs T")
cubes(6, 6)
faces(6, 6)


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