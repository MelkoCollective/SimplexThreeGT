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

    gauge_nthrows = if isnothing(task.sample.gauge_nthrows)
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

function resample(task::TaskInfo)
    isnothing(task.repeat) && error("expect nrepeat specified")
    isnothing(task.uuid) && error("expect uuid specified")
    isnothing(task.sample.nburns) || error("resample task should not have nburns")

    seed = task.seed::Int; nrepeat = task.repeat::Int;

    # save resample task configuration
    uuid = uuid1()
    save_task_image(task, uuid, "resample")

    mcmc_points = read_checkpoint(task, seed)
    # NOTE: no need to checkpoint here, since we are already
    # at the equilibrium state.
    guarantee_dir(task_dir(task, "resample"))
    data_file = task_dir(task, "resample", "$(uuid).csv")

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
