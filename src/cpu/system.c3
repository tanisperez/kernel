module kernel::cpu;

import kernel::types;

extern fn UInt8 inb(UInt16 port);
extern fn void outb(UInt16 port, UInt8 data);
extern fn void gdt_reload(void * gdtr);
extern fn void gdt_load_tss(UInt16 selector);

fn void halt_and_catch_fire() {
    asm("hlt");
}