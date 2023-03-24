Base.@kwdef mutable struct EmitContext
    n_annealing_jobs::Int = 0
    n_resample_jobs::Int = 0
    annealing_job_id::String = ""
    checkpoint_crunch_job_id::String = ""
end

function emit(job::AnnealingJob)
    ctx = EmitContext()
    emit_task!(ctx, job)
    return ctx
end

function emit(job::SimulationJob)
    ctx = EmitContext()
    ajob = AnnealingJob(job)
    rjob = ResampleJob(job)
    emit_task!(ctx, ajob)
    emit_task!(ctx, rjob)
    return ctx
end

function emit(rjob::ResampleJob)
    ctx = EmitContext()
    emit_task!(ctx, rjob)
    return ctx
end

function submit(job::AnnealingJob)
    ctx = emit(job)
    emit_slurm!(ctx, job)
    emit_slurm_crunch_checkpoint!(ctx, job)
    return
end

function submit(job::SimulationJob)
    ctx = emit(job)
    ajob = AnnealingJob(job)
    rjob = ResampleJob(job)
    emit_slurm!(ctx, ajob)
    emit_slurm_crunch_checkpoint!(ctx, ajob)
    emit_slurm!(ctx, rjob)
    return
end

function submit(rjob::ResampleJob)
    ctx = emit(rjob)
    emit_slurm!(ctx, rjob)
    return
end

function emit_task!(ctx::EmitContext, job::AnnealingJob)
    to_toml(image_dir(job, "$(job.uuid).toml"), job)
    cm = CellMapOptions(;job.storage, job.shape, gauge=!isnothing(job.sample.gauge))
    to_toml(temp_dir(job, "cellmap.toml"), cm)
    field_per_job = length(job.fields) ÷ job.njobs + 1
    job_itr = Iterators.partition(job.fields, field_per_job)
    ctx.n_annealing_jobs = length(job_itr)
    for (idx, fields) in enumerate(job_itr)
        option = AnnealingOptions(;
            job = job.uuid,
            uuid = uuid1(),
            seed = UInt(rand(UInt16)),
            shape = job.shape,
            storage = job.storage,
            sample = job.sample,
            temperatures = job.temperatures,
            fields = collect(fields),
        )
        file = guarantee_dir(temp_dir(job, "annealing"), "$idx.toml")
        to_toml(file, option)
    end
end

function emit_task!(ctx::EmitContext, job::ResampleJob)
    to_toml(image_dir(job, "$(job.uuid).toml"), job)
    per_job = (length(job.fields) * length(job.temperatures)) ÷ job.njobs + 1
    job_itr = Iterators.partition(Iterators.product(job.temperatures, job.fields), per_job)
    ctx.n_resample_jobs = length(job_itr)
    for (job_idx, partition) in enumerate(job_itr)
        fields = Float64[]; temps = Float64[]
        for (temp, field) in partition
            push!(fields, field)
            push!(temps, temp)
        end

        option = ResampleOptions(;
            seed = UInt(rand(UInt16)),
            uuid = uuid1(),
            parent = job.parent,
            shape = job.shape,
            storage = job.storage,
            sample = job.sample,
            matrix = ResampleMatrix(;
                temperatures = temps,
                fields = fields,
            ),
        )
        file = guarantee_dir(temp_dir(job, "resample"), "$job_idx.toml")
        to_toml(file, option)
    end
end

###### Slurm ######

Base.@kwdef struct SlurmOptions
    nthreads::Int = 1
    mem::Int = 8
    max_njobs::Int = 800
    time::String = "7-00:00:00"
    account::String = "rrg-rgmelko-ab"
    main::String = pkgdir(Jobs, "scripts", "main.jl")
end

function (opt::SlurmOptions)(name::String, cmds::Vector{String};
        # not usually shared by jobs
        njobs::Int = 1,
        deps::Vector{String} = String[]
    )

    lines = [
        "#!/bin/bash",
        "#SBATCH --account=$(opt.account)",
        "#SBATCH --time=$(opt.time)",
        "#SBATCH --cpus-per-task=$(opt.nthreads)",
        "#SBATCH --mem=$(opt.mem)G",
        "#SBATCH --job-name=$name",
    ]

    if njobs > 1
        if njobs > opt.max_njobs
            push!(lines, "#SBATCH --array=1-$(njobs)%$(opt.max_njobs)")
        else
            push!(lines, "#SBATCH --array=1-$(njobs)")
        end
        push!(lines, "#SBATCH --output=logs/%A_%a.out")
        push!(lines, "#SBATCH --error=logs/%A_%a.err")
    else
        push!(lines, "#SBATCH --output=logs/%j.out")
        push!(lines, "#SBATCH --error=logs/%j.err")
    end

    if !isempty(deps)
        push!(lines, "#SBATCH --dependency=afterok:$(join(deps, ":"))")
    end
    push!(lines, "module load julia/1.8.5")

    mainjl = relpath(opt.main, pwd())
    julia_cmds = [
        "julia",
        "--project"
    ]
    if opt.nthreads > 1
        push!(julia_cmds, "--threads=$(opt.nthreads)")
    end
    push!(julia_cmds, "--")
    push!(julia_cmds, mainjl)
    append!(julia_cmds, cmds)
    push!(lines, join(julia_cmds, ' '))
    return join(lines, '\n') * '\n'
end

function emit_slurm!(ctx::EmitContext, job::AnnealingJob)
    option = SlurmOptions()

    slurm_script = option("cm-" * name(job.shape), [
        "cellmap",
        "--path", job.storage.path,
        "--tags", join(job.storage.tags, ','),
        "--job", string(job.uuid),
    ])
    slurm_script_path = guarantee_dir(temp_dir(job, "slurm"), "cellmap.sh")
    write(slurm_script_path, slurm_script)
    job_id = sbatch(slurm_script_path)

    slurm_script = option("an-" * name(job.shape), [
            "annealing",
            "--path", job.storage.path,
            "--tags", join(job.storage.tags, ','),
            "--job", string(job.uuid),
            "--task", "\$SLURM_ARRAY_TASK_ID",
        ]; deps=[job_id], njobs=ctx.n_annealing_jobs,
    )
    slurm_script_path = guarantee_dir(temp_dir(job, "slurm"), "annealing.sh")
    write(slurm_script_path, slurm_script)
    ctx.annealing_job_id = sbatch(slurm_script_path)
    return
end

function emit_slurm_crunch_checkpoint!(ctx::EmitContext, job::AnnealingJob)
    isempty(ctx.annealing_job_id) && error("annealing job not submitted")
    option = SlurmOptions()
    slurm_script = option("crunch-checkpoint", [
            "crunch", "checkpoint",
            "--path", job.storage.path,
            "--tags", join(job.storage.tags, ','),
            "--job", string(job.uuid),
        ]; deps=[ctx.annealing_job_id],
    )

    slurm_script_path = guarantee_dir(temp_dir(job, "slurm"), "crunch_checkpoint.sh")
    write(slurm_script_path, slurm_script)
    ctx.checkpoint_crunch_job_id = sbatch(slurm_script_path)
    return
end

function emit_slurm!(ctx::EmitContext, job::ResampleJob)
    if !isfile(checkpoint_dir(job, "$(job.parent).checkpoint"))
        isempty(ctx.checkpoint_crunch_job_id) && error(
            "checkpoint crunch job not submitted or error for job $(job.parent)"
        )
    end

    option = SlurmOptions()
    deps = isempty(ctx.checkpoint_crunch_job_id) ? String[] : [ctx.checkpoint_crunch_job_id]
    slurm_script = option("rs-" * name(job.shape), [
            "resample",
            "--path", job.storage.path,
            "--tags", join(job.storage.tags, ','),
            "--job", "$(job.parent)", # lead us to crunched checkpoints
            "--task", "\$SLURM_ARRAY_TASK_ID"
        ]; deps, njobs=ctx.n_resample_jobs,
    )
    slurm_script_path = guarantee_dir(temp_dir(job, "slurm"), "resample.sh")
    write(slurm_script_path, slurm_script)
    sbatch(slurm_script_path)
    return
end

function sbatch(path::String)::String
    # println("sbatch $path")
    # return string(rand(Int))
    out = readchomp(`sbatch $path`)
    return match(r"Submitted batch job (\d+)", out).captures[1]
end
