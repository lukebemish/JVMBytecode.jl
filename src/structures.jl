module Bytes

import Base: read, write, float, Integer, UInt8, String

primitive type ConstantPoolTag 8 end
ConstantPoolTag(x) = reinterpret(ConstantPoolTag, UInt8(x))
UInt8(x::ConstantPoolTag) = reinterpret(UInt8, x)

CONSTANT_CLASS = ConstantPoolTag(7)
CONSTANT_FIELDREF = ConstantPoolTag(9)
CONSTANT_METHODREF = ConstantPoolTag(10)
CONSTANT_INTERFACEMETHODREF = ConstantPoolTag(11)
CONSTANT_STRING = ConstantPoolTag(8)
CONSTANT_INTEGER = ConstantPoolTag(3)
CONSTANT_FLOAT = ConstantPoolTag(4)
CONSTANT_LONG = ConstantPoolTag(5)
CONSTANT_DOUBLE = ConstantPoolTag(6)
CONSTANT_NAMEANDTYPE = ConstantPoolTag(12)
CONSTANT_UTF8 = ConstantPoolTag(1)
CONSTANT_METHODHANDLE = ConstantPoolTag(15)
CONSTANT_METHODTYPE = ConstantPoolTag(16)
CONSTANT_INVOKEDYNAMIC = ConstantPoolTag(18)

function write(io::IO, tag::ConstantPoolTag)
    write(io, hton(UInt8(tag)))
end

function read(io::IO, ::Type{ConstantPoolTag})
    ConstantPoolTag(ntoh(read(io, UInt8)))
end

abstract type ConstantInfo{ConstantPoolTag} end

struct ConstantClassInfo <: ConstantInfo{CONSTANT_CLASS}
    nameindex::UInt16
end

function write(io::IO, info::ConstantClassInfo)
    write(io, CONSTANT_CLASS)
    write(io, hton(info.nameindex))
end

function read(io::IO, ::Type{ConstantClassInfo})
    ConstantClassInfo(ntoh(read(io, UInt16)))
end

struct ConstantFieldrefInfo <: ConstantInfo{CONSTANT_FIELDREF}
    classindex::UInt16
    nameandtypeindex::UInt16
end

function write(io::IO, info::ConstantFieldrefInfo)
    write(io, CONSTANT_FIELDREF)
    write(io, hton(info.classindex))
    write(io, hton(info.nameandtypeindex))
end

function read(io::IO, ::Type{ConstantFieldrefInfo})
    ConstantFieldrefInfo(ntoh(read(io, UInt16)), ntoh(read(io, UInt16)))
end

struct ConstantMethodrefInfo <: ConstantInfo{CONSTANT_METHODREF}
    classindex::UInt16
    nameandtypeindex::UInt16
end

function write(io::IO, info::ConstantMethodrefInfo)
    write(io, CONSTANT_METHODREF)
    write(io, hton(info.classindex))
    write(io, hton(info.nameandtypeindex))
end

function read(io::IO, ::Type{ConstantMethodrefInfo})
    ConstantMethodrefInfo(ntoh(read(io, UInt16)), ntoh(read(io, UInt16)))
end

struct ConstantInterfaceMethodrefInfo <: ConstantInfo{CONSTANT_INTERFACEMETHODREF}
    classindex::UInt16
    nameandtypeindex::UInt16
end

function write(io::IO, info::ConstantInterfaceMethodrefInfo)
    write(io, CONSTANT_INTERFACEMETHODREF)
    write(io, hton(info.classindex))
    write(io, hton(info.nameandtypeindex))
end

function read(io::IO, ::Type{ConstantInterfaceMethodrefInfo})
    ConstantInterfaceMethodrefInfo(ntoh(read(io, UInt16)), ntoh(read(io, UInt16)))
end

struct ConstantStringInfo <: ConstantInfo{CONSTANT_STRING}
    stringindex::UInt16
end

function write(io::IO, info::ConstantStringInfo)
    write(io, CONSTANT_STRING)
    write(io, hton(info.stringindex))
end

function read(io::IO, ::Type{ConstantStringInfo})
    ConstantStringInfo(ntoh(read(io, UInt16)))
end

struct ConstantIntegerInfo <: ConstantInfo{CONSTANT_INTEGER}
    bytes::Int32
end

function write(io::IO, info::ConstantIntegerInfo)
    write(io, CONSTANT_INTEGER)
    write(io, hton(info.bytes))
end

function read(io::IO, ::Type{ConstantIntegerInfo})
    ConstantIntegerInfo(ntoh(read(io, Int32)))
end

struct ConstantFloatInfo <: ConstantInfo{CONSTANT_FLOAT}
    bytes::Float32
end

function write(io::IO, info::ConstantFloatInfo)
    write(io, CONSTANT_FLOAT)
    write(io, hton(info.bytes))
end

function read(io::IO, ::Type{ConstantFloatInfo})
    ConstantFloatInfo(ntoh(read(io, Float32)))
end

struct ConstantLongInfo <: ConstantInfo{CONSTANT_LONG}
    highbytes::UInt32
    lowbytes::UInt32
end

function write(io::IO, info::ConstantLongInfo)
    write(io, CONSTANT_LONG)
    write(io, hton(info.highbytes))
    write(io, hton(info.lowbytes))
end

function read(io::IO, ::Type{ConstantLongInfo})
    ConstantLongInfo(ntoh(read(io, UInt32)), ntoh(read(io, UInt32)))
end

Integer(info::ConstantLongInfo) = Int64(info.highbytes)<<32 + Int64(info.lowbytes)

struct ConstantDoubleInfo <: ConstantInfo{CONSTANT_DOUBLE}
    highbytes::UInt32
    lowbytes::UInt32
end

float(info::ConstantDoubleInfo) = Float64(info.highbytes)<<32 + Float64(info.lowbytes)

function write(io::IO, info::ConstantDoubleInfo)
    write(io, CONSTANT_DOUBLE)
    write(io, hton(info.highbytes))
    write(io, hton(info.lowbytes))
end

function read(io::IO, ::Type{ConstantDoubleInfo})
    ConstantDoubleInfo(ntoh(read(io, UInt32)), ntoh(read(io, UInt32)))
end

struct ConstantNameAndTypeInfo <: ConstantInfo{CONSTANT_NAMEANDTYPE}
    nameindex::UInt16
    descriptorindex::UInt16
end

function write(io::IO, info::ConstantNameAndTypeInfo)
    write(io, CONSTANT_NAMEANDTYPE)
    write(io, hton(info.nameindex))
    write(io, hton(info.descriptorindex))
end

function read(io::IO, ::Type{ConstantNameAndTypeInfo})
    ConstantNameAndTypeInfo(ntoh(read(io, UInt16)), ntoh(read(io, UInt16)))
end

struct ConstantUtf8Info <: ConstantInfo{CONSTANT_UTF8}
    length::UInt16
    bytes::Vector{UInt8}
end

function String(info::ConstantUtf8Info)
    javastring(info.bytes)
end

function javastring(bytes::Vector{UInt8})
    chars = Char[]
    index = 1
    while index <= length(bytes)
        byte = bytes[index]; index += 1
        if byte >> 7 == 0
            push!(chars, Char(byte))
        elseif byte >> 5 == 0b110
            if length(bytes) < 1 || bytes[1] >> 6 != 0b10
                throw(ArgumentError("Invalid Java UTF-8 encoding"))
            end
            byte2 = bytes[index]; index += 1
            char = (UInt16(byte) & 0x1F) << 6 | (UInt16(byte2) & 0x3F)
            push!(chars, Char(char))
        elseif byte >> 4 == 0b1110
            if length(bytes) < 2 || bytes[1] >> 6 != 0b10 || bytes[2] >> 6 != 0b10
                throw(ArgumentError("Invalid Java UTF-8 encoding"))
            end
            byte2 = bytes[index]; index += 1
            byte3 = bytes[index]; index += 1
            char = (UInt16(byte) & 0x0F) << 12 | (UInt16(byte2) & 0x3F) << 6 | (UInt16(byte3) & 0x3F)
            push!(chars, Char(char))
        else
            throw(ArgumentError("Invalid Java UTF-8 encoding"))
        end
    end
    return String(chars)
end

function write(io::IO, info::ConstantUtf8Info)
    write(io, CONSTANT_UTF8)
    write(io, hton(info.length))
    write(io, info.bytes)
end

function read(io::IO, ::Type{ConstantUtf8Info})
    length = ntoh(read(io, UInt16))
    bytes = [read(io, UInt8) for _ in 1:length]
    ConstantUtf8Info(length, bytes)
end

struct ConstantMethodHandleInfo <: ConstantInfo{CONSTANT_METHODHANDLE}
    referencekind::UInt8
    referenceindex::UInt16
end

function write(io::IO, info::ConstantMethodHandleInfo)
    write(io, CONSTANT_METHODHANDLE)
    write(io, hton(info.referencekind))
    write(io, hton(info.referenceindex))
end

function read(io::IO, ::Type{ConstantMethodHandleInfo})
    ConstantMethodHandleInfo(ntoh(read(io, UInt8)), ntoh(read(io, UInt16)))
end

struct ConstantMethodTypeInfo <: ConstantInfo{CONSTANT_METHODTYPE}
    descriptorindex::UInt16
end

function write(io::IO, info::ConstantMethodTypeInfo)
    write(io, CONSTANT_METHODTYPE)
    write(io, hton(info.descriptorindex))
end

function read(io::IO, ::Type{ConstantMethodTypeInfo})
    ConstantMethodTypeInfo(ntoh(read(io, UInt16)))
end

struct ConstantInvokeDynamicInfo <: ConstantInfo{CONSTANT_INVOKEDYNAMIC}
    bootstrapmethodattrindex::UInt16
    nameandtypeindex::UInt16
end

function write(io::IO, info::ConstantInvokeDynamicInfo)
    write(io, CONSTANT_INVOKEDYNAMIC)
    write(io, hton(info.bootstrapmethodattrindex))
    write(io, hton(info.nameandtypeindex))
end

function read(io::IO, ::Type{ConstantInvokeDynamicInfo})
    ConstantInvokeDynamicInfo(ntoh(read(io, UInt16)), ntoh(read(io, UInt16)))
end

function read(io::IO, ::Type{ConstantInfo})
    tag = ConstantPoolTag(ntoh(read(io, UInt8)))
    if tag == CONSTANT_UTF8
        read(io, ConstantUtf8Info)
    elseif tag == CONSTANT_INTEGER
        read(io, ConstantIntegerInfo)
    elseif tag == CONSTANT_FLOAT
        read(io, ConstantFloatInfo)
    elseif tag == CONSTANT_LONG
        read(io, ConstantLongInfo)
    elseif tag == CONSTANT_DOUBLE
        read(io, ConstantDoubleInfo)
    elseif tag == CONSTANT_CLASS
        read(io, ConstantClassInfo)
    elseif tag == CONSTANT_STRING
        read(io, ConstantStringInfo)
    elseif tag == CONSTANT_FIELDREF
        read(io, ConstantFieldrefInfo)
    elseif tag == CONSTANT_METHODREF
        read(io, ConstantMethodrefInfo)
    elseif tag == CONSTANT_INTERFACEMETHODREF
        read(io, ConstantInterfaceMethodrefInfo)
    elseif tag == CONSTANT_NAMEANDTYPE
        read(io, ConstantNameAndTypeInfo)
    elseif tag == CONSTANT_METHODHANDLE
        read(io, ConstantMethodHandleInfo)
    elseif tag == CONSTANT_METHODTYPE
        read(io, ConstantMethodTypeInfo)
    elseif tag == CONSTANT_INVOKEDYNAMIC
        read(io, ConstantInvokeDynamicInfo)
    else
        throw(ArgumentError("Invalid constant pool tag $(tag)"))
    end
end

struct AttributeInfo
    attributenameindex::UInt16
    info::Vector{UInt8}
end

function write(io::IO, info::AttributeInfo)
    write(io, hton(info.attributenameindex))
    write(io, hton(UInt32(length(info.info))))
    for byte in info.info
        write(io, hton(byte))
    end
end

function read(io::IO, ::Type{AttributeInfo})
    attributenameindex = ntoh(read(io, UInt16))
    attributecount = ntoh(read(io, UInt32))
    info = [ntoh(read(io, UInt8)) for _ in 1:attributecount]
    AttributeInfo(attributenameindex, info)
end

struct FieldInfo
    accessflags::UInt16
    nameindex::UInt16
    descriptorindex::UInt16
    attributes::Vector{AttributeInfo}
end

function write(io::IO, info::FieldInfo)
    write(io, hton(info.accessflags))
    write(io, hton(info.nameindex))
    write(io, hton(info.descriptorindex))
    write(io, hton(UInt16(length(info.attributes))))
    for attr in info.attributes
        write(io, attr)
    end
end

function read(io::IO, ::Type{FieldInfo})
    accessflags = ntoh(read(io, UInt16))
    nameindex = ntoh(read(io, UInt16))
    descriptorindex = ntoh(read(io, UInt16))
    attributescount = ntoh(read(io, UInt16))
    attributes = [read(io, AttributeInfo) for _ in 1:attributescount]
    FieldInfo(accessflags, nameindex, descriptorindex, attributes)
end

struct MethodInfo
    accessflags::UInt16
    nameindex::UInt16
    descriptorindex::UInt16
    attributes::Vector{AttributeInfo}
end

function write(io::IO, info::MethodInfo)
    write(io, hton(info.accessflags))
    write(io, hton(info.nameindex))
    write(io, hton(info.descriptorindex))
    write(io, hton(UInt16(length(info.attributes))))
    for attr in info.attributes
        write(io, attr)
    end
end

function read(io::IO, ::Type{MethodInfo})
    accessflags = ntoh(read(io, UInt16))
    nameindex = ntoh(read(io, UInt16))
    descriptorindex = ntoh(read(io, UInt16))
    attributescount = ntoh(read(io, UInt16))
    attributes = [read(io, AttributeInfo) for _ in 1:attributescount]
    MethodInfo(accessflags, nameindex, descriptorindex, attributes)
end

struct ClassFile
    minorversion::UInt16
    majorversion::UInt16
    constantpoolinfo::Vector{ConstantInfo}
    accessflags::UInt16
    thisclass::UInt16
    superclass::UInt16
    interfaces::Vector{UInt16}
    fields::Vector{FieldInfo}
    methods::Vector{MethodInfo}
    attributes::Vector{AttributeInfo}
end

function write(io::IO, class::ClassFile)
    write(io, hton(0xCAFEBABE))
    write(io, hton(class.minorversion))
    write(io, hton(class.majorversion))
    write(io, hton(UInt16(length(class.constantpoolinfo) + 1)))
    for info in class.constantpoolinfo
        write(io, info)
    end
    write(io, hton(class.accessflags))
    write(io, hton(class.thisclass))
    write(io, hton(class.superclass))
    write(io, hton(UInt16(length(class.interfaces))))
    for interface in class.interfaces
        write(io, hton(interface))
    end
    write(io, hton(UInt16(length(class.fields))))
    for field in class.fields
        write(io, field)
    end
    write(io, hton(UInt16(length(class.methods))))
    for method in class.methods
        write(io, method)
    end
    write(io, hton(UInt16(length(class.attributes))))
    for attribute in class.attributes
        write(io, attribute)
    end
end

function read(io::IO, ::Type{ClassFile})
    magic = ntoh(read(io, UInt32))
    if magic != 0xCAFEBABE
        throw(ArgumentError("Invalid magic number $(magic)"))
    end
    minorversion = ntoh(read(io, UInt16))
    majorversion = ntoh(read(io, UInt16))
    constantpoolcount = ntoh(read(io, UInt16))
    constantpoolinfo = [read(io, ConstantInfo) for _ in 1:constantpoolcount-1]
    accessflags = ntoh(read(io, UInt16))
    thisclass = ntoh(read(io, UInt16))
    superclass = ntoh(read(io, UInt16))
    interfacescount = ntoh(read(io, UInt16))
    interfaces = [ntoh(read(io, UInt16)) for _ in 1:interfacescount]
    fieldscount = ntoh(read(io, UInt16))
    fields = [read(io, FieldInfo) for _ in 1:fieldscount]
    methodscount = ntoh(read(io, UInt16))
    methods = [read(io, MethodInfo) for _ in 1:methodscount]
    attributescount = ntoh(read(io, UInt16))
    attributes = [read(io, AttributeInfo) for _ in 1:attributescount]
    ClassFile(
        minorversion,
        majorversion,
        constantpoolinfo,
        accessflags,
        thisclass,
        superclass,
        interfaces,
        fields,
        methods,
        attributes
    )
end

end