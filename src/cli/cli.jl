module CLI

using Comonicon
using TOML: TOML
using Configurations: from_toml, to_dict, from_dict
using SimplexThreeGT: SimplexThreeGT
using SimplexThreeGT.SimplexThreeGT: SimplexThreeGT
using SimplexThreeGT.Homology: cell_map
using SimplexThreeGT.MonteCarlo: MonteCarlo, MarkovChain
using SimplexThreeGT.Spec: TaskInfo, ShapeInfo, Schedule
using SimplexThreeGT.PostProcess: PostProcess

include("utils.jl")
include("emit.jl")
include("slurm.jl")

"""
run annealing

# Options

- `--task <string>`: path to the task file,
  or use `--task.<property>` to change the property
  temporarily.
"""
@cast function annealing(;task::TaskInfo)
    @info "annealing starts" task
    MonteCarlo.annealing(task)
    return
end

"""
run resampling

# Arguments

- `path::String`: path to the directory containing tasks

# Options

- `--ndims <int>`: number of dimensions
- `--size <int>`: size of the lattice
- `--temps <range>`: temperature schedule, default is the same as the annealing task.
- `--fields <range>`: external field schedule, default is the same as the annealing task.
- `--uuid <string>`: uuid of the task
- `--repeat <int>`: number of times to repeat the task
"""
@cast function resample(
        path::String = pkgdir(SimplexThreeGT, "data");
        ndims::Int,
        size::Int,
        temps::String="",
        fields::String="",
        uuid::String,
        repeat::Int,
    )

    task_images_dir = joinpath(path, "cm-$(ndims)d-$(size)L", "task_images")
    isdir(task_images_dir) || return println("no such directory: $task_images_dir")
    d = TOML.parsefile(joinpath(task_images_dir, "$(uuid).toml"))

    if !isempty(temps)
        t_stop,t_step,t_start = map(x->parse(Float64, x), split(temps, ':'))
        d["temperature"]["start"] = t_start
        d["temperature"]["step"] = t_step
        d["temperature"]["stop"] = t_stop
    end

    if !isempty(fields)
        h_stop,h_step,h_start = map(x->parse(Float64, x), split(fields, ':'))
        d["extern_field"]["start"] = h_start
        d["extern_field"]["step"] = h_step
        d["extern_field"]["stop"] = h_stop
    end

    d["uuid"] = uuid
    d["repeat"] = repeat
    delete!(get(Dict, d, "sample"), "nburns")
    task = from_dict(TaskInfo, d)

    @info "resample starts" task
    MonteCarlo.resample(task)
    return
end

"""
list tasks

# Arguments

- `path::String`: path to the directory containing tasks

# Options

- `--ndims <int>`: number of dimensions
- `--size <int>`: size of the lattice
"""
@cast function list(path::String = pkgdir(SimplexThreeGT, "data"); ndims::Int, size::Int)
    task_images_dir = joinpath(path, "cm-$(ndims)d-$(size)L", "task_images")
    isdir(task_images_dir) || return println("no such directory: $task_images_dir")
    for task in readdir(task_images_dir)
        name, ext = splitext(task)
        ext == ".toml" && printstyled(name, '\n'; color=:cyan)

        d = TOML.parsefile(joinpath(task_images_dir, task))
        d = Dict(
            "sample" => d["sample"],
            "temperature" => d["temperature"],
        )
        TOML.print(stdout, d)
        println()
    end
    return
end

"""
crunch the data

# Arguments

- `path::String`: path to the directory containing tasks

# Options

- `--ndims <int>`: number of dimensions
- `--size <int>`: size of the lattice
- `--uuid <string>`: uuid of the task
"""
@cast function crunch(
        path::String = pkgdir(SimplexThreeGT, "data");
        ndims::Int, size::Int, uuid::String,
    )

    task_images_dir = joinpath(path, "cm-$(ndims)d-$(size)L", "task_images")
    isdir(task_images_dir) || return println("no such directory: $task_images_dir")
    info = from_toml(TaskInfo, joinpath(task_images_dir, "$(uuid).toml"); uuid)
    PostProcess.postprocess(info)
    return
end

"""
generate the cell map of the shape

# Options

- `--shape <path>`: path to the shape file,
  or use `--shape.<property>` to change the property
  temporarily.
"""
@cast function csm(;shape::ShapeInfo)
    cell_map(shape, (shape.ndims-1, shape.ndims))
    cell_map(shape, (shape.ndims-2, shape.ndims-1))
end

"""
the Lattice Gerbe Theory simulator
"""
@main

end # module
