module Exact

using LinearAlgebra
using ..Homology: CellMap, nspins
using ..MonteCarlo: MonteCarlo

function configs(cm::CellMap)
    return Iterators.map(
            Iterators.product((0:1 for _ in 1:nspins(cm))...)
        ) do config
        BitVector(config .== 1)
    end
end

function probabilities(cm::CellMap, T::Real, field::Real=0.0)
    beta = 1/T
    probs = map(configs(cm)) do config
        exp(-beta * MonteCarlo.energy(cm, config, field))
    end
    return normalize!(probs, 1)
end

function energy(cm::CellMap, T::Real, field::Real = 0.0)
    ps = probabilities(cm, T, field)
    return sum(zip(configs(cm), ps)) do (config, p)
        p * MonteCarlo.energy(cm, config, field)
    end
end

end # module
