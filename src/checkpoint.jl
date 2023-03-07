module Checkpoint

using DocStringExtensions

"""
    $(TYPEDEF)

A checkpoint for a simulation.

### Fields

- `field::Float64`: The field value.
- `temp::Float64`: The temperature.
- `spins::BitVector`: The spins.
"""
Base.@kwdef struct Row
    field::Float64
    temp::Float64
    spins::BitVector
end # struct

"""
    $(SIGNATURES)

Write a row to a file.
"""
function Base.write(io::IO, row::Row)
    write(io, row.field)
    write(io, row.temp)
    write(io, length(row.spins))
    write(io, row.spins.chunks)
    return
end

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

"""
    $(SIGNATURES)

Read a row from a file.
"""
function Base.read(io::IO, ::Type{Row})
    field = read(io, Float64)
    temp  = read(io, Float64)
    nspins = read(io, Int)
    nbytes = spin_nbytes(nspins)
    spins = to_bitvector(read(io, nbytes), nspins)
    return Row(field, temp, spins)
end

"""
    $(SIGNATURES)

Read all rows from a file.
"""
function read_all_records(filename)
    open(filename, "r") do io
        return read_all_records(io)
    end
end

function read_all_records(io::IO)
    results = Row[]
    while !eof(io)
        push!(results, read(io, Row))
    end
    return results
end

"""
    $(SIGNATURES)

Find rows in a file.
"""
function find(io::IO; temps=Set(), fields=Set([0.0]))
    results = Row[]

    while !eof(io)
        row = read(io, Row)
        if row.field in fields && row.temp in temps
            push!(results, row)
        end
    end
    return results
end

"""
    $(SIGNATURES)

Find rows in a file.
"""
function find(filename::String; temps=Set(), fields=Set([0.0]))
    open(filename, "r") do io
        return find(io, temps=temps, fields=fields)
    end
end

end # module
