coverage:
    #!/usr/bin/env julia --project
    using LocalCoverage
    c = generate_coverage("SimplexThreeGT"; run_test = true)
    html_coverage(c; open=true)

submit type:
    julia --project scripts/main.jl submit {{type}} --job scripts/main.toml

slurm-status:
    squeue --format="%.18i %.9P %.30j %.8u %.8T %.10M %.9l %.6D %R" --me

slurm-count:
    squeue --format="%.18i %.9P %.30j %.8u %.8T %.10M %.9l %.6D %R" --me | wc -l

sync:
    #!/usr/bin/env bash
    REMOTE=compute-canada:/home/rogerluo/projects/def-rgmelko/rogerluo/SimplexThreeGT/data
    rsync -avzcP $REMOTE/image data/
    rsync -avzcP $REMOTE/crunch data/

sync-test:
    #!/usr/bin/env bash
    REMOTE=compute-canada:/home/rogerluo/projects/def-rgmelko/rogerluo/SimplexThreeGT/data
    rsync -avzcP $REMOTE/test data/

pluto:
    julia --project=scripts -e 'using Pluto; Pluto.run()'

clean:
    rm -rf scripts/slurm
    rm -rf scripts/task
    rm logs/*

watch path:
    julia --project scripts/main.jl watch {{path}}
