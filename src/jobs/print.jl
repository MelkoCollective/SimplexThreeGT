function Base.show(io::IO, mime::MIME"text/plain", info::Union{AnnealingJob, ResampleJob})
    println(io, "uuid = \"", info.uuid, "\"")
    println(io)
    println(io, "[cellmap]")
    to_toml(io, info.cellmap)
    println(io)
    println(io, "[storage]")
    to_toml(io, info.storage)
    println(io)

    println(io, "[[tasks]]")
    to_toml(io, info.tasks[1])
    if length(info.tasks) > 1
        println(io)
        println(io, "...")
        println(io)
        println(io, "[[tasks]]")
        to_toml(io, info.tasks[end])
    end
end
