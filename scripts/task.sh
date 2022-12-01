julia --threads=auto --project scripts/main.jl 4 4  --nsamples=100000 --nburns=10000 --seed=1234 --nthrows=50
julia --threads=auto --project scripts/main.jl 4 6  --nsamples=100000 --nburns=10000 --seed=1234 --nthrows=50
julia --threads=auto --project scripts/main.jl 4 8  --nsamples=100000 --nburns=10000 --seed=1234 --nthrows=50
julia --threads=auto --project scripts/main.jl 4 10 --nsamples=100000 --nburns=10000 --seed=1234 --nthrows=50
julia --threads=auto --project scripts/main.jl 4 12 --nsamples=100000 --nburns=10000 --seed=1234 --nthrows=50
