using Dates
using Plots
using Random
using Comonicon
using Logging: global_logger
using TerminalLoggers: TerminalLogger
using SimplexThreeGT
using Serialization
using SimplexThreeGT: mcmc, mcmc_threaded, nspins, cubes, faces, energy, mcmc_step!, local_energy

if !@isdefined(VSCodeServer)
    ENV["GKSwstype"]=100 # turn off display
    global_logger(TerminalLogger())
end

data_dir(xs...) = pkgdir(SimplexThreeGT, "data", "$(today())", xs...)
images_dir(xs...) = data_dir("images", xs...)
samples_dir(xs...) = data_dir("samples", xs...)
cubes_dir(xs...) = data_dir("cubes", xs...)

@main function main(ndims::Int, L::Int;
        nthreads::Int=Threads.nthreads(),
        seed::Int=1234,
        nsamples::Int=10_000,
        nburns::Int=10_000,
        nthrows::Int=50,
    )
    @info "task info" ndims L nthreads seed nsamples nburns nthrows
    isdir(samples_dir()) || mkpath(samples_dir())
    isdir(cubes_dir()) || mkpath(cubes_dir())
    isdir(images_dir()) || mkpath(images_dir())
    task_name = "n$ndims-L$L"

    csm_file = cubes_dir("$task_name.jls")
    if isfile(csm_file)
        csm = deserialize(csm_file)
    else
        @info "generating cubic spin map"
        csm = CubicSpinMap(ndims, L; nthreads)
        serialize(csm_file, csm)
    end

    @info "mcmc start"
    Ts = 10:-0.01:0.1
    Es, Cvs = mcmc_threaded(
        csm, Ts;
        seed, nsamples, nburns,
        nthrows, nthreads,
    )
    @info "saving data"
    serialize(samples_dir("$task_name.jls"), (Es, Cvs))
    @info "plotting start"
    plot(Ts, Cvs;
        xlabel="T", ylabel="Cv", title="Cv vs T ($(task_name))",
        xticks=0:0.5:10, legend=nothing,
    )
    @info "saving image"
    savefig(images_dir("$task_name.png"))
    @info "task done"
    return
end
