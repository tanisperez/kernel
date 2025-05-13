module kernel;

import kernel::types;

struct LimineVideoMode {
    UInt64 pitch;
    UInt64 width;
    UInt64 height;
    UInt16 bpp;
    UInt8 memory_model;
    UInt8 red_mask_size;
    UInt8 red_mask_shift;
    UInt8 green_mask_size;
    UInt8 green_mask_shift;
    UInt8 blue_mask_size;
    UInt8 blue_mask_shift;
}

struct LimineFramebuffer {
    void * address;
    UInt64 width;
    UInt64 height;
    UInt64 pitch;
    UInt16 bpp;
    UInt8 memory_model;
    UInt8 red_mask_size;
    UInt8 red_mask_shift;
    UInt8 green_mask_size;
    UInt8 green_mask_shift;
    UInt8 blue_mask_size;
    UInt8 blue_mask_shift;
    UInt8[7] unused;
    UInt64 edid_size;
    void * edid;
    /* Response revision 1 */
    UInt64 mode_count;
    LimineVideoMode ** modes;
}

struct LimineFramebufferResponse {
    UInt64 revision;
    UInt64 framebuffer_count;
    LimineFramebuffer ** framebuffers;
}

struct LimineFramebufferRequest {
    UInt64[4] id;
    UInt64 revision;
    LimineFramebufferResponse * response;
}

extern UInt64[3] limine_base_revision;
extern LimineFramebufferRequest framebuffer_request;

fn bool is_limine_base_revision_not_supported() {
    return limine_base_revision[2] != 0;
}

fn void halt_and_catch_fire() {
    asm("hlt");
}

fn void kmain() @export("kmain") {
    // Ensure the bootloader actually understands our base revision (see spec).
    if (is_limine_base_revision_not_supported()) {
        halt_and_catch_fire();
    }

    // Ensure we got a framebuffer.
    if (framebuffer_request.response == null || framebuffer_request.response.framebuffer_count < 1) {
        halt_and_catch_fire();
    }

    // Fetch the first framebuffer.
    LimineFramebuffer *framebuffer = framebuffer_request.response.framebuffers[0];

    // Note: we assume the framebuffer model is RGB with 32-bit pixels.
    for (int i = 0; i < 100; i++) {
        UInt32 *fb_ptr = framebuffer.address;
        fb_ptr[i * (framebuffer.pitch / 4) + i] = 0xFF0000;
    }

    // We're done, just hang...
    halt_and_catch_fire();
}