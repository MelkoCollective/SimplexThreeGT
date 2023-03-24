using BinningAnalysis

bin = LogBinner(rand(100))
tau(bin)

using SimplexThreeGT.Jobs
using SimplexThreeGT.PostProcess
using DataFrames

info = StorageInfo("data", "test")
df = PostProcess.crunch(info, "999788de-ca03-11ed-2e81-1fe12183772a")
gdf = groupby(df, [:field, :temp])

function binning(name, x)
    bin = LogBinner(x)
    return [(mean(bin), std_error(bin), tau(bin))]
end

binning(name) = x->binning(name, x)

combine(gdf, :E => binning("E") => [:mean, :std, :tau])

binning("E")(gdf[1].E)

@less mean(LogBinner(gdf[1].E))
DataFrame(:field)
gdf[1]

