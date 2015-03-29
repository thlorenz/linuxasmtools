
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
;------------------------------
;****f* crt/crt_horizontal *
; NAME
;>1 crt
;   crt_horizontal - repeat display character 
; INPUTS
;    bl = character to repeat at cursor position
;    eax = color, see (mov_color) for format of color
;    ecx = number of times to display character
;    lib_buf is used to build display line
; OUTPUT
;   eax = negative system error# or positive if success
; NOTES
;    source file crt_horizontal.asm
;    The current window width is not checked, crt_horizontal
;    will attempth display even if window size too small. 
;<
;  * ---------------------------------------------------
;*******
  extern lib_buf
  extern mov_color

  global crt_horizontal
crt_horizontal:
  push	ecx
  mov	edi,lib_buf
  call	mov_color
  mov	al,bl
  pop 	ecx
  rep	stosb			;build display string
  mov	eax, 0x4		; system call 0x4 (write)
  mov	ebx, 1 ;stdout		; file desc. is stdout
  mov	ecx,lib_buf		;write buffer
  sub	edi,ecx			;compute length of write
  mov	edx,edi			;computed lenght of write
  int	0x80
  ret
