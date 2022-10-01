module SimplexThreeGT

using Random: AbstractRNG
export Hypercube, cube_labels

include("hypercube.jl")
include("mc.jl")

end
