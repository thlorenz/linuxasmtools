#! /bin/bash
nasm -felf test2.asm -o test2.o
ld test2.o -o test2 /usr/lib/asmlib.a
