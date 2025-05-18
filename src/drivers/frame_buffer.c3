module kernel::drivers;

import kernel::types;
import kernel::cpu;
import kernel::boot;

struct FrameBuffer {
    void * address;
    UInt64 phys; // TODO: improve name

    UInt64 width;
    UInt64 height;

    UInt16 bpp;
    UInt64 pitch;

    UInt8 red_mask_size;
    UInt8 red_mask_shift;
    UInt8 green_mask_size;
    UInt8 green_mask_shift;
    UInt8 blue_mask_size;
    UInt8 blue_mask_shift;
}

fn FrameBuffer create_frame_buffer() {
    LimineFramebuffer * limine_frame_buffer = kernel::boot::framebuffer_request.response.framebuffers[0];

    FrameBuffer frame_buffer = {
        limine_frame_buffer.address,
        0, // TODO: TBD
        limine_frame_buffer.width,
        limine_frame_buffer.height,
        limine_frame_buffer.bpp,
        limine_frame_buffer.pitch,
        limine_frame_buffer.red_mask_size,
        limine_frame_buffer.red_mask_shift,
        limine_frame_buffer.green_mask_size,
        limine_frame_buffer.green_mask_shift,
        limine_frame_buffer.blue_mask_size,
        limine_frame_buffer.blue_mask_shift
    };

    return frame_buffer;
}
