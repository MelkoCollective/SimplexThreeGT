function burn!(mc::MarkovChain, task::TaskInfo)
    for _ in 1:task.sample.nburns
        mcmc_step!(mc)
    end
    return mc
end

function sample!(mc::MarkovChain, task::TaskInfo)
    init!(mc)
    nthrows = if isnothing(task.sample.nthrows)
        nspins(mc.cm)÷2
    else
        task.sample.nthrows
    end

    gauge_nthrows = if task.sample.gauge && isnothing(task.sample.gauge_nthrows)
        nspins(mc.gauge)÷2
    else
        task.sample.gauge_nthrows
    end

    for _ in 1:task.sample.nsamples
        for _ in 1:nthrows
            mcmc_step!(mc)
        end

        task.sample.gauge && for _ in 1:gauge_nthrows
            gauge_step!(mc)
        end
        collect!(mc)
    end

    finalize!(mc, task.sample.nsamples)
    return mc
end

function annealing!(mcmc::MarkovChain, task::TaskInfo)
    isnothing(task.uuid) || error("annealing task should not have a uuid")
    isnothing(task.repeat) || error("annealing task should not have a repeat")
    isnothing(task.sample.nburns) && error("annealing task should have nburns")

    save_task_image(task, mcmc.uuid)
    ispath(task_dir(task, "annealing")) || mkpath(task_dir(task, "annealing"))
    data_file = task_dir(task, "annealing", "$(mcmc.uuid).csv")

    with_task_log(task, "annealing-$(mcmc.uuid)") do
        checkpoint(mcmc, task) do checkpoint_agent
            # NOTE: make sure the data is written to different
            # files under same directory for different runs
            record(data_file) do record_agent
                @progress name="extern field" for h in fields(task)
                    mcmc.state.field = h
                    @progress name="annealing" for T in temperatures(task)
                        mcmc.state.temp = T
                        @debug "Temperature: $T (h=$h)"
                        burn!(mcmc, task)
                        sample!(mcmc, task)

                        record_agent(mcmc)
                        checkpoint_agent()
                    end
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

    mcmc_points = read_checkpoint(task, seed)
    # NOTE: no need to checkpoint here, since we are already
    # at the equilibrium state.
    guarantee_dir(task_dir(task, "resample", "$(task.uuid)"))
    data_file = task_dir(task, "resample", "$(task.uuid)", "$(uuid).csv")

    with_task_log(task, "resample-$uuid") do
        @info "Resampling $(length(mcmc_points)) chains" nrepeat seed
        record(data_file) do record_agent
            @progress name="resample" for _ in 1:nrepeat
                for temp in temperatures(task)
                    @debug "Temperature: $(temp)"
                    mcmc = mcmc_points[temp]
                    sample!(mcmc, task)
                    record_agent(mcmc)
                end
            end
        end
    end # with_task_log
    return
end
