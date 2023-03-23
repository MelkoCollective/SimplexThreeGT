function Base.show(io::IO, ::MIME"text/plain", info::Union{AnnealingJob, ResampleJob})
    to_toml(io, info; sorted=true)
end
