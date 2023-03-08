module CLI

using Comonicon
using TOML: TOML
using Configurations: from_toml, to_dict, from_dict
using ..SimplexThreeGT: SimplexThreeGT
using ..MonteCarlo: MonteCarlo, MarkovChain
using ..Spec: TaskInfo, task_dir
using ..PostProcess: PostProcess

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
- `--uuid <string>`: uuid of the task
- `--repeat <int>`: number of times to repeat the task
"""
@cast function resample(
        path::String = pkgdir(SimplexThreeGT, "data");
        ndims::Int, size::Int, uuid::String, repeat::Int,
    )

    task_images_dir = joinpath(path, "cm-$(ndims)d-$(size)L", "task_images")
    isdir(task_images_dir) || return println("no such directory: $task_images_dir")

    d = TOML.parsefile(joinpath(task_images_dir, "$(uuid).toml"))
    d["uuid"] = uuid
    d["repeat"] = repeat
    delete!(d["sample"], "nburns")
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
the Lattice Gerbe Theory simulator
"""
@main

end # CLI
