
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
;  win_move - move window to pixel location
;    warning: this may only work on xterm, not other terminals
; INPUTS
;    eax = pixel column (upper left corner)
;    ebx = pixel row (upper left corner)
; OUTPUT:
;    none
; NOTES
;   source file: win_move.asm
;<
; * ----------------------------------------------
  extern crt_str
  extern dword_to_ascii
  extern lib_buf
  extern str_move

  global win_move
win_move:
  cld
  push	eax
  mov	edi,lib_buf
  mov	esi,request
  call	str_move
  pop	eax
  push	ebx
  call	dword_to_ascii
  mov	al,';'
  stosb
  pop	eax
  call	dword_to_ascii
  mov	al,'t'
  stosb
  xor	eax,eax
  stosb
  
  mov	ecx,lib_buf
  call	crt_str
  ret

;-------------
  [section .data]
request: db 1bh,"[3;",0
  [section .text]


%ifdef DEBUG
  global main,_start
main:
_start:
  nop
;  call	crt_open
  mov	eax,80
  mov	ebx,1
  call	win_move	;eax=h  ebx=witth

  mov	eax,1
  int	byte 80h
;--------

%endif