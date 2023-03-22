export njobs, time_complexity, nspins, name,
    data_dir, log_dir,
    topo_dir, checkpoint_dir,
    task_image_dir, sample_dir

njobs(info::ResampleInfo) = info.nrepeat * length(info.tasks)
njobs(info::FieldResample) = njobs(info.resample)
njobs(info::AnnealingTask) = njobs(info.resample) + 1
njobs(info::CellMapInfo) = 1
njobs(info::AnnealingJob) = njobs(info.cellmap) + sum(njobs, info.tasks)
njobs(info::ResampleJob) = sum(njobs, info.tasks)

function nspins(info::ShapeInfo)
    N0 = info.size^info.ndims  #number of vertices
    return binomial(info.ndims,info.p-1)*N0
end
nspins(info::CellMapInfo) = nspins(info.shape)
nspins(info::AnnealingJob) = nspins(info.cellmap)
nspins(info::ResampleJob) = nspins(info.cellmap)

function time_complexity(info::SamplingInfo, shape::ShapeInfo)
    cost = if info.order == Random
        info.nburns + info.nthrows * info.nsamples
    elseif info.order == TypeWriter
        # tw does not throw, it updates the entire lattice
        # for every sample.
        info.nburns + info.nsamples * nspins(shape)
    else
        error("unknown update order: $(info.order)")
    end
    isnothing(info.gauge) && return cost
    return cost + 6 * info.gauge.steps
end

function time_complexity(info::ResampleInfo, shape::ShapeInfo)
    each_temp = time_complexity(info.sample, shape)
    cost = sum(info.tasks) do task::ResampleTask
        length(task.temperatures) * each_temp
    end
    return cost * info.nrepeat
end

function time_complexity(info::FieldResample, shape::ShapeInfo)
    return time_complexity(info.resample, shape)
end

function time_complexity(info::AnnealingTask, shape::ShapeInfo)
    return time_complexity(info.resample, shape)
end

function time_complexity(info::AnnealingJob)
    cost = if info.order == Random
        info.nburns
    elseif info.order == TypeWriter
        info.nburns * nspins(info.shape)
    else
        error("unknown update order: $(info.order)")
    end
    cost = cost * length(info.temperature)

    return sum(info.tasks) do task::AnnealingTask
        cost + time_complexity(task, info.cellmap.shape)
    end
end

function time_complexity(info::ResampleJob)
    return sum(info.tasks) do task::FieldResample
        time_complexity(task, info.cellmap.shape)
    end
end

function name(info::ShapeInfo)
    return "$(info.ndims)d-$(info.size)L-$(info.p)p"
end

function name(info::CellMapInfo)
    return name(info.shape) * "-$(info.gauge)g"
end

function guarantee_dir(path::String, xs...)
    ispath(path) || mkpath(path)
    return joinpath(path, xs...)
end

data_dir(info::StorageInfo, xs::String...) = joinpath(info.path, info.tags..., xs...)
function log_dir(info::StorageInfo, shape::ShapeInfo, xs::String...)
    guarantee_dir(data_dir(info, name(shape), "log"), xs...)
end

function topo_dir(info::StorageInfo, shape::ShapeInfo, xs::String...)
    guarantee_dir(data_dir(info, name(shape), "topo"), xs...)
end

function checkpoint_dir(info::StorageInfo, shape::ShapeInfo, xs::String...)
    guarantee_dir(data_dir(info, name(shape), "checkpoint"), xs...)
end

function task_image_dir(info::StorageInfo, shape::ShapeInfo, xs::String...)
    guarantee_dir(data_dir(info, name(shape), "task_image"), xs...)
end

function temp_image_dir(info::StorageInfo, shape::ShapeInfo, xs::String...)
    guarantee_dir(data_dir(info, name(shape), "temp_image"), xs...)
end

function sample_dir(info::StorageInfo, shape::ShapeInfo, xs::String...)
    guarantee_dir(data_dir(info, name(shape), "sample"), xs...)
end

task_image_dir(job::AnnealingJob, xs...) = task_image_dir(job.storage, job.cellmap.shape, xs...)
sample_dir(job::AnnealingJob, xs...) = sample_dir(job.storage, job.cellmap.shape, xs...)
checkpoint_dir(job::AnnealingJob, xs...) = checkpoint_dir(job.storage, job.cellmap.shape, xs...)

function temp_image_dir(job::AnnealingJob, xs...)
    guarantee_dir(temp_image_dir(job.storage, job.cellmap.shape, string(job.uuid)), xs...)
end
