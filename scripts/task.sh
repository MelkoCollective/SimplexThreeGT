#!/bin/bash
#SBATCH --account=rrg-rgmelko-ab
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=4096M
#SBATCH -o logs/%j.out
#SBATCH -e logs/%j.err
module load julia/1.8.1
# julia --project -e "using Pkg; Pkg.instantiate()"
julia --project scripts/main.jl annealing --task=task/3d16L.toml
