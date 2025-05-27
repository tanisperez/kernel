module kernel::cpu;

import kernel::types;

const int NUM_GDT_ENTRIES = 7;
const int GDT_KERNEL_CODE = 40;
const int GDT_KERNEL_DATA = 48;
const int GDT_USER_CODE = 80;
const int GDT_USER_DATA = 72;
const int GDT_TSS = 80;

// Access byte
const UInt8 ACCESS_PRESENT     = 1 << 7;
const UInt8 ACCESS_PRIV_RING0  = 0 << 5;
const UInt8 ACCESS_PRIV_RING3  = 3 << 5;
const UInt8 ACCESS_SEGMENT     = 1 << 4;
const UInt8 ACCESS_EXECUTABLE  = 1 << 3;
const UInt8 ACCESS_RW          = 1 << 1;
const UInt8 ACCESS_ACCESSED    = 1 << 0;
const UInt8 ACCESS_TSS         = 0b10001001;

// Granularity byte
const UInt8 GRANULARITY_4K     = 1 << 7;
const UInt8 GRANULARITY_32BIT  = 1 << 6; // Ignored in long mode
const UInt8 GRANULARITY_LONG   = 1 << 5; // Bit L: Long mode (64 bits)
const UInt8 GRANULARITY_AVL    = 1 << 4;

struct GDTEntry @packed {
    UInt16 limit;
    UInt16 base_low;
    UInt8 base_middle;
    UInt8 access;
    UInt8 granularity;
    UInt8 base_high;
}

struct GDTPointer @packed {
    UInt16 limit;
    UInt64 base;
}

struct TSSEntry @packed {
    UInt16 length;
    UInt16 base_low;
    UInt8 base_middle;
    UInt8 access;
    UInt8 granularity;
    UInt8 base_high;
    UInt32 base_upper32;
    UInt32 reserved; // must be zero
}

struct TSSPtr @packed {
    UInt32 unused0;
    UInt64 rsp0;
    UInt64 rsp1;
    UInt64 rsp2;
    UInt64 unused1;
    UInt64 ist1;
    UInt64 ist2;
    UInt64 ist3;
    UInt64 ist4;
    UInt64 ist5;
    UInt64 ist6;
    UInt64 ist7;
    UInt64 unused2;
    UInt32 iopb;
}

struct GDTEntries @packed {
    GDTEntry[5] descriptors;
    TSSEntry tss;
}

struct GDTPtr @packed {
    UInt16 limit;
    UInt64 base;
}

GDTEntries gdt;
GDTPtr gdtr;
TSSPtr tss;

fn void init_gdt() {
    // Null descriptor
    gdt.descriptors[0].limit = 0;
    gdt.descriptors[0].base_low = 0;
    gdt.descriptors[0].base_middle = 0;
    gdt.descriptors[0].access = 0;
    gdt.descriptors[0].granularity = 0;
    gdt.descriptors[0].base_high = 0;

    // Kernel Code Segment
    gdt.descriptors[1].limit = 0x0000; // Ignored in long mode
    gdt.descriptors[1].base_low = 0;
    gdt.descriptors[1].base_middle = 0;
    gdt.descriptors[1].access = ACCESS_PRESENT | ACCESS_PRIV_RING0 | ACCESS_SEGMENT | ACCESS_EXECUTABLE | ACCESS_RW;
    gdt.descriptors[1].granularity = GRANULARITY_LONG;
    gdt.descriptors[1].base_high = 0;

    // Kernel Data Segment
    gdt.descriptors[2].limit = 0x0000;
    gdt.descriptors[2].base_low = 0;
    gdt.descriptors[2].base_middle = 0;
    gdt.descriptors[2].access = ACCESS_PRESENT | ACCESS_PRIV_RING0 | ACCESS_SEGMENT | ACCESS_RW;
    gdt.descriptors[2].granularity = 0;
    gdt.descriptors[2].base_high = 0;

    // User Code Segment
    gdt.descriptors[3].limit = 0x0000;
    gdt.descriptors[3].base_low = 0;
    gdt.descriptors[3].base_middle = 0;
    gdt.descriptors[3].access = ACCESS_PRESENT | ACCESS_PRIV_RING3 | ACCESS_SEGMENT | ACCESS_EXECUTABLE | ACCESS_RW;
    gdt.descriptors[3].granularity = GRANULARITY_LONG;
    gdt.descriptors[3].base_high = 0;

    // User Data Segment
    gdt.descriptors[4].limit = 0x0000;
    gdt.descriptors[4].base_low = 0;
    gdt.descriptors[4].base_middle = 0;
    gdt.descriptors[4].access = ACCESS_PRESENT | ACCESS_PRIV_RING3 | ACCESS_SEGMENT | ACCESS_RW;
    gdt.descriptors[4].granularity = 0;
    gdt.descriptors[4].base_high = 0;

    // Task State Segment
    UInt64 tss_base = (UInt64)&tss;
    gdt.tss.length = TSSPtr.sizeof - 1;
    gdt.tss.base_low = (UInt16)(tss_base & 0xFFFF);
    gdt.tss.base_middle = (UInt8)((tss_base >> 16) & 0xFF);
    gdt.tss.access = ACCESS_TSS; // 0x89
    gdt.tss.granularity = (UInt8)((gdt.tss.length >> 16) & 0x0F);
    gdt.tss.base_high = (UInt8)((tss_base >> 24) & 0xFF);
    gdt.tss.base_upper32 = (UInt32)((tss_base >> 32) & 0xFFFFFFFF);
    gdt.tss.reserved = 0;

    // Create the table descriptor
    gdtr.limit = GDTEntries.sizeof - 1;
    gdtr.base = (UInt64)&gdt;

    // Clean up the TSS (for security)
    // FIXME: I think it's not necessary in C3...
    //TODO: memset(&tss, 0, sizeof(TSSPtr));
    tss.iopb = TSSPtr.sizeof;

    // Load the GDT
    gdt_reload(&gdtr);
    // Load the TSS
    gdt_load_tss(0x28); // 0x28 = TSS selector (5 entries * 8 bytes)
}
