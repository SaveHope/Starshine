#![no_std]
#![no_main]

use core::panic::PanicInfo;

mod vga;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

#[no_mangle]
pub extern "C" fn _start() -> ! {
    vga::VGAWriter::new()
        .setcolor(vga::Color::Blue, vga::Color::Green)
        .writeline("Hewwo!")
        .setcolor_u8(0xA, 0x8)
        .writeline("Hewwo again!");

    loop {}
}
