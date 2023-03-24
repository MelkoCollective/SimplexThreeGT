using BinningAnalysis

bin = LogBinner(rand(100))
tau(bin)

using SimplexThreeGT.Jobs
using SimplexThreeGT.PostProcess
using SimplexThreeGT.PostProcess: binning_transform, specific_heat!
using DataFrames
using Configurations

uuid = "a75057ea-ca1b-11ed-1e48-9f9dc5de9bc0"
info = StorageInfo("data", "test")
job = from_toml(
    AnnealingJob,
    Jobs.image_dir(info, "annealing", "$(uuid).toml")
)
df = PostProcess.crunch(info, uuid)
specific_heat!(df, job.shape)
gdf = groupby(df, [:field, :temp])

function binning(name, x)
    bin = LogBinner(x)
    return [(mean(bin), std_error(bin), tau(bin))]
end

binning(name) = x->binning(name, x)
PostProcess.binning(gdf[end].Cv)
combine(gdf, binning_transform(Symbol("Cv")))

binning("E")(gdf[end].E)
binning("E")(gdf[1].E)

@less mean(LogBinner(gdf[1].E))
DataFrame(:field)
gdf[1]

