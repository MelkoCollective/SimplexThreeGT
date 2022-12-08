### A Pluto.jl notebook ###
# v0.19.17

using Markdown
using InteractiveUtils

# ╔═╡ 8dd1a53c-92f1-4666-b1e0-16166f615a1f
using Pkg; Pkg.activate(dirname(dirname(@__FILE__)))

# ╔═╡ 1a794950-769f-11ed-3329-75fd635dfc85
using Statistics, CSV, DataFrames, Plots, Interpolations, SimplexThreeGT, Configurations, QuadGK

# ╔═╡ b609b326-aaea-4b47-98af-9e5022e10c9f
using SimplexThreeGT: task_dir, shape_dir

# ╔═╡ 0a82ff84-13a7-4882-b09c-efa9040b7558
function read_csv_files(dir::String)
    filter(readdir(dir)) do each
        isfile(joinpath(dir, each)) || return false
        endswith(each, ".csv") || return false
        return true
    end
end

# ╔═╡ 565fc26c-bcc4-40b1-b963-b1ee73072f35
function collect_csv_samples(task::ChainTaskInfo; extra::Bool=true)
    csv_files = read_csv_files(task_dir(task))
    isempty(csv_files) && return DataFrame()

    df = mapreduce(vcat, csv_files) do each
        DataFrame(CSV.File(task_dir(task, each)))
    end

    extra || return df
    isdir(task_dir(task, "extra")) || return df

    csv_files = read_csv_files(task_dir(task, "extra"))
    df2 = mapreduce(vcat, csv_files) do each
        DataFrame(CSV.File(task_dir(task, "extra", each)))
    end
    return vcat(df, df2)
end

# ╔═╡ d0759b6e-2139-407f-92b7-1e9b5ac63591
function merge_temp(df::DataFrame)
    ops = map(filter(!isequal(:temp), propertynames(df))) do key
        key => mean => key
    end
    return combine(groupby(df, :temp), ops...)
end

# ╔═╡ b6f42e9e-4142-4dfc-8c1a-f7080090143f
function collect_samples(task; extra::Bool=true)
    df = collect_csv_samples(task; extra)
    return merge_temp(df)
end

# ╔═╡ 38e4a2e2-f633-4f96-ad44-1762e7b14b47
specific_heat!(df::DataFrame, task) = specific_heat!(df, task.shape)

# ╔═╡ ea719ce7-c7a7-4bb1-847c-384e6ed9c4f4
function specific_heat!(df::DataFrame, shape::ShapeInfo)
    df.Cv = (df.var"E^2" - df.E.^2) ./ (df.temp.^2) ./ (shape.size^shape.ndims)
    return df
end

# ╔═╡ 645dcabc-6a94-4e19-8d8b-efdbb875f75e
task = from_toml(ChainTaskInfo, pkgdir(SimplexThreeGT, "scripts", "3d4L.toml"))

# ╔═╡ a556cd8f-031e-4bd9-b902-c7de720ba54b
df = let df = collect_samples(task; extra=false)
	specific_heat!(df, task)
end

# ╔═╡ 2b9725ed-a755-4050-a949-8c7892c091a8
plot(df.temp, df.Cv, xlabel="T", ylabel="Cv", legend=nothing)

# ╔═╡ 0546b4cf-e60e-450b-bae2-c910ff8fa9de
2/3 * log(2)

# ╔═╡ 8e0ff364-6f22-4dab-8f4b-b06e0695645d
let interp = linear_interpolation(reverse(df.temp), reverse(df.Cv))
	S,_ = quadgk(minimum(df.temp), maximum(df.temp), rtol=1e-8) do T
    	interp(T)/T
	end
	log(2) - S
end

# ╔═╡ Cell order:
# ╠═8dd1a53c-92f1-4666-b1e0-16166f615a1f
# ╠═1a794950-769f-11ed-3329-75fd635dfc85
# ╠═b609b326-aaea-4b47-98af-9e5022e10c9f
# ╟─0a82ff84-13a7-4882-b09c-efa9040b7558
# ╟─565fc26c-bcc4-40b1-b963-b1ee73072f35
# ╟─d0759b6e-2139-407f-92b7-1e9b5ac63591
# ╟─b6f42e9e-4142-4dfc-8c1a-f7080090143f
# ╟─38e4a2e2-f633-4f96-ad44-1762e7b14b47
# ╟─ea719ce7-c7a7-4bb1-847c-384e6ed9c4f4
# ╠═645dcabc-6a94-4e19-8d8b-efdbb875f75e
# ╠═a556cd8f-031e-4bd9-b902-c7de720ba54b
# ╠═2b9725ed-a755-4050-a949-8c7892c091a8
# ╠═0546b4cf-e60e-450b-bae2-c910ff8fa9de
# ╠═8e0ff364-6f22-4dab-8f4b-b06e0695645d
