  extern sys_exit
  extern stdout_str
  extern read_stdin
  extern delay
  extern kbuf
  
;----------------------------------------------------
; This program demonstrates basic AsmLib functions
; for the display.
;
; compile with:
;  nasm -felf -g asmlib_display_demo.asm
;  ld asmlib_display_demo.o -o asmlib_display_demo /usr/lib/asmlib.a
;
; the program "asmlib_display_demo" demonstrates the simplest display
; usage
;----------------------------------------------------
; this is beginning of demo1, it display a message
; and waits for a response.
  [section .text]

  global _start
_start:
  mov	ecx,demo1_msg1	;get message
  call	stdout_str	;display message
  call	read_stdin	;read key
  mov	al,[kbuf]	;get key read
  mov	[out_char],al	;store key in ouptut msg
  mov	ecx,demo1_msg2	;get message 2
  call	stdout_str	;display message 2
  mov	eax,-2		;delay 2 seconds
  call	delay
  call	sys_exit	;all done
  
;--------------------------------------------------
  [section .data]
demo1_msg1: db 0ah,'hello, what is first letter of your name',0
demo1_msg2: db 0ah,'you entered '
out_char:   db 0,0

;