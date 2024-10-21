#!/bin/bash

apool=0
function assert_pool {
    ret=$?
    if [ $ret -ne 0 ]; then
        apool=$ret
    fi
}

function assert {
    ret=$?
    if [ $ret -ne 0 ]; then
        exit $ret
    fi
    if [ $apool -ne 0 ]; then
        exit $apool
    fi
}


#   Clean
rm -rf build; mkdir -p build/kernel
rm -rf out;   mkdir -p out/boot/grub
rm -rf dist;  mkdir dist

#   NASM
for fname in src/kernel/*.asm; do
    bname=$(basename $fname)
    nasm -f elf64 -o "build/kernel/${bname%.asm}.o" $fname
    assert_pool
done
assert

#   Linker
ld -T src/kernel/linker.ld -o out/boot/kernel.bin $(ls build/kernel/*.o)
assert $?

#   GRUB
if grub-file --is-x86-multiboot out/boot/kernel.bin; then
    echo multiboot confirmed
else
    echo multiboot check failed
    exit 1
fi

cp src/grub/grub.cfg out/boot/grub/grub.cfg
grub-mkrescue -o dist/starshine.iso out
assert $?

# QEMU
qemu-system-x86_64 -cdrom dist/starshine.iso