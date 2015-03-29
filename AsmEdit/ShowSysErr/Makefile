all:	show_sys_err


show_sys_err: show_sys_err.o 
	ld -oshow_sys_err show_sys_err.o

show_sys_err.o: show_sys_err.asm
	nasm -g -felf -oshow_sys_err.o show_sys_err.asm


