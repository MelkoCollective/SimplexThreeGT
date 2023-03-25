coverage:
    #!/usr/bin/env julia --project
    using LocalCoverage
    c = generate_coverage("SimplexThreeGT"; run_test = true)
    html_coverage(c; open=true)

submit type:
    julia --project scripts/main.jl submit {{type}} --job scripts/main.toml

slurm-status:
    squeue --format="%.18i %.9P %.30j %.8u %.8T %.10M %.9l %.6D %R" --me

sync ndims size:
    #!/usr/bin/env bash
    REMOTE=graham:/home/rogerluo/projects/def-rgmelko/rogerluo/SimplexThreeGT/data
    NAME=cm-{{ndims}}d-{{size}}L
    rsync -avzcP $REMOTE/$NAME/task_images data/$NAME/
    rsync -avzcP $REMOTE/$NAME/annealing data/$NAME/
    rsync -avzcP $REMOTE/$NAME/resample data/$NAME/
    rsync -avzcP $REMOTE/$NAME/resample_images data/$NAME/

sync-test:
    #!/usr/bin/env bash
    REMOTE=graham:/home/rogerluo/projects/def-rgmelko/rogerluo/SimplexThreeGT/data
    rsync -avzcP $REMOTE/test data/

pluto:
    julia --project -e 'using Pluto; Pluto.run()'

clean:
    rm -rf scripts/slurm
    rm -rf scripts/task
    rm logs/*

watch path:
    #!/usr/bin/env julia --compile=min --
    open("{{path}}") do io
        if readlines(io)[end] == "done"
            @info "done"
            return
        end

        while true
            try
                if !eof(io)
                    line = readline(io)
                    line == "done" && break
                    print('\r', line)
                end
                sleep(1e-3)
            catch e
                e isa InterruptException && break
                rethrow(e)
            end
        end
    end
