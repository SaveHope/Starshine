use core::fmt;

pub const VGA_HEIGHT: usize = 25;
pub const VGA_WIDTH: usize = 80;

#[allow(dead_code)]
#[repr(u8)]
pub enum Color {
    Black,
    Blue,
    Green,
    Cyan,
    Red,
    Magenta,
    Brown,
    Gray,
    DarkGray,
    LightBlue,
    LightGreen,
    LightCyan,
    LightRed,
    Pink,
    Yellow,
    White,
}

#[allow(dead_code)]
#[derive(Clone, Copy)]
struct ColorByte(u8);

impl ColorByte {
    fn new(fg: Color, bg: Color) -> ColorByte {
        ColorByte((bg as u8) << 4 | (fg as u8))
    }

    fn from_u8(fg: u8, bg: u8) -> ColorByte {
        ColorByte(fg | bg << 4)
    }
}

#[allow(dead_code)]
#[derive(Clone, Copy)]
struct Cell {
    symbol: u8,
    color: ColorByte,
}

#[allow(dead_code)]
pub enum Align {
    Left,
    Center,
    Right,
}

pub struct VGAWriter {
    buffer: &'static mut [[Cell; VGA_WIDTH]; VGA_HEIGHT],
    column: usize,
    row: usize,
    color: ColorByte,
    align: Align,
}

impl VGAWriter {
    #[allow(dead_code)]
    pub fn new() -> VGAWriter {
        VGAWriter {
            buffer: unsafe { &mut *(0xb8000 as *mut [[Cell; VGA_WIDTH]; VGA_HEIGHT]) },
            column: 0,
            row: 0,
            color: ColorByte::new(Color::Gray, Color::Black),
            align: Align::Left,
        }
    }

    #[allow(dead_code)]
    fn nextline(&mut self) {
        self.column = 0;
        self.row += 1;

        if self.row >= VGA_HEIGHT {
            for i in 0..VGA_HEIGHT-1 {
                let line = self.buffer[i + 1];
                self.buffer[i] = line;
            }

            self.clearline(0, VGA_HEIGHT-1);
            self.row -= 1;
        }
    }

    #[allow(dead_code)]
    pub fn write(&mut self, string: &str) -> &mut VGAWriter {
        for byte in string.bytes() {
            match byte {
                b'\n' => self.nextline(),
                _ => {
                    if self.column >= VGA_WIDTH {
                        self.nextline();
                    }
                    
                    self.buffer[self.row][self.column] = Cell {
                        symbol: byte,
                        color: self.color,
                    };

                    self.column += 1;
                }
            }
        }
        self
    }

    #[allow(dead_code)]
    pub fn writeline(&mut self, string: &str) -> &mut VGAWriter {
        self.write(string);
        self.nextline();
        self
    }

    #[allow(dead_code)]
    pub fn color(&mut self, fg: Color, bg: Color) -> &mut VGAWriter {
        self.color = ColorByte::new(fg, bg);
        self
    }

    #[allow(dead_code)]
    pub fn color_u8(&mut self, fg: u8, bg: u8) -> &mut VGAWriter {
        self.color = ColorByte::from_u8(fg, bg);
        self
    }

    pub fn throwpanic(&mut self) {
        self.color(Color::LightRed, Color::White)
            .write("AAAAAA!1! PANIC!!!11!!!1");

        self.row = 26;
        self.write("E");
    }

    pub fn clearline(&mut self, symbol: u8, row: usize) -> &mut VGAWriter {
        for i in 0..VGA_WIDTH {
            self.buffer[row][i] = Cell {
                symbol,
                color: self.color,
            }
        }
        self
    }

    pub fn clear(&mut self, symbol: u8) -> &mut VGAWriter {
        for i in 0..VGA_HEIGHT {
            self.clearline(symbol, i);
        }
        self.row = 0;
        self.column = 0;
        self
    }

    pub fn print(&mut self, string: &str,) -> &mut VGAWriter {
        self.column = match self.align {
            Align::Left => self.column,
            Align::Center => self.column - string.len() / 2,
            Align::Right => self.column - string.len(),
        };
        self.write(string);
        self
    }

    pub fn align(&mut self, align: Align) -> &mut VGAWriter {
        self.align = align;
        self
    }

    pub fn at(&mut self, column: usize, row: usize) -> &mut VGAWriter {
        self.row = row;
        self.column = column;
        self
    }

    pub fn at_row(&mut self, row: usize) -> &mut VGAWriter {
        self.row = row;
        self.column = 0;
        self
    }
}

impl fmt::Write for VGAWriter {
    fn write_str(&mut self, string: &str) -> fmt::Result {
        self.write(string);
        Ok(())
    }
}
