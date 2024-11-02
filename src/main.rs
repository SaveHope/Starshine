#![no_std]
#![no_main]

use core::panic::PanicInfo;
use core::fmt::Write;

mod vga;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    let mut vga = vga::VGAWriter::new();
    vga.setcolor(vga::Color::White, vga::Color::Red)
        .clear(0);
    write!(vga, "Kernel panic!\n\n{}", _info).ok();
    loop {}
}

#[no_mangle]
pub extern "C" fn _start() -> ! {
    vga::VGAWriter::new()
        .setcolor(vga::Color::Blue, vga::Color::Green)
        .writeline("\n\n\n\n\n\nHewwo!")
        .setcolor_u8(0xA, 0x8)
        .writeline("Hewwo again!")
        .throwpanic();
    
    loop {}
}
