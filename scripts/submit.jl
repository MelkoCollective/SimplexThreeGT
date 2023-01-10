using Comonicon
using SimplexThreeGT
using Configurations

root_dir(xs...) = joinpath(dirname(@__FILE__), xs...)
task_dir(xs...) = root_dir("task", xs...)
script_dir(xs...) = root_dir("scripts", xs...)
guarantee_dir(path) = isdir(path) ? path : mkpath(path)

function emit_csm_task(d, L)
    guarantee_dir(task_dir())
    task = ShapeInfo(;ndims=d, size=L)
    to_toml(task_dir("csm-$(d)d$(L)L.toml"), task)
    return
end

function emit_annealing_task(d, L)
    guarantee_dir(task_dir())
    task = TaskInfo(;
        shape = ShapeInfo(;
            ndims=d,
            size=L
        ),
        sample = SamplingInfo(;
            nburns=50_000,
            nsamples=500_000,
            nthrows=10,
            observables=["E", "E^2"]
        ),
        temperature = Schedule(;
            start=50.0,
            step=-0.01,
            stop=0.1
        )
    )
    to_toml(task_dir("annealing-$(d)d$(L)L.toml"), task)
    return
end

# function emit_resample_task(d, L)
#     task = TaskInfo(;
#         shape = ShapeInfo(;
#             ndims=d,
#             size=L
#         ),
#         sample = SamplingInfo(;
#             nburns=50_000,
#             nsamples=500_000,
#             nthrows=10,
#             observables=["E", "E^2"]
#         ),
#         temperature = Schedule(;
#             start=10.0,
#             step=-0.01,
#             stop=0.1
#         )
#     )
#     to_toml(task_dir("resample-$(d)d$(L)L.toml"), task)
#     return
# end


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
    julia --project --threads=$nthreads scripts/main.jl $type --task=scripts/task/$type-$(d)d$(L)L.toml
    """
end

@cast function csm()
    slurm_dir = joinpath(dirname(@__FILE__), "slurm")
    ispath(slurm_dir) || mkpath(slurm_dir)

    for d in 3:4, L in 4:2:16
        @info "emit CSM task for $(d)d$(L)L"
        emit_csm_task(d, L)
        open("scripts/slurm/csm_$(d)d$(L)L.sh", "w") do io
            print(io, template("csm", d, L, 32, 16))
        end
        @info "run(`sbatch scripts/slurm/csm_$(d)d$(L)L.sh`)"
        run(`sbatch scripts/slurm/csm_$(d)d$(L)L.sh`)
    end
end

@cast function annealing()
    slurm_dir = joinpath(dirname(@__FILE__), "slurm")
    ispath(slurm_dir) || mkpath(slurm_dir)

    for d in 3:4, L in 4:2:16
        @info "emit annealing task for $(d)d$(L)L"
        emit_annealing_task(d, L)

        open("scripts/slurm/annealing_$(d)d$(L)L.sh", "w") do io
            print(io, template("annealing", d, L, 1, 4))
        end
        @info "run(`sbatch scripts/slurm/annealing_$(d)d$(L)L.sh`)"
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
