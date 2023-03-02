module Mutable

import ..Bytes

abstract type ConstantPoolEntry end

struct ConstantPool
    entries::Dict{ConstantPoolEntry,Integer}
end

function claimed!(::ConstantPoolEntry, ::ConstantPool) end
function released!(::ConstantPoolEntry, ::ConstantPool) end

function claim!(pool::ConstantPool, entry::ConstantPoolEntry)
    if haskey(pool.entries, entry)
        pool.entries[entry] += 1
    else
        pool.entries[entry] = 1
        claimed!(entry, pool)
        1
    end
end

function release!(pool::ConstantPool, entry::ConstantPoolEntry)
    if haskey(pool.entries, entry)
        pool.entries[entry] -= 1
        if pool.entries[entry] == 0
            delete!(pool.entries, entry)
            released!(entry, pool)
            return
        end
    else
        error("Entry $(entry) not found in constant pool!")
    end
end

struct ClassEntry <: ConstantPoolEntry
    name::String
end

function claimed!(class::ClassEntry, pool::ConstantPool)
    claim!(pool, StringEntry(class.name))
end

function released!(class::ClassEntry, pool::ConstantPool)
    release!(pool, StringEntry(class.name))
end

struct StringEntry <: ConstantPoolEntry
    value::String
end

end