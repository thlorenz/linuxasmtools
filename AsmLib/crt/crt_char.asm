
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
  extern crt_set_color
  extern move_cursor
	%define stdout 0x1
	%define stderr 0x2

;****f* crt/crt_char_at *
; NAME
;>1 crt
;  crt_char_at - display one colored char at location.
; INPUTS
;     eax = color (aa??ffbb) attribute,foreground,background
;     bl = column
;     bh = row
;     cl = ascii char
; OUTPUT
;    one colored character displayed
; NOTES
;    file crt_char
;<
;  * ----------------------------------------------
;*******
  global crt_char_at
crt_char_at:
  push	ecx
  push	ebx
  call	crt_set_color
  pop	eax
  call	move_cursor
  pop	ecx

  cmp	cl,20h
  jae	dca_2			;jmp if possible alpha
  mov	cl,'?'
dca_2:
  cmp	cl,7eh
  jbe	dca_4			;jmp if legal alpha
  mov	cl,'?'
dca_4:
  mov	byte [char_out],cl
  mov	ecx,char_out		;display data
  mov eax, 0x4			; system call 0x4 (write)
  mov ebx, stdout		; file desc. is stdout
  mov	edx,1			;write one char
  int 0x80
  ret

  [section .data]
char_out  db	0
  [section .text]
