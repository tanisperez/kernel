#include <stdint.h>

uint8_t inb(uint16_t port) {
    uint8_t data;
    __asm__ __volatile__("inb %1, %0" : "=a"(data) : "dN"(port));
    return data;
}

void outb(uint16_t port, uint8_t data) {
    __asm__ __volatile__("outb %1, %0" : : "dN"(port), "a"(data));
}

void gdt_reload(void* gdtr) {
    asm volatile (
        "lgdt (%0)\n\t"               // Load GDTR from memory
        "pushq $0x08\n\t"             // Code selector (index 1 = 0x08)
        "leaq 1f(%%rip), %%rax\n\t"   // Load return address
        "pushq %%rax\n\t"             // Long jumpt to reload CS
        "lretq\n\t"
        "1:\n\t"
        "mov $0x10, %%ax\n\t"         // Data selector (index 2 = 0x10)
        "mov %%ax, %%ds\n\t"
        "mov %%ax, %%es\n\t"
        "mov %%ax, %%fs\n\t"
        "mov %%ax, %%gs\n\t"
        "mov %%ax, %%ss\n\t"
        :
        : "r"(gdtr)
        : "rax", "memory"
    );
}

void gdt_load_tss(uint16_t selector) {
    asm volatile (
        "ltr %0"
        :
        : "r"(selector)
        : "memory"
    );
}

