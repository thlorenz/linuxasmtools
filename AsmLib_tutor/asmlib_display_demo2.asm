  extern env_stack
  extern read_window_size
  extern crt_columns
  extern crt_rows
  extern move_cursor
  extern crt_set_color
  extern sys_exit
  extern stdout_str
  extern kbuf
  extern read_stdin
  extern crt_clear
  extern delay
  
;----------------------------------------------------
; This program demonstrates basic AsmLib functions
; for the display.
;
; compile with:
;  nasm -felf -g asmlib_display_demo.asm
;  ld asmlib_display_demo.o -o asmlib_display_demo /usr/lib/asmlib.a
;
;----------------------------------------------------
; this is the beginning of demo2, it gets display
; size, sets color, clears display, moves cursor
; and asks for input
;
; first we need to tell asmlib where the stack
; information is.  This is done by calling env_stack
; when the stack is at entry state.  The library function
; 'read_window_size' needs information on stack to determine
; terminal type.

  [section .text]

  global _start
_start:
  call	env_stack	;save enviornment (on stack)
  call	read_window_size;get window size
  mov	eax,30003437h	;color code
  call	crt_clear	;clear display
  mov	al,[crt_columns];get display
  mov	ah,[crt_rows]	;  size
  shr	al,1		;   and compute
  shr	ah,1		;     center
  call	move_cursor	;move cursor to center
  mov	eax,30003734h	;color
  call	crt_set_color	;change color
  mov	ecx,demo2_msg	;get message 'center'
  call	stdout_str	;show center message
  call	read_stdin	;wait for key
  call	sys_exit	;all done
  
;--------------------------------------------------
  [section .data]

demo2_msg   db '<- center, hit key',0
;