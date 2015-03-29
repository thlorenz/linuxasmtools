
;   Copyright (C) 2007 Jeff Owens
;
;   This program is free software: you can redistribute it and/or modify
;   it under the terms of the GNU General Public License as published by
;   the Free Software Foundation, either version 3 of the License, or
;   (at your option) any later version.
;
;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;   GNU General Public License for more details.
;
;   You should have received a copy of the GNU General Public License
;   along with this program.  If not, see <http://www.gnu.org/licenses/>.


  [section .text align=1]
;------------------------------------------------
;>1 xterm
;  screen_size - report screen size in pixels
;    In the console this function returns the complete screen
;    In xterm it retruns the terminal size
;    In xterm-clones it returns the console screen size
; INPUTS
;    env_stack must be called at start of program
; OUTPUT:
;    eax = screen pixel width
;    ebx = screen pixel height
;    note: if terminal does not provide
;          data, eax,ebx will = 0
; NOTES
;   source file: screen_size.asm
;
;    see also: crt_type - returns $TERM usually as "linux" or "xterm"
;              terminal_type - returns code for console,xterm,clone
;              read_winsize_x - returns winsize struc
;              read_term_info_x - returns termios and winsize struc
;              read_window_size - returns text size for console,xterm,clone
;              get_screen_size - returns pixels for xterm or framebuffer
;              win_size - returns xterm pixels or zero if not xterm
;              win_txt_size - returns text size for xterm or zero if other term
;<
; * ----------------------------------------------
  extern ascii_to_dword
  extern lib_buf
  extern term_type
  extern terminal_type
  extern win_size

  global screen_size
screen_size:
  mov	al,[term_type]
  or	al,al
  jnz	ss_check
  call	terminal_type
ss_check:
  cmp	byte [term_type],3	;is this an  xterm
  jb	ss_other		;jmp if not xterm or clone
;
  call	win_size
  xchg	eax,ebx
  jmp	ss_exit
ss_other:
  mov	eax,5		;open
  mov	ebx,fb_dev
  xor	ecx,ecx		;read only
  int	byte 80h
  or	eax,eax
  js	ss_exit

  mov	ebx,eax		;fd to ebx
  mov	eax,54		;ioctl
  mov	ecx,4600h	;FBIOGET_VSCREENINFO
  mov	edx,lib_buf
  int	byte 80h

  mov	eax,6		;close
  int	byte 80h

  mov	eax,[lib_buf]	;get x (screen width 
  mov	ebx,[lib_buf+4]	;get y (screen height 
ss_exit:
  ret  
;-------------
  [section .data]
fb_dev:	db "/dev/fb0",0

  [section .text]

%ifdef DEBUG

 extern dword_to_ascii
 extern crt_str
 extern env_stack

  global main,_start
main:
_start:
  nop
  call	env_stack
;  call	crt_open
  call	screen_size	;eax=h  ebx=witth
  push	ebx		;save width
  mov	edi,buf1
  call	dword_to_ascii
  mov	byte [edi],0

  pop	eax		;get width
  mov	edi,buf2
  call	dword_to_ascii
  mov	byte [edi],0

  mov	ecx,msg1
  call	crt_str
  mov	ecx,msg2
  call	crt_str
  mov	ecx,msg3
  call	crt_str

  mov	eax,1
  int	byte 80h
;--------
  [section .data]
msg1: db 0ah,'screen width (pixels)='
buf1: db 0,0,0,0,0,0,0
msg2: db 0ah,'screen height (pixels)='
buf2: db 0,0,0,0,0,0,0
msg3: db 0ah,0

%endif