using CSV: CSV
using Statistics: mean, std
using DataFrames: DataFrame, groupby, combine
using ..Spec: TaskInfo, task_dir
using Configurations: to_dict, from_dict


function crunch(info::TaskInfo)
    isnothing(info.uuid) && error("expect `uuid` specified")
    resample_dir = task_dir(info, "resample", string(info.uuid))
    return mapreduce(vcat, readdir(resample_dir)) do file
        DataFrame(CSV.File(joinpath(resample_dir, file)))
    end
end

function specific_heat!(df::DataFrame, ndims::Int, L::Int)
	nfaces = ndims * (ndims-1) / 2 * L^ndims
    df.Cv = (df.var"E^2" - df.E.^2) ./ (df.temp.^2) ./ nfaces
    return df
end

function error_analysis(df::DataFrame)
    return combine(groupby(df, [:field, :temp]),
        :E => mean => "E", :E => std => "E(std)",
        "E^2" => mean => "E^2", "E^2" => std => "E^2(std)",
        :Cv => mean => "Cv", :Cv => std => "Cv(std)",
        :M => mean => "M", :M => std => "M(std)",
    )
end

function postprocess(info::TaskInfo)
    df = crunch(info)
    specific_heat!(df, info.shape.ndims, info.shape.size)
    df = error_analysis(df)
    ispath(task_dir(info, "crunch")) || mkpath(task_dir(info, "crunch"))
    CSV.write(task_dir(info, "crunch", string(info.uuid, ".csv")), df)
    return
end
