using Comonicon

function template(type, d, L, nthreads::Int, mem::Int)
    """#!/bin/bash
    #SBATCH --account=rrg-rgmelko-ab
    #SBATCH --time=48:00:00
    #SBATCH --cpus-per-task=$nthreads
    #SBATCH --mem=$(mem)G
    #SBATCH --job-name=$(type)_$(d)d$(L)L
    #SBATCH -o logs/%j.out
    #SBATCH -e logs/%j.err
    module load julia/1.8.1
    # julia --project -e "using Pkg; Pkg.instantiate()"
    julia --project scripts/main.jl $type --task=task/$(d)d$(L)L.toml
    """
end

@cast function csm()
    slurm_dir = joinpath(dirname(@__FILE__), "slurm")
    ispath(slurm_dir) || mkpath(slurm_dir)

    for d in 3:4, L in 4:2:16
        open("scripts/slurm/csm_$(d)d$(L)L.sh", "w") do io
            print(io, template("csm", d, L, 32, 16))
        end
        run(`sbatch scripts/slurm/csm_$(d)d$(L)L.sh`)
    end
end

@cast function annealing()
    slurm_dir = joinpath(dirname(@__FILE__), "slurm")
    ispath(slurm_dir) || mkpath(slurm_dir)

    for d in 3:4, L in 4:2:16
        open("scripts/slurm/annealing_$(d)d$(L)L.sh", "w") do io
            print(io, template("annealing", d, L, 1, 4))
        end
        run(`sbatch scripts/slurm/annealing_$(d)d$(L)L.sh`)
    end
end

@cast function resample(njobs::Int=1)
    slurm_dir = joinpath(dirname(@__FILE__), "slurm")
    ispath(slurm_dir) || mkpath(slurm_dir)

    for _ in 1:njobs, d in 3:4, L in 4:2:16
        open("scripts/slurm/resample_$(d)d$(L)L.sh", "w") do io
            print(io, template("resample", d, L, 1, 4))
        end
        run(`sbatch scripts/slurm/resample_$(d)d$(L)L.sh`)
    end
end

@main
