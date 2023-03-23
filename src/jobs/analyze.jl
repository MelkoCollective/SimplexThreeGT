export nspins, name, data_dir, checkpoint_dir, sample_dir

function nspins(info::ShapeInfo)
    N0 = info.size^info.ndims  #number of vertices
    return binomial(info.ndims,info.p-1)*N0
end

nspins(info::AnnealingJob) = nspins(info.shape)
nspins(info::ResampleJob) = nspins(info.shape)

function name(info::ShapeInfo)
    return "$(info.ndims)d-$(info.size)L-$(info.p)p"
end

function guarantee_dir(path::String, xs...)
    ispath(path) || mkpath(path)
    return joinpath(path, xs...)
end

data_dir(info::StorageInfo, xs::String...) = joinpath(info.path, info.tags..., xs...)
function subdata_dir(info::StorageInfo, subdir::String, xs::String...)
    guarantee_dir(data_dir(info, subdir), xs...)
end

for name in (:log, :topo, :checkpoint, :image, :sample)
    @eval begin
        export $(Symbol(name, :_dir))
        function $(Symbol(name, :_dir))(info::StorageInfo, xs::String...)
            subdata_dir(info, $(string(name)), xs...)
        end
    end
end

function image_dir(job::AnnealingJob, xs::String...)
    guarantee_dir(image_dir(job.storage, "annealing"), xs...)
end

function image_dir(job::ResampleJob, xs::String...)
    guarantee_dir(image_dir(job.storage, "resample"), xs...)
end

function temp_dir(job::AnnealingJob, xs::String...)
    guarantee_dir(image_dir(job.storage, "temp", string(job.uuid)), xs...)
end

function temp_dir(job::ResampleJob, xs::String...)
    guarantee_dir(image_dir(job.storage, "temp", string(job.parent)), xs...)
end

sample_dir(job::AnnealingJob, xs...) = sample_dir(job.storage, xs...)
checkpoint_dir(job::AnnealingJob, xs...) = checkpoint_dir(job.storage, xs...)
checkpoint_dir(job::ResampleJob, xs...) = checkpoint_dir(job.storage, xs...)
