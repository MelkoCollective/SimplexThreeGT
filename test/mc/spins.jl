using Test
using Random: Xoshiro
using SimplexThreeGT
using SimplexThreeGT.MonteCarlo: sum_spins, rand_spins

@testset "sum_spins" begin
    sum_spins(ones(Int, 10)) == 10
    sum_spins(trues(10)) == 10

    sum_spins(-ones(Int, 10)) == -10
    sum_spins(falses(10)) == -10
end # testset

@testset "rand_spins" begin
    spins = rand_spins(Xoshiro(123), 10)
    @test length(spins) == 10
end
