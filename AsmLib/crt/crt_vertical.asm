
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
  [section .text]

 extern crt_rows,crt_columns
 extern crt_set_color,move_cursor

;****f* crt/crt_vbar *
; NAME
;>1 crt
;  crt_vbar - display vertical bar lenght of window
; INPUTS
;    [crt_columns] - set by crt_open
;    [crt_rows] - set by crt_open
; OUTPUT
;    vertical bar displayed on screen,
; NOTES
;    source file crt_vertical.asm
;    call crt_set_color to set bar color
;<
;  * ----------------------------------------------
;*******
  global crt_vbar
crt_vbar:
  mov	al,[crt_columns]
  inc	al
  mov	ah,1
  mov	bl," "
  mov	bh,[crt_rows]
  call	crt_vertical
  ret
;----------------------------------
;****f* crt/crt_vertical *
; NAME
;>1 crt
;  crt_vertical - repeat char vertically
; INPUTS
;     al = column (ascii)
;     ah = row (ascii)
;     bl = char
;     bh = repeat count
; OUTPUT
;    display character in vertical column
; NOTES
;    source file crt_vertical.asm
;<
;  * ----------------------------------------------
;*******
   global crt_vertical
crt_vertical:
  mov	byte [display_char],bl
  mov	byte [repeat_count],bh
drv_lp:
  push	eax
  call	move_cursor		;al=column ah=row

  mov	ecx,display_char	;get ptr to character
  mov edx,1			;write one char
  mov eax, 0x4			; system call 0x4 (write)
  mov ebx,edx			; stdout
  int 0x80
  pop	eax			;restore ah-row al-column
  inc	ah
  dec	byte [repeat_count]
  jnz	drv_lp
  ret  
  
  [section .data]
display_char	db	0
repeat_count	db	0

  [section .text]
