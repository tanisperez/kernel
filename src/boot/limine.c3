module kernel::boot;

import kernel::cpu;
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

fn bool is_limine_base_revision_not_supported() @private {
    return limine_base_revision[2] != 0;
}

fn void validate_limine_boot() {
    // Ensure the bootloader actually understands our base revision (see spec).
    if (is_limine_base_revision_not_supported()) {
        cpu::halt_and_catch_fire();
    }

    // Ensure we got a framebuffer.
    if (framebuffer_request.response == null || framebuffer_request.response.framebuffer_count < 1) {
        cpu::halt_and_catch_fire();
    }
}