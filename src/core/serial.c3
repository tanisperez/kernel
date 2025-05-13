module kernel::core::serial;

import kernel::types;
import kernel::core::system;

// Documentation: https://wiki.osdev.org/Serial_Ports

enum SerialPort: UInt16 (inline UInt16 address) {
    COM1 = 0x3F8,
    COM2 = 0x2F8,
    COM3 = 0x3E8,
    COM4 = 0x2E8,
}

struct Serial {
    SerialPort serial_port;
}

fn void Serial.enable(self) {
    system::outb(self.serial_port + 1, 0x00);    // Disable all interrupts
    system::outb(self.serial_port + 3, 0x80);    // Enable DLAB (set baud rate divisor)
    system::outb(self.serial_port + 0, 0x03);    // Set divisor to 3 (lo byte) 38400 baud
    system::outb(self.serial_port + 1, 0x00);    //                  (hi byte)
    system::outb(self.serial_port + 3, 0x03);    // 8 bits, no parity, one stop bit
    system::outb(self.serial_port + 2, 0xC7);    // Enable FIFO, clear them, with 14-byte threshold
    system::outb(self.serial_port + 4, 0x0B);    // IRQs enabled, RTS/DSR set

    system::outb(self.serial_port + 1, 0x01);
}

fn void Serial.putchar(self, char character) {
    system::outb(self.serial_port, character);
}