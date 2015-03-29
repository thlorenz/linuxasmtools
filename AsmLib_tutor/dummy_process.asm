  extern sys_exit
  extern stdout_str
  extern delay
  
;----------------------------------------------------
; This program is used by asmlib_process_demo, it displays
; a message and waits forever.
;
; compile with:
;  nasm -felf -g asmlib_display_demo.asm
;  ld asmlib_display_demo.o -o asmlib_display_demo /usr/lib/asmlib.a
;
;----------------------------------------------------
  [section .text]

  global _start
_start:
  mov	ecx,demo_msg1	;get message
  call	stdout_str	;display message
here:	mov	eax,-1
 	call	delay	;give up time to other processes
        jmp	here

  
;--------------------------------------------------
  [section .data]
demo_msg1: db 0ah,'Child process running and waiting forever',0ah,0

;