module Checkpoint

export read_checkpoint, write_checkpoint, find_checkpoint

function spin_nbytes(nspins::Int)
    d,r = divrem(nspins, 64)
    n_uint64 = r == 0 ? d : d + 1
    return 8 * n_uint64
end

function to_bitvector(x::Vector{UInt8}, nspins::Int)
    spin_nbytes(nspins) == length(x) || throw(ArgumentError("x is not the correct size"))

    siz = sizeof(x)
    bv = BitVector(undef, nspins)
    GC.@preserve bv x begin
        chunks_ptr = reinterpret(Ptr{UInt8}, pointer(bv.chunks))
        unsafe_copyto!(chunks_ptr, pointer(x), siz)
    end
    return bv
end

function write_checkpoint(io::IO, temp::Float64, spins::BitVector, field::Float64 = 0.0)
    write(io, temp)
    write(io, field)
    write(io, spins.chunks)
    return
end

function read_spins(io::IO, nspins::Int)
    nbytes = spin_nbytes(nspins)
    return to_bitvector(read(io, nbytes), nspins)
end

function read_checkpoint(io::IO, nspins::Int)
    return read(io, Float64), read(io, Float64), read_spins(io, nspins)
end

function find_checkpoint(io::IO, T::Float64, nspins::Int, field::Float64 = 0.0)
    d = find_checkpoint(io, [T], nspins, field)
    return (first(d)..., )
end

function find_checkpoint(io::IO, temps, nspins::Int, field::Float64 = 0.0)
    nbytes = (nspins ÷ 64 + 1) * 8
    d = Dict{Float64, BitVector}()
    sizehint!(d, length(temps))
    temps = Set(temps)

    while !eof(io)
        temp = read(io, Float64)
        if field == read(io, Float64)
            if temp in temps
                delete!(temps, temp)
                d[temp] = read_spins(io, nspins)
            else
                skip(io, nbytes)
            end
            isempty(temps) && return d
        end
    end
    eof(io) && throw(ArgumentError("no checkpoint found or EOF reached"))
    # not all temperatures found
    throw(ArgumentError("missing temperatures: $(temps)"))
end

end # module