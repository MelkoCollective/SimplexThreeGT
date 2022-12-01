using Random
using Comonicon
using Logging: global_logger
using TerminalLoggers: TerminalLogger
using SimplexThreeGT
using Serialization
using SimplexThreeGT: mcmc, mcmc_threaded, nspins, cubes, faces, energy, mcmc_step!, local_energy

if !@isdefined(VSCodeServer)
    global_logger(TerminalLogger())
end

data_dir(xs...) = pkgdir(SimplexThreeGT, "data", xs...)

@main function main(ndims::Int, L::Int;
        nthreads::Int=Threads.nthreads(),
        seed::Int=1234,
        nsamples::Int=10_000,
        nburns::Int=10_000,
        nthrows::Int=50,
    )
    isdir(data_dir("samples")) || mkpath(data_dir("samples"))
    isdir(data_dir("cubes")) || mkpath(data_dir("cubes"))

    csm_file = data_dir("cubes", "$ndims-$L.jls")
    if isfile(csm_file)
        csm = deserialize(csm_file)
    else
        csm = CubicSpinMap(ndims, L; nthreads)
        serialize(csm_file, csm)
    end

    Ts = 10:-0.01:0.1
    Es, Cvs = mcmc_threaded(
        csm, Ts;
        seed, nsamples, nburns,
        nthrows, nthreads,
    )
    serialize(data_dir("samples", "$ndims-$L.jls"), (Es, Cvs))
    return
end
