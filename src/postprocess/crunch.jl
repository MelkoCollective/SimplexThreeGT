using CSV: CSV
using DataFrames: DataFrame, groupby, combine
using ..Jobs
using Configurations: to_dict, from_toml
using BinningAnalysis

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

function binning(x)
    bin = LogBinner(x)
    return [(mean(bin), std_error(bin), tau(bin), count(bin))]
end

function error_analysis(df::DataFrame)
    transforms = []
    for ob in filter(p -> !(p in (:field, :temp)), propertynames(df))
        cols = [string(ob, "(", type, ")") for type in ("mean", "std", "tau", "count")]
        push!(transforms, ob => binning => cols)
    end
    return combine(groupby(df, [:field, :temp]), transforms...)
end

function postprocess(info::StorageInfo, uuid::String)
    job = from_toml(
        AnnealingJob,
        Jobs.image_dir(info, "annealing", "$(uuid).toml")
    )
    @info "Crunching $(uuid)" job
    df = crunch(job.storage, uuid)
    specific_heat!(df, job.shape)
    df = error_analysis(df)
    CSV.write(Jobs.crunch_dir(info, "$(uuid).csv"), df)
    return
end
