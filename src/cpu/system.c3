module kernel::cpu;

import kernel::types;

extern fn UInt8 inb(UInt16 port);
extern fn void outb(UInt16 port, UInt8 data);

fn void halt_and_catch_fire() {
    asm("hlt");
}