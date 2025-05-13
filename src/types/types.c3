module kernel::types;

alias Int8 = ichar;
alias UInt8 = char;
alias Int16 = short;
alias UInt16 = ushort;
alias Int32 = int;
alias UInt32 = uint;
alias Int64 = long;
alias UInt64 = ulong;
alias Int128 = int128;
alias UInt128 = uint128;

fn void foo() @export("foo")
{
    UInt8 i = 5;
    UInt8 j = 4;
    UInt8 result = i + j;
}