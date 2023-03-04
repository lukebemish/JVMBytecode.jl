module Flags

import Base: |, &, ~, ==, in, iterate, show, read, write

export AccessFlagSet, TypedFlagSet, bits, set, fitsclass, fitsfield, fitsmethod, fits

abstract type AccessFlagSet end

struct AccessFlag <: AccessFlagSet
    bits::UInt16
    field::Bool
    class::Bool
    method::Bool
    symbol::Symbol
end

struct CombinedAccessFlagSet <: AccessFlagSet
    flags::Set{AccessFlag}
end

struct TypedFlagSet{K}
    flags::AccessFlagSet
    TypedFlagSet{K}(flags::AccessFlagSet) where K = if fits(flags, K)
        new(flags)
    else
        error("Flags $(flags) do not fit in $(K)")
    end
end

TypedFlagSet(flags::AccessFlagSet, k::Symbol) = TypedFlagSet{k}(flags)

bits(flag::AccessFlag) = flag.bits
bits(flag::CombinedAccessFlagSet) = reduce(|, bits(f) for f in flag.flags)
bits(flag::TypedFlagSet) = bits(flag.flags)

set(f::AccessFlag) = Set([f])
set(f::CombinedAccessFlagSet) = f.flags
set(f::TypedFlagSet) = set(f.flags)

iterate(flags::AccessFlagSet) = iterate(set(flags))
iterate(flags::TypedFlagSet) = iterate(set(flags))

(|)(a::AccessFlagSet, b::AccessFlagSet) = CombinedAccessFlagSet(union(set(a), set(b)))
function (|)(a::TypedFlagSet{A}, b::TypedFlagSet{A}) where A
    TypedFlagSet(a.flags | b.flags, A)
end

(&)(a::AccessFlagSet, b::AccessFlagSet) = CombinedAccessFlagSet(intersect(set(a), set(b)))

function (&)(a::TypedFlagSet{A}, b::TypedFlagSet{A}) where A
    TypedFlagSet(a.flags & b.flags, A)
end

(==)(a::AccessFlagSet, b::AccessFlagSet) = set(a) == set(b)
(==)(a::TypedFlagSet{A}, b::TypedFlagSet{A}) where A = a.flags == b.flags

in(flag::AccessFlag, set::AccessFlagSet) = bits(flag) & bits(set) == bits(flag)
in(flag::AccessFlag, set::TypedFlagSet) = in(flag, set.flags)

fitsclass(flag::AccessFlag) = flag.class
fitsfield(flag::AccessFlag) = flag.field
fitsmethod(flag::AccessFlag) = flag.method

fitsclass(set::CombinedAccessFlagSet) = all(fitsclass, set.flags)
fitsfield(set::CombinedAccessFlagSet) = all(fitsfield, set.flags)
fitsmethod(set::CombinedAccessFlagSet) = all(fitsmethod, set.flags)

fitsclass(set::TypedFlagSet) = false
fitsfield(set::TypedFlagSet) = false
fitsmethod(set::TypedFlagSet) = false

fitsclass(set::TypedFlagSet{:class}) = true
fitsfield(set::TypedFlagSet{:field}) = true
fitsmethod(set::TypedFlagSet{:method}) = true

function fits(set::AccessFlagSet, kind::Symbol)
    if kind == :class
        fitsclass(set)
    elseif kind == :field
        fitsfield(set)
    elseif kind == :method
        fitsmethod(set)
    else
        error("Unknown kind: $(kind)")
    end
end

function fits(set::TypedFlagSet{K}, kind::Symbol) where K
    kind == K
end

show(io::IO, flag::AccessFlag) = print(io,"AccessFlagSet[$(flag.symbol)]")

show(io::IO, set::CombinedAccessFlagSet) = print(io, "AccessFlagSet[$(join([i.symbol for i in set.flags], ", "))]")

show(io::IO, s::TypedFlagSet{K}) where K = print(io, "AccessFlagSet[$(K): $(join([i.symbol for i in set(s.flags)], ", "))]")

function accessflags(flags::UInt16, kind::Symbol)::AccessFlagSet
    if kind != :class && kind != :field && kind != :method
        error("Unknown kind: $(kind)")
    end
    out = Set{AccessFlag}()
    if flags & 0x0001 != 0
        push!(out, PUBLIC)
    end
    if flags & 0x0002 != 0 && (kind == :field || kind == :method)
        push!(out, PRIVATE)
    end
    if flags & 0x0004 != 0 && (kind == :field || kind == :method)
        push!(out, PROTECTED)
    end
    if flags & 0x0008 != 0 && (kind == :field || kind == :method)
        push!(out, STATIC)
    end
    if flags & 0x0010 != 0
        push!(out, FINAL)
    end
    if flags & 0x0020 != 0 && kind == :class
        push!(out, SUPER)
    end
    if flags & 0x0020 != 0 && kind == :method
        push!(out, SYNCHRONIZED)
    end
    if flags & 0x0040 != 0 && kind == :field
        push!(out, VOLATILE)
    end
    if flags & 0x0040 != 0 && kind == :method
        push!(out, BRIDGE)
    end
    if flags & 0x0080 != 0 && kind == :field
        push!(out, TRANSIENT)
    end
    if flags & 0x0080 != 0 && kind == :method
        push!(out, VARARGS)
    end
    if flags & 0x0100 != 0 && kind == :method
        push!(out, NATIVE)
    end
    if flags & 0x0200 != 0 && kind == :class
        push!(out, INTERFACE)
    end
    if flags & 0x0400 != 0 && (kind == :class || kind == :method)
        push!(out, ABSTRACT)
    end
    if flags & 0x0800 != 0 && kind == :method
        push!(out, STRICT)
    end
    if flags & 0x1000 != 0
        push!(out, SYNTHETIC)
    end
    if flags & 0x2000 != 0 && kind == :class
        push!(out, ANNOTATION)
    end
    if flags & 0x4000 != 0 && (kind == :class || kind == :field)
        push!(out, ENUM)
    end
    return CombinedAccessFlagSet(out)
end

accessflags(flags::TypedFlagSet) = flags.flags

function write(io::IO, flags::AccessFlagSet)
    write(io, hton(UInt16(bits(flags))))
end

function write(io::IO, flags::TypedFlagSet)
    write(io, flags.flags)
end

function read(io::IO, ::Type{TypedFlagSet{K}}) where K
    TypedFlagSet{K}(accessflags(ntoh(read(io, UInt16)), K))
end

const PUBLIC = AccessFlag(0x0001, true, true, true, :public)
const PRIVATE = AccessFlag(0x0002, true, false, true, :private)
const PROTECTED = AccessFlag(0x0004, true, false, true, :protected)
const STATIC = AccessFlag(0x0008, true, false, true, :static)
const FINAL = AccessFlag(0x0010, true, true, true, :final)
const SUPER = AccessFlag(0x0020, false, true, false, :super)
const SYNCHRONIZED = AccessFlag(0x0020, false, false, true, :synchronized)
const VOLATILE = AccessFlag(0x0040, true, false, false, :volatile)
const BRIDGE = AccessFlag(0x0040, false, false, true, :bridge)
const TRANSIENT = AccessFlag(0x0080, true, false, false, :transient)
const VARARGS = AccessFlag(0x0080, false, false, true, :varargs)
const NATIVE = AccessFlag(0x0100, false, false, true, :native)
const INTERFACE = AccessFlag(0x0200, false, true, false, :interface)
const ABSTRACT = AccessFlag(0x0400, false, true, true, :abstract)
const STRICT = AccessFlag(0x0800, false, false, true, :strict)
const SYNTHETIC = AccessFlag(0x1000, true, true, true, :synthetic)
const ANNOTATION = AccessFlag(0x2000, false, true, false, :annotation)
const ENUM = AccessFlag(0x4000, true, true, false, :enum)

end