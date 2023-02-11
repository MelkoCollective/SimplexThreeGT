function with_path_log(f, path::String, name::String)
    ispath(path) || mkpath(path)
    log_file = joinpath(path, "$name.log")
    return open(log_file, "w") do io
        with_logger(f, TerminalLogger(io; always_flush=true))
    end
end

function with_task_log(f, task::TaskInfo, name::String)
    with_path_log(f, task_dir(task, "logs"), name)
end

function with_shape_log(f, shape::ShapeInfo, name::String)
    with_path_log(f, shape_dir(shape, "logs"), name)
end
