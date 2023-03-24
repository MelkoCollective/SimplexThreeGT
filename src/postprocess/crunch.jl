using CSV: CSV
using DataFrames: DataFrame, groupby, combine
using ..Jobs
using Configurations: to_dict, from_toml
using BinningAnalysis
using ProgressLogging: @withprogress, @logprogress

function crunch(info::StorageInfo, uuid::String)
    csv_files = readdir(sample_dir(info, uuid))
    ncsv_files = length(csv_files)
    return @withprogress name="crunching csv files for $(uuid)" begin
        mapreduce(vcat, 1:ncsv_files, csv_files) do idx, file
            @logprogress idx/ncsv_files
            DataFrame(CSV.File(sample_dir(info, uuid, file)))
        end
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
    bin = LogBinner(eltype(x))
    append!(bin, x)
    return [(mean(bin), std_error(bin), tau(bin), count(bin))]
end

function binning_transform(name::Symbol)
    cols = [string(name, "(", type, ")") for type in ("mean", "std", "tau", "count")]
    return name => binning => cols
end

function error_analysis(df::DataFrame)
    transforms = []
    for ob in filter(p -> !(p in (:field, :temp)), propertynames(df))
        push!(transforms, binning_transform(ob))
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
