module Mutable

import ..Low

abstract type ConstantPoolEntry end

struct Class
    constants::Dict{ConstantPoolEntry,Integer}
end

function claimed!(::ConstantPoolEntry, ::Class) end
function released!(::ConstantPoolEntry, ::Class) end

function claim!(pool::Class, entry::ConstantPoolEntry)
    if haskey(pool.constants, entry)
        pool.constants[entry] += 1
    else
        pool.constants[entry] = 1
        claimed!(entry, pool)
        1
    end
end

function release!(pool::Class, entry::ConstantPoolEntry)
    if haskey(pool.constants, entry)
        pool.constants[entry] -= 1
        if pool.constants[entry] == 0
            delete!(pool.constants, entry)
            released!(entry, pool)
            return
        end
    else
        error("Entry $(entry) not found in constant pool!")
    end
end

struct ConstantClassEntry <: ConstantPoolEntry
    name::String
end

function claimed!(class::ConstantClassEntry, pool::Class)
    claim!(pool, ConstantUTF8Entry(class.name))
end

function released!(class::ConstantClassEntry, pool::Class)
    release!(pool, ConstantUTF8Entry(class.name))
end

struct ConstantUTF8Entry <: ConstantPoolEntry
    value::String
end

struct ConstantNameAndTypeEntry <: ConstantPoolEntry
    name::String
    descriptor::String
end

function claimed!(info::ConstantNameAndTypeEntry, pool::Class)
    claim!(pool, ConstantUTF8Entry(info.name))
    claim!(pool, ConstantUTF8Entry(info.descriptor))
end

function released!(info::ConstantNameAndTypeEntry, pool::Class)
    release!(pool, ConstantUTF8Entry(info.name))
    release!(pool, ConstantUTF8Entry(info.descriptor))
end

struct ConstantFieldEntry <: ConstantPoolEntry
    class::ConstantClassEntry
    name::String
    descriptor::String
end

function claimed!(info::ConstantFieldEntry, pool::Class)
    claim!(pool, info.class)
    claim!(pool, ConstantNameAndTypeEntry(info.name, info.descriptor))
end

function released!(info::ConstantFieldEntry, pool::Class)
    release!(pool, info.class)
    release!(pool, ConstantNameAndTypeEntry(info.name, info.descriptor))
end

struct ConstantMethodEntry <: ConstantPoolEntry
    class::ConstantClassEntry
    name::String
    descriptor::String
end

function claimed!(info::ConstantMethodEntry, pool::Class)
    claim!(pool, info.class)
    claim!(pool, ConstantNameAndTypeEntry(info.name, info.descriptor))
end

function released!(info::ConstantMethodEntry, pool::Class)
    release!(pool, info.class)
    release!(pool, ConstantNameAndTypeEntry(info.name, info.descriptor))
end

struct ConstantInterfaceMethodEntry <: ConstantPoolEntry
    class::ConstantClassEntry
    name::String
    descriptor::String
end

function claimed!(info::ConstantInterfaceMethodEntry, pool::Class)
    claim!(pool, info.class)
    claim!(pool, ConstantNameAndTypeEntry(info.name, info.descriptor))
end

function released!(info::ConstantInterfaceMethodEntry, pool::Class)
    release!(pool, info.class)
    release!(pool, ConstantNameAndTypeEntry(info.name, info.descriptor))
end

struct ConstantStringEntry <: ConstantPoolEntry
    value::String
end

function claimed!(info::ConstantStringEntry, pool::Class)
    claim!(pool, ConstantUTF8Entry(info.value))
end

function released!(info::ConstantStringEntry, pool::Class)
    release!(pool, ConstantUTF8Entry(info.value))
end

struct ConstantIntegerEntry <: ConstantPoolEntry
    value::Int32
end

struct ConstantFloatEntry <: ConstantPoolEntry
    value::Float32
end

struct ConstantLongEntry <: ConstantPoolEntry
    value::Int64
end

struct ConstantDoubleEntry <: ConstantPoolEntry
    value::Float64
end

# TODO: method handles

struct ConstantMethodTypeEntry <: ConstantPoolEntry
    descriptor::String
end

function claimed!(info::ConstantMethodTypeEntry, pool::Class)
    claim!(pool, ConstantUTF8Entry(info.descriptor))
end

function released!(info::ConstantMethodTypeEntry, pool::Class)
    release!(pool, ConstantUTF8Entry(info.descriptor))
end

# TODO: invokedynamic

end