export nspins, name, data_dir, sample_dir, checkpoint_file, sample_file, crunch_dir

function nspins(info::ShapeInfo)
    N0 = info.size^info.ndims  #number of vertices
    return binomial(info.ndims,info.p-1)*N0
end

nspins(info::Job) = nspins(info.shape)

function name(info::ShapeInfo)
    return "$(info.ndims)d-$(info.size)L-$(info.p)p"
end

function guarantee_dir(path::String, xs...)
    ispath(path) || mkpath(path)
    return joinpath(path, xs...)
end

function data_dir(info::StorageInfo, xs::String...)
    relpath(normpath(joinpath(info.path, info.tags..., xs...)), pwd())
end

function subdata_dir(info::StorageInfo, subdir::String, xs::String...)
    return guarantee_dir(data_dir(info, subdir), xs...)
end

for name in (:log, :topo, :checkpoint, :image, :sample, :crunch)
    @eval begin
        export $(Symbol(name, :_dir))
        function $(Symbol(name, :_dir))(info::StorageInfo, xs::String...)
            return subdata_dir(info, $(string(name)), xs...)
        end
    end
end

function image_dir(job::Job, xs::String...)
    return guarantee_dir(image_dir(job.storage, "annealing"), xs...)
end

function image_dir(job::ResampleJob, xs::String...)
    return guarantee_dir(image_dir(job.storage, "resample"), xs...)
end

function temp_dir(job::Job, xs::String...)
    return guarantee_dir(image_dir(job.storage, "temp", string(job.uuid)), xs...)
end

function temp_dir(job::ResampleJob, xs::String...)
    return guarantee_dir(image_dir(job.storage, "temp", string(job.parent)), xs...)
end

sample_dir(job::Job, xs...) = sample_dir(job.storage, string(job.uuid), xs...)
sample_dir(job::ResampleJob, xs...) = sample_dir(job.storage, string(job.parent), xs...)
function sample_file(job::ResampleOptions)
    return guarantee_dir(sample_dir(job.storage, string(job.parent)), "$(job.uuid).csv")
end

checkpoint_dir(job::Job, xs...) = checkpoint_dir(job.storage, xs...)
checkpoint_file(job::Job) = checkpoint_dir(job, "$(job.uuid).checkpoint")
checkpoint_file(job::ResampleJob) = checkpoint_dir(job, "$(job.parent).checkpoint")
checkpoint_file(task::ResampleOptions) = checkpoint_dir(task.storage, "$(task.parent).checkpoint")

# annealing save checkpoint in a temp file waiting for crunching
function checkpoint_file(task::AnnealingOptions)
    return guarantee_dir(
        checkpoint_dir(task.storage, "temp", string(task.job)),
        "$(task.uuid).checkpoint"
    )
end
