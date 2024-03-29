using Test
using Random: Xoshiro
using UUIDs: uuid1
using SimplexThreeGT.Homology: CellMap, nspins, cell_map
using SimplexThreeGT.MonteCarlo: MarkovChain, Observable, State,
    energy, cubic_energy, local_energy, rand_spins, energy_diff!

@testset "cubic_energy" begin
    spins = [1, 1, 1, -1, 1, 1, 1, 1]
    @test cubic_energy([1, 4, 5, 6, 7, 8], spins) == 1
    @test cubic_energy([1, 2, 3, 5, 6, 7], spins) == -1

    spins = (spins .+ 1) .÷ 2 .== 1
    @test cubic_energy([1, 4, 5, 6, 7, 8], spins) == 1
    @test cubic_energy([1, 2, 3, 5, 6, 7], spins) == -1
end # testset

@testset "energy: dims=$dims, L=$L" for dims in 2:3, L in 2:4
    cm = CellMap(dims, L, (1, 2))
    @test energy(cm, trues(nspins(cm)), 0.0) == -length(cm.p2p1)
    @test energy(cm, falses(nspins(cm)), 0.0) == -length(cm.p2p1)
    energy(cm, trues(nspins(cm)), 1.0) == -length(cm.p2p1) - nspins(cm)

    @testset "field = $field" for field in [0.0, 0.5, 1.0]
        cm = CellMap(dims, L, (dims-1, dims))
        spins = rand_spins(Xoshiro(1000), nspins(cm))
        old_E = energy(cm, spins, field)
        delta_E = energy_diff!(spins, cm, 1, field)
        new_E = energy(cm, spins, field)
        @test new_E - old_E == delta_E
    end
end # testset

cm = CellMap(4, 2, (2, 3))
energy(cm, trues(nspins(cm)), 0.1)
energy(cm, trues(nspins(cm)), 0.2)
energy(cm, trues(nspins(cm)), 0.3)
energy(cm, trues(nspins(cm)), 0.4)
energy(cm, trues(nspins(cm)), 0.5)
