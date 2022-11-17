function draw(s::String; dash::Bool=false)
    dash && return "\\draw[dashed] $s;\n"
    return "\\draw $s;\n"
end

function square_lattice(n::Int)
    s = ""
    for i in 1:n, j in 1:n-1
        i,j = i-1, j-1 # convert tikz coords
        s *= draw("($i, $j) -- ($i, $(j+1))")
    end
    for i in 1:n-1, j in 1:n
        i,j = i-1, j-1 # convert tikz coords
        s *= draw("($i, $j) -- ($(i+1), $j)")
    end
    return s
end

function cube(n::Int)
    s = ""
    function is_boundary(i, j, k)
        # return i == 0 || j == 0 || k == 0 ||
        return i == (n-1) || j == (n-1) || k == (n-1)
    end
    
    for i in 1:n, j in 1:n, k in 1:n-1
        i,j,k = i-1,j-1,k-1
        dash = !(is_boundary(i, j, k) && is_boundary(i, j, k+1))
        if !dash
            s *= draw("($i, $j, $k) -- ($i, $j, $(k+1))"; dash)
        end
    end

    for i in 1:n, j in 1:n-1, k in 1:n
        i,j,k = i-1,j-1,k-1
        dash = !(is_boundary(i, j, k) && is_boundary(i, j+1, k))
        if !dash
            s *= draw("($i, $j, $k) -- ($i, $(j+1), $k)"; dash)
        end
    end

    for i in 1:n-1, j in 1:n, k in 1:n
        i,j,k = i-1,j-1,k-1
        dash = !(is_boundary(i, j, k) && is_boundary(i+1, j, k))
        if !dash
            s *= draw("($i, $j, $k) -- ($(i+1), $j, $k)"; dash)
        end
    end
    return s
end

function cubic_tn(n::Int)
    s = ""
    for i in 0.5:n-0.5, j in 0.5:n-0.5, k in 0.5:n-1.5
        s *= draw("($i,$j,$k) -- ($i,$j,$(k+1))")
    end
    return s
end

function standalone(s::String)
    lines = split(s, '\n')
    lines = map(x->strip(x, ['\n', ' ']), lines)
    lines = filter(!isempty, lines)
    lines = map(x->"    "^2 * x, lines)
    text = join(lines, '\n')

    return """
    \\documentclass[crop,tikz]{standalone}
    \\begin{document}
        \\begin{tikzpicture}
        $text
        \\end{tikzpicture}
    \\end{document}
    """
end

img_dir(xs...) = normpath(joinpath(@__DIR__, "..", "images", xs...))


square_lattice(4)|>clipboard
cube(4)|>clipboard

write(img_dir("tn-plaquette.tex"), standalone(square_lattice(4)))
write(img_dir("tn-cube.tex"), standalone(cube(4)))
clipboard(cubic_tn(4))