module CLI

using Comonicon
using Configurations: from_toml, to_dict, from_dict
using SimplexThreeGT.Jobs
using SimplexThreeGT.Homology: Homology
using SimplexThreeGT.MonteCarlo: MonteCarlo

include("emit.jl")
include("submit.jl")
include("crunch.jl")
include("main.jl")

"""
the Lattice Gerbe Theory simulator
"""
@main

end # module
