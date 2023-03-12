coverage:
    #!/usr/bin/env julia --project
    using LocalCoverage
    c = generate_coverage("SimplexThreeGT"; run_test = true)
    html_coverage(c; open=true)

slurm-status:
    squeue --format="%.18i %.9P %.30j %.8u %.8T %.10M %.9l %.6D %R" --me

sync ndims size:
    #!/usr/bin/env bash
    REMOTE=graham:/home/rogerluo/projects/def-rgmelko/rogerluo/SimplexThreeGT/data
    NAME=cm-{{ndims}}d-{{size}}L
    rsync -avzcP $REMOTE/$NAME/task_images data/$NAME/
    rsync -avzcP $REMOTE/$NAME/annealing data/$NAME/

pluto:
    julia --project -e 'using Pluto; Pluto.run()'

clean:
    rm -rf scripts/slurm
    rm -rf scripts/task
    rm logs/*

