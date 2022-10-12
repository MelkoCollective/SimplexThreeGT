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
        return i == 0 || j == 0 || k == 0 ||
            i == (n-1) || j == (n-1) || k == (n-1)
    end
    
    for i in 1:n, j in 1:n, k in 1:n-1
        i,j,k = i-1,j-1,k-1
        dash = !(is_boundary(i, j, k) && is_boundary(i, j, k+1))
        s *= draw("($i, $j, $k) -- ($i, $j, $(k+1))"; dash)
    end

    for i in 1:n, j in 1:n-1, k in 1:n
        i,j,k = i-1,j-1,k-1
        dash = !(is_boundary(i, j, k) && is_boundary(i, j+1, k))
        s *= draw("($i, $j, $k) -- ($i, $(j+1), $k)"; dash)
    end

    for i in 1:n-1, j in 1:n, k in 1:n
        i,j,k = i-1,j-1,k-1
        dash = !(is_boundary(i, j, k) && is_boundary(i+1, j, k))
        s *= draw("($i, $j, $k) -- ($(i+1), $j, $k)"; dash)
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

write(img_dir("cube.tex"), standalone(cube(3)))
