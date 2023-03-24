function sample_step!(mc::MarkovChain, info::SamplingInfo)
    if info.order == Random
        mcmc_step!(mc)
    elseif info.order == TypeWriter
        typewriter_step!(mc)
    else
        error("unknown order: $(info.order)")
    end
end

function burn!(mc::MarkovChain, info::SamplingInfo)
    for _ in 1:info.nburns
        sample_step!(mc, info)
    end
    return mc
end

function sample!(mc::MarkovChain, info::ResampleInfo)
    init!(mc)

    burn!(mc, info.option)
    for _ in 1:info.nsamples
        for _ in 1:info.nthrows
            sample_step!(mc, info.option)
        end
        gauge!(mc, info.option)
        collect!(mc)
    end
    finalize!(mc, info.nsamples)
    return mc
end

function gauge!(mc::MarkovChain, option::SamplingInfo)
    isnothing(option.gauge) && return mc
    for _ in 1:option.gauge.steps
        gauge_step!(mc)
    end
    return mc
end

function annealing(task::AnnealingOptions)
    chain = MarkovChain(task)
    with_log(task.storage, "annealing-$(task.uuid)") do
        @info "annealing started" task
        checkpoint(chain, task) do checkpoint_agent
            @withprogress name="annealing" begin
                n_fields = length(task.fields)
                for (idx, h) in enumerate(task.fields)
                    chain.state.field = h
                    for T in task.temperatures
                        chain.state.temp = T
                        burn!(chain, task.sample)
                        checkpoint_agent()
                    end
                    @logprogress @sprintf("   h=%.2f", h) idx/n_fields
                end
            end # @withprogress
        end # checkpoint
    end # with_task_log
    return
end

function resample(task::ResampleOptions)
    chains = read_checkpoint(task)

    with_log(task.storage, "resample-$(task.uuid)") do
        @info "resampling started" task
        record(sample_file(task)) do record_agent
            task_itr = Iterators.product(chains, 1:task.sample.nrepeat)
            total_tasks = length(task_itr)
            @withprogress name="resample  " begin
                for (task_idx, (chain, idx)) in enumerate(task_itr)
                    sample!(chain, task.sample)
                    record_agent(chain)
                    @logprogress @sprintf("epoch %3i", idx) task_idx/total_tasks
                end
            end # @withprogress
        end # record
    end # with_task_log
    return
end
