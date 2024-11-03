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
        .color_swap()
        .print(" KERNEL PANIC ")
        .color_swap();

    vga
        .at_row(6)
        .margin(4, 4);
    writeln!(vga, "{}\n", _info.message()).ok();
    if _info.location().is_some() {
        writeln!(vga, "Source: {}", _info.location().unwrap()).ok();
    }
    
    loop {}
}

#[no_mangle]
pub extern "C" fn _start() -> ! {
    let mut kernel = Kernel::init();
    kernel.main();
    
    loop {}
}

struct Kernel {
    vga: vga::VGAWriter,
}

impl Kernel {
    pub fn init() -> Kernel {
        Kernel {
            vga: vga::VGAWriter::new(),
        }
    }

    pub fn main(&mut self) {
        self.vga
            .color(vga::Color::Blue, vga::Color::Green)
            .writeline("\n\n\n\n\n\nHewwo!");
    }
}
