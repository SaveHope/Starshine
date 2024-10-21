;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   EXPORTS n' IMPORTS
;

global _start

extern vga_write
extern vga_writeline



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   NASM PREPROCESSOR
;

MB_MAGIC    equ 0x1BADB002
MB_FLAGS    equ 00000011b
MB_CHECKSUM equ -(MB_MAGIC + MB_FLAGS)

%define VGA_TEXT  1, 0x0F
%define VGA_LIGHT 1, 0x0B
%define VGA_DONE  1, 0xA0
%define VGA_FAIL  1, 0xC0

%macro WRITE 1
    mov esi, %1
    call vga_write
%endmacro

%macro WRITELINE 1
    mov esi, %1
    call vga_writeline
%endmacro



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   MULTIBOOT HEADER
;

section .multiboot
        dd MB_MAGIC
        dd MB_FLAGS
        dd MB_CHECKSUM



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   POST-INITILIZATION DATA
;

section .bss
align 4
stack_bottom:
    resb 16384 ; 16 KB
stack_top:



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   READ ONLY DATA
;

section .rodata
msg_empty:     db VGA_TEXT,' ', 0
msg_done:      db VGA_DONE,' DONE ',0
msg_failed:    db VGA_FAIL,' FAILED ',0
msg_halted:    db VGA_TEXT,'Halt loop entering',0
msg_bootbegin: db VGA_TEXT,'Booting ',VGA_LIGHT,'Starshine ',VGA_TEXT, 'OS',0
msg_bootfault: db VGA_TEXT,'Boot fault.',0
msg_cpuid:     db VGA_TEXT,'[1/2] CPUID check... ',0
msg_longmode:  db VGA_TEXT,'[2/2] Long-mode check... ',0



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   EXECUTABLE CODE
;

section .text
bits 32



;   FUNCTION `_start`

_start:
    ;   Setup stack
    mov esp, stack_top

    ;   Boot begin message
    WRITELINE msg_bootbegin
    WRITELINE msg_empty

    ;   CPUID check
    call check_cpuid

    ;   Long mode
    call check_longmode

    ;   Enter into halt loop
    call halt



;   FUNCTION `check_cpuid`

check_cpuid:
    WRITE msg_cpuid

    ;   Pop EFLAGS to EAX (for checking) and EBX (for restoring)
    pushfd
    pop eax
    mov ebx, eax
    ;   Enabling ID flag, and push EAX to EFLAGS
    xor eax, 1 << 21
    push eax
    popfd
    ;   Pop EFLAGS to EAX. If ID flag resets, then CPU don't support CPUID
    pushfd
    pop eax
    ;   Restore EFLAGS
    push ebx
    popfd
    ;   if (eax != ebx) throw fail
    cmp eax, ebx
    jz .fail
    ;   Return
    WRITELINE msg_done
    ret
.fail: 
    WRITELINE msg_failed
    jmp failed



;   FUNCTION `check_longmode`

check_longmode:
    WRITE msg_longmode
    jmp halt



;   FUNCTION `failed`

failed:
    WRITELINE msg_bootfault
    jmp halt



;   FUNCTION `halt`

halt:
    WRITELINE msg_halted
.loop:
    hlt
    jmp .loop
