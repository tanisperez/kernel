module kernel::core::system;

import kernel::types;

extern fn UInt8 inb(UInt16 port);
extern fn void outb(UInt16 port, UInt8 data);