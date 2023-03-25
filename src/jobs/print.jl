function Base.show(io::IO, ::MIME"text/plain", info::Info)
    summary(io, info)
    println(io)
    to_toml(io, info)
end
