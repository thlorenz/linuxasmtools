
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
;  win_posn - report window position in pixels
;    warning: this may only work on xterm, not other terminals
; INPUTS
;    none
; OUTPUT:
;    eax = pixel column (upper left corner)
;    ebx = pixel row (upper left corner)
; NOTES
;   source file: win_posn.asm
;<
; * ----------------------------------------------
  extern crt_str
  extern key_mouse2
  extern kbuf
  extern ascii_to_dword

  global win_posn
win_posn:
  mov	ecx,request
  call	crt_str
  call	key_mouse2
  mov	esi,kbuf
;move to start of height
  add	esi,byte 4
  call	ascii_to_dword
  push	ecx
  call	ascii_to_dword
  mov	ebx,ecx
  pop	eax
  ret

;-------------
  [section .data]
request: db 1bh,"[13t",0
  [section .text]


 extern dword_to_ascii

%ifdef DEBUG
  global main,_start
main:
_start:
  nop
;  call	crt_open
  call	win_posn	;eax=h  ebx=witth
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
msg1: db 0ah,'pixel column='
buf1: db 0,0,0,0,0,0,0
msg2: db 0ah,'pixel row='
buf2: db 0,0,0,0,0,0,0
msg3: db 0ah,0

%endif