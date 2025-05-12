module kernel;

fn void halt_and_catch_fire() @export("halt_and_catch_fire")
{
    asm("hlt");
}

struct LimineVideoMode {
    ulong pitch;
    ulong width;
    ulong height;
    ushort bpp;
    char memory_model;
    char red_mask_size;
    char red_mask_shift;
    char green_mask_size;
    char green_mask_shift;
    char blue_mask_size;
    char blue_mask_shift;
}

struct LimineFramebuffer {
    void * address;
    ulong width;
    ulong height;
    ulong pitch;
    ushort bpp;
    char memory_model;
    char red_mask_size;
    char red_mask_shift;
    char green_mask_size;
    char green_mask_shift;
    char blue_mask_size;
    char blue_mask_shift;
    char[7] unused;
    ulong edid_size;
    void * edid;
    /* Response revision 1 */
    ulong mode_count;
    LimineVideoMode ** modes;
}

struct LimineFramebufferResponse {
    ulong revision;
    ulong framebuffer_count;
    LimineFramebuffer ** framebuffers;
}

struct LimineFramebufferRequest {
    ulong[4] id;
    ulong revision;
    LimineFramebufferResponse * response;
}

extern ulong[3] limine_base_revision;
extern LimineFramebufferRequest framebuffer_request;

fn bool is_limine_base_revision_not_supported()
{
    return limine_base_revision[2] != 0;
}

// TODO:
// ***********************************************
// Estraer las variables del código C apuntando a la dirección de memoria correspondiente

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
        uint *fb_ptr = framebuffer.address;
        fb_ptr[i * (framebuffer.pitch / 4) + i] = 0xFF0000;
    }

    // We're done, just hang...
    halt_and_catch_fire();
}