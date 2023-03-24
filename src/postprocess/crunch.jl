using CSV: CSV
using Statistics: mean, std
using DataFrames: DataFrame, groupby, combine
using ..Jobs
using Configurations: to_dict, from_toml


function crunch(info::StorageInfo, uuid::String)
    return mapreduce(vcat, readdir(sample_dir(info, uuid))) do file
        DataFrame(CSV.File(sample_dir(info, uuid, file)))
    end
end

function specific_heat!(df::DataFrame, shape::ShapeInfo)
    return specific_heat!(df, shape.ndims, shape.size)
end

function specific_heat!(df::DataFrame, ndims::Int, L::Int)
	nfaces = ndims * (ndims-1) / 2 * L^ndims
    df.Cv = (df.var"E^2" - df.E.^2) ./ (df.temp.^2) ./ nfaces
    return df
end

function error_analysis(df::DataFrame)
    transforms = []
    for ob in filter(p -> !(p in (:field, :temp)), propertynames(df))
        push!(transforms, ob => mean => string(ob))
        push!(transforms, ob => std => string(ob, "(std)"))
    end
    return combine(groupby(df, [:field, :temp]), transforms...)
end

function postprocess(info::StorageInfo, uuid::String)
    job = from_toml(
        AnnealingJob,
        Jobs.image_dir(info, "annealing", "$(uuid).toml")
    )
    df = crunch(job.storage, uuid)
    specific_heat!(df, job.shape)
    df = error_analysis(df)
    CSV.write(Jobs.crunch_dir(info, "$(uuid).csv"), df)
    return
end
