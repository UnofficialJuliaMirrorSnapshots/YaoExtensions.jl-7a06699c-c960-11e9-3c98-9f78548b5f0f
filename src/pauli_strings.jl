import StaticArrays: SizedVector
export PauliString

# TODO: expand to Clifford?
struct PauliString{N, BT <: ConstantGate{1}, VT <: SizedVector{N, BT}} <: CompositeBlock{N}
    blocks::VT
    PauliString(blocks::SizedVector{N, BT}) where {N, BT <: ConstantGate{1}} =
        new{N, BT, typeof(blocks)}(blocks)
end

# NOTE: PauliString has a fixed size `N`, thus by default, it should use
#      SizedVector, or this block could be actually not correct.

"""
    PauliString(xs::PauliGate...)

Create a `PauliString` from some Pauli gates.

# Example

```jldoctest; setup=:(using YaoBlocks)
julia> PauliString(X, Y, Z)
nqubits: 3
PauliString
├─ X gate
├─ Y gate
└─ Z gate
```
"""
PauliString(xs::PauliGate...) = PauliString(SizedVector{length(xs), PauliGate}(xs))

"""
    PauliString(list::Vector)

Create a `PauliString` from a list of Pauli gates.

# Example

```jldoctest; setup=:(using YaoBlocks)
julia> PauliString([X, Y, Z])
nqubits: 3
PauliString
├─ X gate
├─ Y gate
└─ Z gate
```
"""
function PauliString(xs::Vector)
    for each in xs
        if !(each isa PauliGate)
            error("expect pauli gates")
        end
    end
    return PauliString(SizedVector{length(xs), PauliGate}(xs))
end

subblocks(ps::PauliString) = ps.blocks
chsubblocks(pb::PauliString, blocks::Vector) = PauliString(blocks)
chsubblocks(pb::PauliString, it) = PauliString(collect(it))

Yao.occupied_locs(ps::PauliString) = (findall(x->!(x isa I2Gate), ps.blocks)...,)

cache_key(ps::PauliString) = map(cache_key, ps.blocks)

Yao.ishermitian(::PauliString) = true
Yao.isreflexive(::PauliString) = true
Yao.isunitary(::PauliString) = true

Base.copy(ps::PauliString) = PauliString(copy(ps.blocks))
Base.getindex(ps::PauliString, x) = getindex(ps.blocks, x)
Base.lastindex(ps::PauliString) = lastindex(ps.blocks)
Base.iterate(ps::PauliString) = iterate(ps.blocks)
Base.iterate(ps::PauliString, st) = iterate(ps.blocks, st)
Base.length(ps::PauliString) = length(ps.blocks)
Base.eltype(ps::PauliString) = eltype(ps.blocks)
Base.eachindex(ps::PauliString) = eachindex(ps.blocks)
Base.getindex(ps::PauliString, index::Union{UnitRange, Vector}) =
    PauliString(getindex(ps.blocks, index))
function Base.setindex!(ps::PauliString, v::PauliGate, index::Union{Int})
    ps.blocks[index] = v
    return ps
end

function Base.:(==)(lhs::PauliString{N}, rhs::PauliString{N}) where N
    (length(lhs.blocks) == length(rhs.blocks)) && all(lhs.blocks .== rhs.blocks)
end

xgates(ps::PauliString{N}) where N = RepeatedBlock{N}(X, (findall(x->x isa XGate, (ps.blocks...,))...,))
ygates(ps::PauliString{N}) where N = RepeatedBlock{N}(Y, (findall(x->x isa YGate, (ps.blocks...,))...,))
zgates(ps::PauliString{N}) where N = RepeatedBlock{N}(Z, (findall(x->x isa ZGate, (ps.blocks...,))...,))

function apply!(reg::AbstractRegister, ps::PauliString)
    _check_size(reg, ps)
    for pauligates in [xgates, ygates, zgates]
        blk = pauligates(ps)
        apply!(reg, blk)
    end
    return reg
end

function mat(::Type{T}, ps::PauliString) where T
    return mat(T, xgates(ps)) * mat(T, ygates(ps)) * mat(T, zgates(ps))
end

function YaoBlocks.print_block(io::IO, x::PauliString)
    printstyled(io, "PauliString"; bold=true, color=color(PauliString))
end

YaoBlocks.color(::Type{T}) where {T <: PauliString} = :cyan
