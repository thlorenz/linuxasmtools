
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
;-------------------------------------------------
;>1 xterm
;  win_size - report window size excluding title
;    warning: this may only work on xterm, not other terminals
; INPUTS
;    none
; OUTPUT:
;    eax = window pixel height
;    ebx = window pixel width
;    
; NOTES
;   source file: win_size.asm
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
  extern terminal_report
  extern key_mouse2
  extern kbuf
  extern ascii_to_dword

  global win_size
win_size:
  mov	ecx,request
  call	terminal_report
  jns	ws_ok
  xor	eax,eax
  xor	ebx,ebx
  jmp	short ws_exit
ws_ok:
;  call	key_mouse2
  mov	esi,kbuf
;move to start of height
  add	esi,byte 4
  call	ascii_to_dword
  push	ecx
  call	ascii_to_dword
  mov	ebx,ecx
  pop	eax
ws_exit:
  ret

;-------------
  [section .data]
request: db 1bh,"[14t",0
  [section .text]



%ifdef DEBUG
 extern dword_to_ascii
 extern crt_str
  global main,_start
main:
_start:
  nop
;  call	crt_open
  call	win_size	;eax=h  ebx=witth
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
msg1: db 0ah,'our window height (pixels)='
buf1: db 0,0,0,0,0,0,0
msg2: db 0ah,'our window width (pixels)='
buf2: db 0,0,0,0,0,0,0
msg3: db 0ah,0

%endif