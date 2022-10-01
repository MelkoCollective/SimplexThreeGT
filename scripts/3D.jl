using Random: MersenneTwister
using SimplexThreeGT: mcmc

E2 = 0.0
E_avg = 0.0
nburn = 10_000
nsamples = 200_000
cfs = CubicFaceSites(2, 2, 2)
rng = MersenneTwister(123)
mcmc(rng, cfs, 10:-0.2:0.2; nburns, nsamples)
Cv = E2/nsamples- (E_avg/nsamples)^2
println(T," ",E_avg/nsamples/nspins(cfs)," ",Cv/nspins(cfs)/T/T)
