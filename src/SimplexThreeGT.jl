module SimplexThreeGT

using Random: AbstractRNG
using Combinatorics
using ProgressLogging
export CubicSpinMap, mcmc

include("cells.jl")
include("mc.jl")

end
