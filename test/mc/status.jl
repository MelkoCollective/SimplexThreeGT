using Test
using Random: Xoshiro
using UUIDs: uuid1
using SimplexThreeGT.Homology: CellMap, nspins, cell_map
using SimplexThreeGT.MonteCarlo: MarkovChain, Observable, State,
    energy, system_energy, cubic_energy, local_energy

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

    cm = CellMap(dims, L, (dims-1, dims))
    mc = MarkovChain(
        Xoshiro(123),
        uuid1(),
        cm,
        nothing,
        State(
            trues(nspins(cm)),
            40.0, # temp
            energy(cm, trues(nspins(cm)), 0.0),  # energy
            0.0, # field
        ),
        (Observable(:E), ),
    )

    @test energy(mc) == energy(cm, trues(nspins(cm)), 0.0) == mc.state.energy
    @test local_energy(mc, 1) == -2 # this only depends on dims, and always is -2
end
