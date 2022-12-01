using Plots
using Serialization

Ts = 10:-0.01:0.1
xs = Float64[]; ys = Float64[]
for L in 4:2:16
    (Es, Cvs) = deserialize("data/2022-12-01/samples/n4-L$L.jls")
    Cv, idx = findmax(Cvs[5:end-5])
    T = Ts[idx]
    push!(xs, T)
    push!(ys, Cv)
end

using Interpolations

interp = linear_interpolation(
    reverse(1 ./(10:2:16)),
    reverse(xs[4:end]),
    extrapolation_bc=Line()
)


plot(1 ./(10:2:16), xs[4:end];
    xlabel="1/L", ylabel="T_c",
    title="1/L-T_c",
    ylims=(0.9, 1.6),
    yticks=0.9:0.05:1.6,
    legend=nothing
)
savefig("n4-L-T_c.png")



(E, Cv) = deserialize("data/2022-12-01/samples/n4-L6.jls")
_, idx = findmax(Cv)
Ts[idx]

(E, Cv) = deserialize("data/2022-12-01/samples/n4-L8.jls")
_, idx = findmax(Cv)
Ts[idx]

(E, Cv) = deserialize("data/2022-12-01/samples/n4-L10.jls")
_, idx = findmax(Cv)
Ts[idx]

(E, Cv) = deserialize("data/2022-12-01/samples/n4-L12.jls")
_, idx = findmax(Cv)
Ts[idx]
length(Cv)


(E, Cv) = deserialize("data/2022-12-01/samples/n4-L14.jls")
_, idx = findmax(Cv[5:end-5])
Ts[idx]

(E, Cv) = deserialize("data/2022-12-01/samples/n4-L16.jls")
_, idx = findmax(Cv[5:end-5])
Ts[idx]



# (E, Cv) = deserialize("data/2022-12-01/samples/n4-L18.jls")
# _, idx = findmax(Cv[100:end-50])
# Ts[idx]

# (E, Cv) = deserialize("data/2022-12-01/samples/n4-L20.jls")
# _, idx = findmax(Cv[100:end-50])
# Ts[idx]
