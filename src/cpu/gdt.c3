module kernel::cpu;

import kernel::types;

// Access Byte Flags (for segment and system descriptors)
// ----------------------------------------------------------------------------
// | Bit | Nombre         | Significado                                        |
// | --- | -------------- | -------------------------------------------------- |
// | 7   | P (Present)    | Segment is present in memory                       |
// | 6–5 | DPL            | Descriptor Privilege Level (Ring 0–3)              |
// | 4   | S (Descriptor) | 1 = Code/Data, 0 = System segment (e.g., TSS, LDT) |
// | 3   | E (Executable) | 1 = Code, 0 = Data                                 |
// | 2   | DC             | Direction (data) / Conforming (code)               |
// | 1   | RW             | Writable (data) / Readable (code)                  |
// | 0   | A (Accessed)   | Set by CPU when the segment is accessed            |
// ----------------------------------------------------------------------------
const UInt8 ACCESS_ACCESSED     = 1 << 0; // Bit 0: Accessed (set by CPU when used)
const UInt8 ACCESS_RW           = 1 << 1; // Bit 1: Readable (code) / Writable (data)
const UInt8 ACCESS_DIRECTION    = 1 << 2; // Bit 2: Direction (data) / Conforming (code) — usually 0 in long mode
const UInt8 ACCESS_EXECUTABLE   = 1 << 3; // Bit 3: 1 = Code segment, 0 = Data segment
const UInt8 ACCESS_SEGMENT      = 1 << 4; // Bit 4: 1 = Code/Data segment, 0 = System descriptor
// Descriptor Privilege Level (DPL), bits [6:5]
const UInt8 ACCESS_PRIV_RING0   = 0 << 5; // Ring 0 (highest privilege)
const UInt8 ACCESS_PRIV_RING1   = 1 << 5; // Ring 1
const UInt8 ACCESS_PRIV_RING2   = 2 << 5; // Ring 2
const UInt8 ACCESS_PRIV_RING3   = 3 << 5; // Ring 3 (user mode)
const UInt8 ACCESS_PRESENT      = 1 << 7; // Bit 7: Segment present in memory

// ACCESS_TSS = 0x89 (10001001)
const UInt8 ACCESS_TSS          = ACCESS_PRESENT
                                | ACCESS_PRIV_RING0
                                | ACCESS_ACCESSED
                                | 0x08; // Type 1000 (TSS Available)

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
    gdt.descriptors[1].limit = 0x0000;  // Ignored in long mode
    gdt.descriptors[1].base_low = 0;    // Ignored in long mode
    gdt.descriptors[1].base_middle = 0; // Ignored in long mode
    gdt.descriptors[1].access = ACCESS_PRESENT | ACCESS_PRIV_RING0 | ACCESS_SEGMENT | ACCESS_EXECUTABLE | ACCESS_RW;
    gdt.descriptors[1].granularity = GRANULARITY_4K | GRANULARITY_LONG;
    gdt.descriptors[1].base_high = 0;   // Ignored in long mode

    // Kernel Data Segment
    gdt.descriptors[2].limit = 0x0000;  // Ignored in long mode
    gdt.descriptors[2].base_low = 0;    // Ignored in long mode
    gdt.descriptors[2].base_middle = 0; // Ignored in long mode
    gdt.descriptors[2].access = ACCESS_PRESENT | ACCESS_PRIV_RING0 | ACCESS_SEGMENT | ACCESS_RW;
    gdt.descriptors[2].granularity = GRANULARITY_4K;
    gdt.descriptors[2].base_high = 0;   // Ignored in long mode

    // User Code Segment
    gdt.descriptors[3].limit = 0x0000;  // Ignored in long mode
    gdt.descriptors[3].base_low = 0;    // Ignored in long mode
    gdt.descriptors[3].base_middle = 0; // Ignored in long mode
    gdt.descriptors[3].access = ACCESS_PRESENT | ACCESS_PRIV_RING3 | ACCESS_SEGMENT | ACCESS_EXECUTABLE | ACCESS_RW;
    gdt.descriptors[3].granularity = GRANULARITY_4K | GRANULARITY_LONG;
    gdt.descriptors[3].base_high = 0;   // Ignored in long mode

    // User Data Segment
    gdt.descriptors[4].limit = 0x0000;  // Ignored in long mode
    gdt.descriptors[4].base_low = 0;    // Ignored in long mode
    gdt.descriptors[4].base_middle = 0; // Ignored in long mode
    gdt.descriptors[4].access = ACCESS_PRESENT | ACCESS_PRIV_RING3 | ACCESS_SEGMENT | ACCESS_RW;
    gdt.descriptors[4].granularity = GRANULARITY_4K;
    gdt.descriptors[4].base_high = 0;   // Ignored in long mode

    // Task State Segment
    UInt64 tss_base = (UInt64)&tss;
    gdt.tss.length = TSSPtr.sizeof - 1;
    gdt.tss.base_low = (UInt16)(tss_base & 0xFFFF);
    gdt.tss.base_middle = (UInt8)((tss_base >> 16) & 0xFF);
    gdt.tss.access = ACCESS_TSS;
    gdt.tss.granularity = (UInt8)((gdt.tss.length >> 16) & 0x0F);
    gdt.tss.base_high = (UInt8)((tss_base >> 24) & 0xFF);
    gdt.tss.base_upper32 = (UInt32)((tss_base >> 32) & 0xFFFFFFFF);
    gdt.tss.reserved = 0;

    // Create the table descriptor
    gdtr.limit = GDTEntries.sizeof - 1;
    gdtr.base = (UInt64)&gdt;

    tss.iopb = TSSPtr.sizeof;

    // Load the GDT
    gdt_reload(&gdtr);
    // Load the TSS
    gdt_load_tss(0x28); // 0x28 = TSS selector (5 entries * 8 bytes)
}
