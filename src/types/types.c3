module kernel::types;

typedef UInt8 = char;
typedef Int8 = ichar;

fn void foo() @export("foo")
{
    UInt8 i = 5;
    UInt8 j = 4;
    UInt8 result = i + j;
}