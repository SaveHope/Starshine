#![no_std]
#![no_main]

use core::panic::PanicInfo;
use core::fmt::Write;
mod vga;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    let mut vga = vga::VGAWriter::new();

    vga 
        .color(vga::Color::White, vga::Color::Red)
        .clear(0);

    vga
        .at(vga::VGA_WIDTH / 2, 2)
        .align(vga::Align::Center)
        .print("Kernel panic!");

    vga.at_row(6);
    writeln!(vga, "{}", _info.message()).ok();
    if _info.location().is_some() {
        writeln!(vga, "{}", _info.location().unwrap()).ok();
    }
    
    loop {}
}

#[no_mangle]
pub extern "C" fn _start() -> ! {
    vga::VGAWriter::new()
        .color(vga::Color::Blue, vga::Color::Green)
        .writeline("\n\n\n\n\n\nHewwo!")
        .color_u8(0xA, 0x8)
        .writeline("Hewwo again!")
        .throwpanic();
    
    loop {}
}
