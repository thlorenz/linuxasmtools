;-------------------------------------------------

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
;   along with this program.  If not, see <http://www.gnu.org/licenses/.


  [section .text align=1]


;---------------------------------------------------
;>1 key_sig
;key_decode - decode key and return handler
; INPUT
;   ecx = key string ptr
;   esi = decode table
; OUTPUT
;   eax = process pointer, or zero if key not found
; NOTE 
;   source file key_decode.asm
;<
;-----------------------------------------------------
  global key_decode
key_decode:
  mov	edi,ecx		;get inkey ptr
check_next:
  cmpsb			;inkey match table entry
  je	first_char_match ;jmp if char match
kd3_10:
  lodsb			;get next table char
  or	al,al		;scan to end of table key string
  jnz	kd3_10		;skip to end of table key
  add	esi,4		;move past process
  cmp	byte [esi],0	;check if end of table
  jne	key_decode	;jmp if another table entry
  xor	eax,eax		;generate fail code
  jmp	short kd3_exit2	;go exit
first_char_match:
  cmp	byte [esi],0	;end of table entry
  jne	check_next	;jmp if no match
  cmp	byte [edi],0	;end of input key?
  jne	kd3_10		;go restart search
get_process:
  inc	esi		;move past zero
kd3_exit:
  lodsd			;get process
kd3_exit2:
  ret
