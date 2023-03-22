### A Pluto.jl notebook ###
# v0.19.22

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ c1bb5b70-c070-11ed-25a7-4ba77b0da3ed
begin
	using Pkg
	Pkg.activate("..")
	using SimplexThreeGT
	using SimplexThreeGT.PostProcess
	using DataFrames
	using CSV
	using Plots
end

# ╔═╡ d898f113-5752-44a1-aa0d-5fc87499130a
using PlutoUI

# ╔═╡ 002f5bed-9f90-4344-9c84-dbd667d847a9
data_dir = pkgdir(SimplexThreeGT, "data")

# ╔═╡ f108e52d-e658-4ccc-85a1-9210617d0009
ndims=4

# ╔═╡ 7e936015-1518-4e21-ae9a-4c100fccaf4b
L=4

# ╔═╡ 294558fa-b7a6-4253-a339-aefcd77c3ccb
cm_file = "cm-$(ndims)d-$(L)L"

# ╔═╡ 75a4e2ea-9d55-42b2-aced-b19bf7af9e88
uuids = readdir(joinpath(data_dir, cm_file, "annealing"))

# ╔═╡ 9d2e2cc6-b755-4c48-b0d2-152d9355f68a
df = mapreduce(vcat, uuids) do file
	DataFrame(CSV.File(joinpath(data_dir, cm_file, "annealing", file)))
end

# ╔═╡ 6c200417-28e1-42ad-9b21-efb598a1fff3
PostProcess.specific_heat!(df, ndims, L)

# ╔═╡ ba44f420-fbd3-4eaf-aed9-ab3457f726e2
groups = groupby(df, [:field, :temp], sort=true)

# ╔═╡ b424881a-8bf8-4173-937f-9e571cdd855f
fields = 0.0:0.01:1.0

# ╔═╡ 5f59b060-642c-4fb0-8e66-cd8cd813f6fd
temps = 0.1:0.01:50.0

# ╔═╡ 2b435077-a1e2-470e-bb31-1c141b945b41
Cv = let Cv = zeros(length(fields), length(temps))
	for group in groups
		i = searchsortedfirst(fields, group.field[1])
		j = searchsortedfirst(temps, group.temp[1])
		Cv[i, j] = group.Cv[1]
	end
	Cv
end

# ╔═╡ 06fe524f-b161-40cc-8e79-5933cbf5a836
heatmap(fields,
    temps[1:120], Cv[:, 1:120],
    c=cgrad([:blue, :white,:red, :yellow]),
    xlabel="fields", ylabel="temps",
    title="Cv")

# ╔═╡ 0eb561f3-24e3-4bc0-b85d-c403b5b91b7c
Cv[:, 1:200]

# ╔═╡ 432df020-eb30-49a8-9eb5-64f939f58fe1
temps[1:300]

# ╔═╡ 27f2ce4e-e265-4cb2-866d-6a2a36990fca
field_groups = groupby(df, [:field, ], sort=true)

# ╔═╡ d1fe6607-ea40-4a8d-8136-18a9d65c4be6
md"""
h = $(@bind h Slider(1:length(field_groups), show_value=true))
start = $(@bind start Slider(1:5000, show_value=true))
"""

# ╔═╡ 67c2c669-59e5-4dc5-a709-3af45273a409
plot(field_groups[h].temp[start:end], field_groups[h].M[start:end], title="h=$(field_groups[h].field[1])")

# ╔═╡ 7bbd835c-731a-482d-863b-0a4970b345c8
plot(field_groups[h].temp[start:end], field_groups[h].Cv[start:end], title="h=$(field_groups[h].field[1])")

# ╔═╡ d1de043f-409d-4975-9b2e-152ca24562db


# ╔═╡ Cell order:
# ╠═c1bb5b70-c070-11ed-25a7-4ba77b0da3ed
# ╠═002f5bed-9f90-4344-9c84-dbd667d847a9
# ╠═f108e52d-e658-4ccc-85a1-9210617d0009
# ╠═7e936015-1518-4e21-ae9a-4c100fccaf4b
# ╠═294558fa-b7a6-4253-a339-aefcd77c3ccb
# ╠═75a4e2ea-9d55-42b2-aced-b19bf7af9e88
# ╠═9d2e2cc6-b755-4c48-b0d2-152d9355f68a
# ╠═6c200417-28e1-42ad-9b21-efb598a1fff3
# ╠═ba44f420-fbd3-4eaf-aed9-ab3457f726e2
# ╠═b424881a-8bf8-4173-937f-9e571cdd855f
# ╠═5f59b060-642c-4fb0-8e66-cd8cd813f6fd
# ╠═2b435077-a1e2-470e-bb31-1c141b945b41
# ╠═06fe524f-b161-40cc-8e79-5933cbf5a836
# ╠═0eb561f3-24e3-4bc0-b85d-c403b5b91b7c
# ╠═432df020-eb30-49a8-9eb5-64f939f58fe1
# ╟─27f2ce4e-e265-4cb2-866d-6a2a36990fca
# ╠═d898f113-5752-44a1-aa0d-5fc87499130a
# ╠═d1fe6607-ea40-4a8d-8136-18a9d65c4be6
# ╠═67c2c669-59e5-4dc5-a709-3af45273a409
# ╠═7bbd835c-731a-482d-863b-0a4970b345c8
# ╠═d1de043f-409d-4975-9b2e-152ca24562db
