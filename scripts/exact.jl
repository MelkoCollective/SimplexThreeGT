# generate exact test energies
using ProgressLogging
using SimplexThreeGT: SimplexThreeGT
using SimplexThreeGT.Exact
using SimplexThreeGT.Homology: CellMap, nspins

@static if !@isdefined(VSCodeServer)
    using TerminalLoggers
    using Logging: global_logger
    global_logger(TerminalLogger())
end

cm = CellMap(3, 2, (2, 3))
dir = pkgdir(SimplexThreeGT, "test", "exact")
ispath(dir) || mkpath(dir)
open(joinpath(dir, "energy.csv"), "w") do io
    println(io, "h,T,E")
    @progress "energy" for T in 0.1:0.1:1.0, field in 0.0:0.1:1.0
        E = Exact.energy(cm, T, field)
        println(io, "$(field),$(T),$(E)")
        flush(io)
    end
end # open
