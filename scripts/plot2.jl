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

# ╔═╡ de9f08e2-ce67-11ed-3a88-838fff267690
begin
	using Pkg
	Pkg.activate(Base.current_project())
	using Plots, PlutoUI, DataFrames, CSV, LinearAlgebra
end

# ╔═╡ c3279e72-838e-49b5-b3dd-c1dc7f301ece
df = DataFrame(CSV.File("../data/crunch/c8ec6624-cace-11ed-0795-d1e27c39ff1f.csv"))

# ╔═╡ d21e5512-632e-4ae1-8d42-cdb1f98311bb
gdf = groupby(df, [:field])

# ╔═╡ 8a37f5bd-75b3-435e-9a17-615977321b33
@bind h Slider(1:100)

# ╔═╡ 85f64587-79aa-423a-809e-5dcd22d25837
plot(
	gdf[h]."temp", gdf[h]."Cv(mean)",
	yerror=map(gdf[h]."Cv(std)") do x
		isnan(x) ? 0.0 : x
	end,
	legend=nothing,
	xlabel="temperature", ylabel="Cv(mean)",
	title="h=$(gdf[h].field[1])"
)

# ╔═╡ 60019633-dc6f-4078-9601-c141df4b46c1
plot(
	gdf[h]."temp", gdf[h]."M(mean)",
	yerror=map(gdf[h]."M(std)") do x
		isnan(x) ? 0.0 : x
	end,
	legend=nothing,
	xlabel="temperature", ylabel="M(mean)",
	title="h=$(gdf[h].field[1])"
)

# ╔═╡ bb6c87a4-8d3c-462a-bef3-8f15c84281a0
plot(
	gdf[h]."temp", gdf[h]."accept_rate(mean)" .+ 1e-20,
	legend=nothing,
	xlabel="temperature", ylabel="accept_rate(mean)",
	yaxis=:log,
	title="h=$(gdf[h].field[1])"
)

# ╔═╡ 6175d2f3-2a41-4d8c-afaa-d3836e986e41
maximum(gdf[77]."Cv(std)")

# ╔═╡ 6048db65-70b9-4936-954a-87b2db57e5b1
maximum(gdf[77]."Cv(mean)")

# ╔═╡ d7157f73-a8b5-43bf-b888-ed4fc20d50ed
maximum(gdf[57]."Cv(tau)")

# ╔═╡ 9e3a937b-fb32-45da-8a74-c4dc0e76f4bd
maximum(gdf[57]."Cv(count)")

# ╔═╡ 79921671-272f-4a50-a5e7-0b05d236689f
hs = [df.field[1] for df in gdf]

# ╔═╡ a8b551b8-d365-48fe-84ac-291ea7962387
Ts = sort(gdf[1].temp)

# ╔═╡ 0b64e65b-0e17-4d58-9a18-935d72a2bdfb
Cv = let
	ret = zeros(length(gdf[1].temp), length(gdf))
	for (h_idx, df) in enumerate(gdf), (T_idx, T) in enumerate(df.temp)
		ret[end - T_idx + 1, h_idx] = df."Cv(mean)"[T_idx] / maximum(df."Cv(mean)")
	end
	ret
end

# ╔═╡ 051415ce-30b6-4fdd-b335-ee371320147b
heatmap(hs, Ts, Cv; xlabel="h", ylabel="T")

# ╔═╡ 779aa539-e30e-4736-a1e1-c2a487cd09da
maximum(Ts)

# ╔═╡ e8395949-5f7b-40f9-bb70-2c2719489b79
plot(Cv[:, 1])

# ╔═╡ fb067387-529d-4849-8d4f-da4943f0c939
M = let
	ret = zeros(length(gdf[1].temp), length(gdf))
	for (h_idx, df) in enumerate(gdf), (T_idx, T) in enumerate(df.temp)
		ret[end - T_idx + 1, h_idx] = df."M(mean)"[T_idx] / maximum(df."M(mean)")
	end
	ret
end

# ╔═╡ 18237a59-3057-4a72-9dbe-c22fcc26b568
heatmap(hs, Ts, M; xlabel="h", ylabel="T")

# ╔═╡ Cell order:
# ╠═de9f08e2-ce67-11ed-3a88-838fff267690
# ╠═c3279e72-838e-49b5-b3dd-c1dc7f301ece
# ╠═d21e5512-632e-4ae1-8d42-cdb1f98311bb
# ╠═8a37f5bd-75b3-435e-9a17-615977321b33
# ╠═85f64587-79aa-423a-809e-5dcd22d25837
# ╠═60019633-dc6f-4078-9601-c141df4b46c1
# ╠═bb6c87a4-8d3c-462a-bef3-8f15c84281a0
# ╠═6175d2f3-2a41-4d8c-afaa-d3836e986e41
# ╠═6048db65-70b9-4936-954a-87b2db57e5b1
# ╠═d7157f73-a8b5-43bf-b888-ed4fc20d50ed
# ╠═9e3a937b-fb32-45da-8a74-c4dc0e76f4bd
# ╠═79921671-272f-4a50-a5e7-0b05d236689f
# ╠═a8b551b8-d365-48fe-84ac-291ea7962387
# ╠═0b64e65b-0e17-4d58-9a18-935d72a2bdfb
# ╠═051415ce-30b6-4fdd-b335-ee371320147b
# ╠═779aa539-e30e-4736-a1e1-c2a487cd09da
# ╠═e8395949-5f7b-40f9-bb70-2c2719489b79
# ╠═fb067387-529d-4849-8d4f-da4943f0c939
# ╠═18237a59-3057-4a72-9dbe-c22fcc26b568
