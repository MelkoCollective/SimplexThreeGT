using TerminalLoggers: TerminalLogger
using Logging: with_logger
using .Jobs: StorageInfo, log_dir

function with_path_log(f, path::String, name::String)
    ispath(path) || mkpath(path)
    log_file = joinpath(path, "$name.log")
    return open(log_file, "w") do io
        with_logger(f, TerminalLogger(io; always_flush=true))
        println(io, "done")
    end
end

function with_log(f, storage::StorageInfo, name::String)
    with_path_log(f, log_dir(storage), name)
end
