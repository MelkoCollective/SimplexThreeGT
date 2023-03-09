"""
emit slurm scripts at `scripts/slurm`
"""
@cast module Slurm

using Comonicon
using SimplexThreeGT.CLI: CLI, foreach_shape, foreach_field
using SimplexThreeGT.Spec: Spec

function slurm(name::String, nthreads::Int, mem::Int, cmds::Vector{String})
    """#!/bin/bash
    #SBATCH --account=rrg-rgmelko-ab
    #SBATCH --time=48:00:00
    #SBATCH --cpus-per-task=$nthreads
    #SBATCH --mem=$(mem)G
    #SBATCH --job-name=$name
    #SBATCH -o logs/%j.out
    #SBATCH -e logs/%j.err
    module load julia/1.8.1
    """ * join(cmds, "\n")
end

@cast function csm()
    ispath(CLI.slurm_dir()) || mkpath(CLI.slurm_dir())
    main_jl = CLI.root_dir("main.jl")
    task_file = CLI.task_dir("csm-$(d)d$(L)L.toml")

    foreach_shape() do d, L
        slurm_script = CLI.slurm_dir("csm_$(d)d$(L)L.sh")
        script = slurm("csm_$(d)d$(L)L", 2, 16, [
            "julia --project --threads=2 $main_jl csm --task=$task_file"
        ]
        open(slurm_script, "w") do io
            println(io, script)
        end
        @info "run(`sbatch $slurm_script`)"
        run(`sbatch $slurm_script`)
    end
end

@cast function annealing()
    ispath(CLI.slurm_dir()) || mkpath(CLI.slurm_dir())

    foreach_shape() do d, L
        foreach_field() do h_start, h_stop
            file = CLI.task_dir("annealing-$(d)d$(L)L-$(h_start)h.toml")
            slurm_script = CLI.slurm_dir("annealing_$(d)d$(L)L_$(h_start)h.sh")
            script = slurm("annealing_$(d)d$(L)L_$(h_start)h", 1, 4, [
                "julia --project $main_jl annealing --task=$file"
            ]

            open(slurm_script, "w") do io
                println(io, script)
            end
            @info "run(`sbatch $slurm_script`)"
            run(`sbatch $slurm_script`)
        end # foreach_field
    end # foreach_shape
end

"""
emit slurm scripts at `scripts/slurm` for binning.

# Intro

This runs the entire schedule of corresponding annealing task.
To run a subset of the schedule, use `resample` command manually.

# Options

- `--ndims <range>`: range of ndims to run.
- `--sizes <range>`: range of sizes to run.
- `--total <int>`: total number of points to run.
- `--each <int>`: number of points to run for each job.
"""
@cast function binning(;
        ndims::String, sizes::String,
        total::Int=100, each::Int=10
    )
    parse_range(s::String) = UnitRange(map(x->parse(Int, x), split(s, ":"))...)
    main_jl = CLI.root_dir("main.jl")
    ndims = parse_range(ndims)
    sizes = parse_range(sizes)
    njobs = total ÷ each

    for d in ndims, L in sizes
        shape = Spec.ShapeInfo(;ndims=d, size=L)
        file = first(readdir(Spec.task_dir(shape, "task_images")))
        uuid = splitext(file)[1]

        @info "binning" ndims=d size=L uuid=uuid
        script = slurm("binning_$(d)d$(L)L_$uuid", 1, 4, [
            "julia --project $main_jl resample --ndims=$d --size=$L --uuid=$uuid --repeat=$each"
        ]

        slurm_script = CLI.slurm_dir("binning_$uuid.sh")
        open(slurm_script, "w") do io
            println(io, script)
        end

        for _ in 1:njobs
            @info "run(`sbatch $slurm_script`)"
            run(`sbatch $slurm_script`)
        end
    end
end

end # module
