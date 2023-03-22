function burn!(mc::MarkovChain, nburns::Int)
    for _ in 1:nburns
        mcmc_step!(mc)
    end
    return mc
end

function sample!(mc::MarkovChain, info::SamplingInfo)
    init!(mc)

    step! = if info.order == Random
        mcmc_step!
    elseif info.order == TypeWriter
        typewriter_step!
    else
        error("unknown order: $(info.order)")
    end

    for _ in 1:info.nsamples
        for _ in 1:info.nthrows
            step!(mc)
        end

        isnothing(info.gauge) || for _ in 1:info.gauge.step
            gauge_step!(mc)
        end
        collect!(mc)
    end
    finalize!(mc, info.nsamples)
    return mc
end

function annealing(job::AnnealingJob)
    save_task_image(job)
    pmap(job.tasks) do task::AnnealingTask
        cm = cell_map(job.storage, job.cellmap)
        gauge = gauge_map(job.storage, job.cellmap)

        rng = Xoshiro(task.seed)
        spins = rand_spins(rng, nspins(cm))
        field = task.field

        chain = MarkovChain(;
            rng,
            uuid = task.uuid,
            cm, gauge,
            state = State(
                spins,
                temp = first(job.temperature),
                energy = energy(cm, spins, field),
                field,
            ),
        )

        with_task_log(task, "annealing-$(task.uuid)") do
            @info "annealing started"
            checkpoint(chain, job) do checkpoint_agent
                @progress name="h=$(field)" for T in job.temperature
                    chain.state.temp = T
                    burn!(chain, job.nburns)
                    checkpoint_agent()
                end
            end # checkpoint
        end # with_task_log
    end
end

function annealing!(mcmc::MarkovChain, task::AnnealingJob)
    save_task_image(task)
    ispath(task_dir(task, "annealing")) || mkpath(task_dir(task, "annealing"))
    data_file = task_dir(task, "annealing", "$(mcmc.uuid).csv")

    with_task_log(task, "annealing-$(mcmc.uuid)") do
        checkpoint(mcmc, task) do checkpoint_agent
            # NOTE: make sure the data is written to different
            # files under same directory for different runs
            record(data_file) do record_agent
                @progress name="annealing" for h in fields(task), T in temperatures(task)
                    mcmc.state.field = h
                    mcmc.state.temp = T
                    @debug "Temperature: $T (h=$h)"
                    burn!(mcmc, task)
                    sample!(mcmc, task)
                    record_agent(mcmc)
                    checkpoint_agent()
                end
            end
        end
    end # with_task_log
    return mcmc
end

function resample(task::TaskInfo)
    isnothing(task.repeat) && error("expect `repeat` specified")
    isnothing(task.uuid) && error("expect uuid specified")
    isnothing(task.sample.nburns) || error("resample task should not have nburns")

    seed = task.seed::Int; nrepeat = task.repeat::Int;

    # save resample task configuration
    uuid = uuid1()
    save_task_image(task, uuid, "resample")

    # NOTE: no need to checkpoint here, since we are already
    # at the equilibrium state.
    guarantee_dir(task_dir(task, "resample", "$(task.uuid)"))
    data_file = task_dir(task, "resample", "$(task.uuid)", "$(uuid).csv")

    mcmc_tasks = read_checkpoint(task, seed)

    with_task_log(task, "resample-$uuid") do
        @info "Resampling $(length(mcmc_tasks)) chains" nrepeat seed
        record(data_file) do record_agent
            @progress name="resample" for round_idx in 1:nrepeat, mcmc in mcmc_tasks
                # @show mcmc.state.temp
                sample!(mcmc, task)
                record_agent(mcmc)
            end
        end # record
    end # with_task_log
    return
end
