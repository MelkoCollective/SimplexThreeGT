#!/bin/bash
#SBATCH --account=kfm-471-aa
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=1
#SBATCH --array=4-16:2
module load julia/1.8.1
julia --project scripts/main.jl annealing --task=task/3d${SLURM_ARRAY_JOB_ID}L.toml
