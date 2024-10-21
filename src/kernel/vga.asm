;   kernel/vga.asm - Simple VGA output with scrolling

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   EXPORTS n' IMPORTS
;

global vga_write
global vga_writeline



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   NASM PREPROCESSOR
;

VGA_WIDTH  equ 80 * 2
VGA_HEIGHT equ 25
VGA_LENGTH equ VGA_WIDTH * VGA_HEIGHT



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   DATA
;

section .data
cursor_pos: dw 0



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   EXECUTABLE CODE
;

section .text
bits 32



;   FUNCTION `vga_write`
;   Prints zero-ended string to VGA buffer.
;   If char == 1, then next char loaded as VGA color-code for next chars.
;   - ESI - Zero-ended string address

vga_write:
    ;   Read position
    mov edi, 0xB8000
    add edi, [cursor_pos]

.loop: 
    ;   Read char
    mov al, [esi]

    ;   if (al == '\0') break
    cmp al, 0
    jz .end

    ;   Check for colorcode
    ;   if (al == '\1')
    cmp al, 1
    jz .colorcode

    ;   Print char
    mov [edi], ax 
    inc esi
    add edi, 2
    jmp .continue
.colorcode:
    inc esi
    mov ah, [esi]
    inc esi
.continue:
    jmp .loop
.end:
    ;   Write position
    sub edi, 0xB8000
    mov [cursor_pos], edi
    ret



;   FUNCTION `vga_writeline`
;   Prints zero-ended string to VGA buffer, and moves cursor to next line.
;   If char == 1, then next char loaded as VGA color-code for next chars.
;   If VGA buffer overflows, call `vga_scroll`.
;   - ESI - Zero-ended string address

vga_writeline:
    call vga_write
    call vga_nextline
    ret



;   FUNCTION `vga_nextline`
;   Moves cursor to nextline.
;   If char == 1, then loads next char as VGA color-code for next chars.

vga_nextline:
    mov ax, [cursor_pos]
.loop:
    ;   if (ax < VGA_WIDTH) break
    cmp ax, VGA_WIDTH
    jna .end

    ;   Calc cursor column
    sub ax, VGA_WIDTH
    jmp .loop
.end:
    ;   Calc columns to endline, and move to endline
    mov bx, VGA_WIDTH
    sub bx, ax
    add [cursor_pos], bx
    ;   Check buffer overflow
    ;   if (cursor_pos >= VGA_LENGTH) vga_scroll
    cmp [cursor_pos], word VGA_LENGTH
    jge .overflow
    ret
.overflow:
    call vga_scroll
    ret



;   FUNCTION `vga_scroll`
;   Shifts VGA buffer up by 1 line, clears last line, 
;   and moves cursor to last line.

vga_scroll:
    mov ecx, 0
    mov edi, 0xB8000
    mov esi, 0xB8000 + VGA_WIDTH
.loop: ; Move lines
    ;   if (cx == VGA_LENGTH - VGA_WIDTH - 1) break
    cmp ecx, VGA_LENGTH - VGA_WIDTH - 1
    jz .end

    mov ax, [esi]
    mov [edi], ax

    inc ecx
    inc edi
    inc esi
    jmp .loop
.end:
    mov edi, 0xB8000 + VGA_LENGTH - VGA_WIDTH
.loop2: ; Clear last line
    mov [edi], byte 0
    inc edi

    ;   until (edi < 0xB8000 + VGA_LENGTH)
    cmp edi, 0xB8000 + VGA_LENGTH
    jnz .loop2

    ;   Move cursor up
    sub [cursor_pos], word VGA_WIDTH
    ret
