using Test
using SimplexThreeGT
using SimplexThreeGT: energy, local_energy, gauge_flip!, cell_topology

@testset "energy D=2" begin
    cm = CellMap(2, 3, (1, 2))
    gauge_cm = CellMap(2, 3, (0, 1))
    spins = falses(18)
    @test energy(cm, spins) == -9
    gauge_flip!(spins, gauge_cm, 1)
    @test energy(cm, spins) == -9
end # energy

@testset "energy D=3" begin
    cm = CellMap(3, 3, (2, 3))
    gauge_cm = CellMap(3, 3, (1, 2))
    spins = falses(nspins(cm))
    @test energy(cm, spins) == -27
    gauge_flip!(spins, gauge_cm, 1)
    @test energy(cm, spins) == -27
end
