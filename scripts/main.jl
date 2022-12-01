using Random
using SimplexThreeGT
using Serialization
using SimplexThreeGT: mcmc, mcmc_threaded, nspins, cubes, faces, energy, mcmc_step!, local_energy

Ts = 10:-0.01:0.9
csm = CubicSpinMap(4, 8; nthreads=4)
# serialize("csm.jls", csm)
# csm = deserialize("csm.jls")

Es, Cvs = mcmc_threaded(
    csm, Ts;
    seed=1234,
    nsamples=10_000, nburns=10_000,
    nthrows=50, nthreads=8
)
