using Plots
using QuadGK
using DelimitedFiles
using Interpolations

d = readdlm("L3.txt")
T, E, C = d[:, 1], d[:, 2], d[:, 3]
# integral, err = quadgk(x -> exp(-x^2), 0, 1, rtol=1e-8)
interp = linear_interpolation(reverse(T), reverse(C))

plot(0.05:1e-3:maximum(T), interp.(0.05:1e-3:maximum(T)))

quadgk(minimum(T), maximum(T), rtol=1e-8) do T
    81 * interp(T)/T
end
log(2)
