
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

; NAME
;>1 menu
;  mouse_line_decode - find mouse process from display line text
; INPUTS
;    esi = display line text ptr
;    edi = process list matching display line buttons, ending with zero
;    bl = column mouse click occured on
;    example:
;     menu_line1
;      db 1,' New-proj ',1,' Del-proj ',1,' Add-todo ',1,' Fwd ',0
;     process_names
;      dd  new_proj,  del_proj,   add_todo,   page_fwd, 0
; OUTPUT
;    ecx = process match or zero if no match
; NOTES
;   file:  mouse_line_decode.asm
;   assumes click occured on button line matching input tables
;   assumes menu line uses numbers 1-6 to indicate spaces between buttons
;   assumes menu line text is terminated by a zero
;<
; * ----------------------------------------------
;*******
;
 global mouse_line_decode
mouse_line_decode:
me_60:
  mov	bh,1				;starting column
  xor	ecx,ecx				;preload null process
me_62:
  inc	bh
  inc	esi
  cmp	bh,bl				;match?
  je	me_70
  cmp	byte [esi],9
  jae	me_62				;jmp if normal char
me_64:
  cmp	dword [edi],0			;check if end of buttons
  je	me_70				;exit if beyond buttons
  add	edi,4				;move to next process
  jmp	me_62
me_70:
  mov	ecx,[edi]				;return ecx to caller
me_exit:      
  ret
