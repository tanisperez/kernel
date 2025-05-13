module kernel::core::serial;

import kernel::types;
import kernel::core::system;

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
    system::outb(self.serial_port + 1, 0x00);
    system::outb(self.serial_port + 3, 0x80); /* Enable divisor mode */
    system::outb(self.serial_port + 0, 0x03); /* Div Low:  03 Set the port to 38400 bps */
    system::outb(self.serial_port + 1, 0x00); /* Div High: 00 */
    system::outb(self.serial_port + 3, 0x03);
    system::outb(self.serial_port + 2, 0xC7);
    system::outb(self.serial_port + 4, 0x0B);

    system::outb(self.serial_port + 1, 0x01);
}

fn void Serial.putchar(self, char character) {
    system::outb(self.serial_port, character);
}