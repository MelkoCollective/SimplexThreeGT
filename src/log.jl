using TerminalLoggers: TerminalLogger
using Logging: with_logger

function with_path_log(f, path::String, name::String)
    ispath(path) || mkpath(path)
    log_file = joinpath(path, "$name.log")
    return open(log_file, "w") do io
        with_logger(f, TerminalLogger(io; always_flush=true))
    end
end
