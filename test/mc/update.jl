using Test
using SimplexThreeGT.Spec
using SimplexThreeGT.MonteCarlo: MarkovChain, flip_spin!, energy_diff!, metropolis_accept!, mcmc_step!, gauge_step!

@testset "flip_spin(::Vector{Int}, $i)" for i in 1:10
    spins = rand((-1, 1), 10)
    @test flip_spin!(copy(spins), i)[i] == -spins[i]
end

@testset "flip_spin(::BitVector, $i)" for i in 1:10
    spins = BitVector(rand(Bool, 10))
    @test flip_spin!(copy(spins), i)[i] == !spins[i]
end
