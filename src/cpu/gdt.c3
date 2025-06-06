module kernel::cpu;

import kernel::types;

/*
 * Global Descriptor Table (GDT) Setup for x86_64 Long Mode
 *
 * The Global Descriptor Table (GDT) is a data structure used by x86 CPUs to define
 * the characteristics of the various memory areas (segments) used during program
 * execution. These characteristics include the base address, size (limit), access
 * privileges, and type of segment.
 *
 * In 64-bit long mode, segmentation is mostly unused and flat memory model is assumed,
 * but the GDT is still required for:
 *   - Defining code and data segments with correct access bits.
 *   - Defining a Task State Segment (TSS) for kernel context switching.
 *
 * GDT Entry Format (64-bit mode):
 *
 * 63              56 55      52 51      48 47              40 39               32
 * +----------------+----------+----------+------------------+-------------------+
 * | Base 31:24     | Flags    | Limit19:16| Access Byte      | Base 23:16        |
 * +----------------+----------+----------+------------------+-------------------+
 * 31                             16 15                              0
 * +--------------------------------+--------------------------------+
 * | Base 15:0                      | Segment Limit 15:0             |
 * +--------------------------------+--------------------------------+
 *
 * Segment selectors (offsets into the GDT):
 *   0x00 - Null segment
 *   0x08 - Kernel Code segment
 *   0x10 - Kernel Data segment
 *   0x18 - User Code segment
 *   0x20 - User Data segment
 *   0x28 - TSS (Task State Segment)
 *
 * ASCII diagram of segment layout in GDT:
 *
 *  GDT Layout:
 *
 *  Index | Selector | Description
 *  ------+----------+------------------------
 *   0    | 0x00     | Null Segment
 *   1    | 0x08     | Kernel Code Segment
 *   2    | 0x10     | Kernel Data Segment
 *   3    | 0x18     | User Code Segment
 *   4    | 0x20     | User Data Segment
 *   5    | 0x28     | Task State Segment (TSS)
 *
 */

const UInt8 GDT_ENTRIES = 5;

enum GDTSegment: UInt8 (inline UInt8 address) {
    NULL = 0,
    KERNEL_CODE = 1,
    KERNEL_DATA = 2,
    USER_CODE = 3,
    USER_DATA = 4
}

// Access Byte Flags (for segment and system descriptors)
// ----------------------------------------------------------------------------
// | Bit | Name           | Usage                                              |
// | --- | -------------- | -------------------------------------------------- |
// | 7   | P (Present)    | Segment is present in memory                       |
// | 6–5 | DPL            | Descriptor Privilege Level (Ring 0–3)              |
// | 4   | S (Descriptor) | 1 = Code/Data, 0 = System segment (e.g., TSS, LDT) |
// | 3   | E (Executable) | 1 = Code, 0 = Data                                 |
// | 2   | DC             | Direction (data) / Conforming (code)               |
// | 1   | RW             | Writable (data) / Readable (code)                  |
// | 0   | A (Accessed)   | Set by CPU when the segment is accessed            |
// ----------------------------------------------------------------------------
const UInt8 ACCESS_ACCESSED     = 0b00000001; // Bit 0: Accessed
const UInt8 ACCESS_RW           = 0b00000010; // Bit 1: Readable (code) / Writable (data)
const UInt8 ACCESS_DIRECTION    = 0b00000100; // Bit 2: Direction (data) / Conforming (code)
const UInt8 ACCESS_EXECUTABLE   = 0b00001000; // Bit 3: 1 = Code, 0 = Data
const UInt8 ACCESS_SEGMENT      = 0b00010000; // Bit 4: 1 = Code/Data, 0 = System
const UInt8 ACCESS_PRIV_RING0   = 0b00000000; // Bits 5–6: DPL = 0
const UInt8 ACCESS_PRIV_RING1   = 0b00100000; // DPL = 1
const UInt8 ACCESS_PRIV_RING2   = 0b01000000; // DPL = 2
const UInt8 ACCESS_PRIV_RING3   = 0b01100000; // DPL = 3
const UInt8 ACCESS_PRESENT      = 0b10000000; // Bit 7: Present

// ACCESS_TSS = 0x89 (10001001)
const UInt8 ACCESS_TSS          = ACCESS_PRESENT
                                | ACCESS_PRIV_RING0
                                | ACCESS_ACCESSED
                                | 0x08; // Type 1000 (TSS Available)

// Granularity Byte (Flags) – Bits 0–7
// -------------------------------------------------------------------------------------------------------------------------
// | Bit | Name          | Usage                                                                                            |
// | --- | ------------- | ------------------------------------------------------------------------------------------------ |
// | 7   | G             | Granularity: 0 = byte granularity, 1 = 4 KiB granularity (limit \* 4K)                           |
// | 6   | D/B           | **Size bit**: 1 = 32-bit segment (in protected mode) / 0 = 16-bit segment (ignored in long mode) |
// | 5   | L             | **Long mode**: 1 = 64-bit code segment (only for code)                                           |
// | 4   | AVL           | **Available for software use**                                                                   |
// | 3–0 | Limit\[19:16] | High 4 bits of the segment limit (complementa los 16 bits del campo `limit`)                     |
// -------------------------------------------------------------------------------------------------------------------------
const UInt8 GRANULARITY_AVL     = 0b00010000; // Bit 4: Software use
const UInt8 GRANULARITY_LONG    = 0b00100000; // Bit 5: Long mode (64-bit)
const UInt8 GRANULARITY_32BIT   = 0b01000000; // Bit 6: 32-bit segment (protected mode)
const UInt8 GRANULARITY_4K      = 0b10000000; // Bit 7: 4 KiB granularity

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
    GDTEntry[GDT_ENTRIES] descriptors;
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
    gdt.descriptors[GDTSegment.NULL] = {
        .limit = 0,
        .base_low = 0,
        .base_middle = 0,
        .access = 0,
        .granularity = 0,
        .base_high = 0,
    };

    // Kernel Code Segment
    gdt.descriptors[GDTSegment.KERNEL_CODE] = {
        .limit        = 0x0000, // Ignored in long mode
        .base_low     = 0,      // Ignored in long mode
        .base_middle  = 0,      // Ignored in long mode
        .access       = ACCESS_PRESENT | ACCESS_PRIV_RING0 | ACCESS_SEGMENT | ACCESS_EXECUTABLE | ACCESS_RW,
        .granularity  = GRANULARITY_4K | GRANULARITY_LONG,
        .base_high    = 0,      // Ignored in long mode
    };

    // Kernel Data Segment
    gdt.descriptors[GDTSegment.KERNEL_DATA] = {
        .limit        = 0x0000, // Ignored in long mode
        .base_low     = 0,      // Ignored in long mode
        .base_middle  = 0,      // Ignored in long mode
        .access       = ACCESS_PRESENT | ACCESS_PRIV_RING0 | ACCESS_SEGMENT | ACCESS_RW,
        .granularity  = GRANULARITY_4K,
        .base_high    = 0,      // Ignored in long mode
    };

    // User Code Segment
    gdt.descriptors[GDTSegment.USER_CODE] = {
        .limit        = 0x0000, // Ignored in long mode
        .base_low     = 0,      // Ignored in long mode
        .base_middle  = 0,      // Ignored in long mode
        .access       = ACCESS_PRESENT | ACCESS_PRIV_RING3 | ACCESS_SEGMENT | ACCESS_EXECUTABLE | ACCESS_RW,
        .granularity  = GRANULARITY_4K | GRANULARITY_LONG,
        .base_high    = 0,      // Ignored in long mode
    };

    // User Data Segment
    gdt.descriptors[GDTSegment.USER_DATA] = {
        .limit        = 0x0000, // Ignored in long mode
        .base_low     = 0,      // Ignored in long mode
        .base_middle  = 0,      // Ignored in long mode
        .access       = ACCESS_PRESENT | ACCESS_PRIV_RING3 | ACCESS_SEGMENT | ACCESS_RW,
        .granularity  = GRANULARITY_4K,
        .base_high    = 0,      // Ignored in long mode
    };

    // Task State Segment
    UInt64 tss_base = (UInt64) &tss;
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
    gdt_load_tss(GDT_ENTRIES * UInt64.sizeof); // 0x28 = TSS selector (5 entries * 8 bytes)
}
