module kernel;

import kernel::boot;
import kernel::drivers;
import kernel::cpu;

fn void kmain() @export("kmain") {
    boot::validate_limine_boot();

    // Fetch the first framebuffer.
    LimineFramebuffer *framebuffer = kernel::boot::framebuffer_request.response.framebuffers[0];

    // Note: we assume the framebuffer model is RGB with 32-bit pixels.
    for (int i = 0; i < 100; i++) {
        UInt32 *fb_ptr = framebuffer.address;
        fb_ptr[i * (framebuffer.pitch / 4) + i] = 0xFF0000;
    }

    Serial serial = { SerialPort.COM1 };
    serial.enable();
    serial.writeln("[Serial] COM1 port is ready");
    serial.writeln("Kernel up and running!");

    // We're done, just hang...
    cpu::halt_and_catch_fire();
}