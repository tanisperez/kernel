module kernel::drivers;

import kernel::types;
import kernel::cpu;

// Documentation: https://wiki.osdev.org/Serial_Ports

enum SerialPort: UInt16 (inline UInt16 address) {
    COM1 = 0x3F8,
    COM2 = 0x2F8,
    COM3 = 0x3E8,
    COM4 = 0x2E8,
}

struct Serial {
    SerialPort port;
}

fn void Serial.enable(self) {
    cpu::outb(self.port + 1, 0x00);    // Disable all interrupts
    cpu::outb(self.port + 3, 0x80);    // Enable DLAB (set baud rate divisor)
    cpu::outb(self.port + 0, 0x03);    // Set divisor to 3 (lo byte) 38400 baud
    cpu::outb(self.port + 1, 0x00);    //                  (hi byte)
    cpu::outb(self.port + 3, 0x03);    // 8 bits, no parity, one stop bit
    cpu::outb(self.port + 2, 0xC7);    // Enable FIFO, clear them, with 14-byte threshold
    cpu::outb(self.port + 4, 0x0B);    // IRQs enabled, RTS/DSR set
}

fn int Serial.is_write_empty(self) @private {
    return cpu::inb(self.port + 5) & 0x20;
}

fn int Serial.is_read_empty(self) @private {
    return cpu::inb(self.port + 5) & 1;
}

fn void Serial.write_char(self, char character) {
    // while (self.is_write_empty() == 0);

    cpu::outb(self.port, character);
}

fn void Serial.writeln(self, String text) {
    foreach (char c : text) {
        self.write_char(c);
    }
    self.write_char('\n');
}

fn char Serial.read_char(self) {
    // while (self.is_read_empty() == 0);

    return (char) cpu::inb(self.port);
}