module kernel::types;

typedef Int8 = ichar;
typedef UInt8 = char;
typedef Int16 = short;
typedef UInt16 = ushort;
typedef Int32 = int;
typedef UInt32 = uint;
typedef Int64 = long;
typedef UInt64 = ulong;
typedef Int128 = int128;
typedef UInt128 = uint128;

fn void foo() @export("foo")
{
    UInt8 i = 5;
    UInt8 j = 4;
    UInt8 result = i + j;
}