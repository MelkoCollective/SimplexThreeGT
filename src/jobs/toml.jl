function to_toml(io::IO, info::Info)
    d = to_dict(info; exclude_nothing=true)
    function sortby(x)
        idx = findfirst(isequal(x), d.keys)
        isnothing(idx) && return length(d) + 1
        return idx
    end
    TOML.print(io, d; sorted=true, by=sortby)
    return
end

function to_toml(filename::String, info::Info)
    open(filename, "w") do io
        to_toml(io, info)
    end
    return
end
