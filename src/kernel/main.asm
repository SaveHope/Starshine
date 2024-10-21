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
;   Memory Page Tables
align 4096
mpt4:
    resb 4096
mpt3:
    resb 4096
mpt2:
    resb 4096
mpt1:
    resb 4096
;   Stack
align 16
stack_bottom:
    resb 16384 ; 16 KB
stack_top:



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   READ ONLY DATA
;

section .rodata
;   Global Descriptor Table
gdt64:
    ;   Null-descriptor
    dq 0
.code: equ $ - gdt64
    ;   Read     | Executable | Descriptor | Present   | x64
    dq (1 << 41) | (1 << 43)  | (1 << 44)  | (1 << 47) | (1 << 53)
.data: equ $ - gdt64
    ;   Read     | Descriptor | Present
    dq (1 << 41) | (1 << 44)  | (1 << 47)
.pointer:
    ;   Table size
    dw $ - gdt64 - 1
    ;   Table begin address
    dq gdt64

;   Output messages
msg_empty:     db VGA_TEXT,' ', 0
msg_done:      db VGA_DONE,' DONE ',0
msg_failed:    db VGA_FAIL,' FAILED ',0
msg_halted:    db VGA_TEXT,'Halt loop entering',0
msg_bootbegin: db VGA_TEXT,'Booting ',VGA_LIGHT,'Starshine ',VGA_TEXT, 'OS',0
msg_bootfault: db VGA_TEXT,'Boot fault.',0
msg_cpuid:     db VGA_TEXT,'CPUID check... ',0
msg_longmode:  db VGA_TEXT,'Long-mode check... ',0
msg_setup_memorypages: db VGA_TEXT,'Setting up Memory Pages',0
msg_setup_longmode:    db VGA_TEXT,'Setting up Long Mode',0



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
    ;   Check
    call check_cpuid
    call check_longmode
    ;   Setup
    call setup_memorypages
    call setup_longmode
    ;   Jump to x64 code
    ;jmp gdt64.code:x64start



;   FUNCTION `halt`

halt:
    WRITELINE msg_halted
    cli
.loop:
    hlt
    jmp .loop



;   FUNCTION `check_cpuid`

check_cpuid:
    WRITE msg_cpuid
    ;   Pop EFLAGS to EAX (for checking) and EBX (for restoring)
    pushfd
    pop eax
    mov ebx, eax
    ;   Switch ID flag, and push EAX to EFLAGS
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
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    jz .fail
    ;   Return
    WRITELINE msg_done
    ret
.fail: 
    WRITELINE msg_failed
    jmp failed



;   FUNCTION `setup_memorypages`

setup_memorypages:
    ;   Point mpt3 to mpt4
    mov eax, mpt3
    or eax, 11b ; Present | Writeable
    mov dword [mpt4], eax
    ;   Point mpt2 to mpt3
    mov eax, mpt2
    or eax, 11b ; Present | Writeable
    mov dword [mpt3], eax
    ;   Point mpt1 to mpt2
    mov eax, mpt1
    or eax, 11b ; Present | Writeable
    mov dword [mpt2], eax
    ;   Mapping mpt1
    mov ecx, 0
.loop:
    mov eax, 0x400 ; 2KB each page
    mul ecx
    or eax, 11b ; Present | Writeable
    mov [mpt1 + ecx * 8], eax
    ;   increment
    inc ecx
    cmp ecx, 512
    jne .loop
    ;   Set memory page address
    mov eax, mpt4
    mov cr3, eax
    WRITELINE msg_setup_memorypages
    ret

;   FUNCTION `setup_longmode`

setup_longmode:
    ;   Enable Physical Address Extension
    mov edx, cr4
    or edx, 1 << 5
    mov cr4, edx
    ;   Enable Long Mode
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr
    ;   Enable Memory Pages and protect read-only pages
    mov eax, cr0
    or eax, (1 << 16) | (1 << 31)
    mov cr0, eax
    ;   Enable GDT
    lgdt [gdt64.pointer]
    ;   Setup segment registers
    mov ax, gdt64.data
    mov ss, ax
    mov ds, ax
    mov es, ax
    WRITELINE msg_setup_longmode
    ret

;   FUNCTION `failed`

failed:
    WRITELINE msg_bootfault
    jmp halt
