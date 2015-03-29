
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
  extern kbuf
  extern is_alpha
;****f* key_mouse/key_decode1 *
;
; NAME
;>1 menu
;  key_decode3 - decode non-aplha key strings and get process
; INPUTS
;    kbuf - global library buffer with key string
;    esi = table of key strings and processes
;    example
;    db 1bh,5bh,48h,0  ; pad_home
;    dd gs_home        ; home process 
;    db 1bh,5bh,44h,0  ; pad_left
;    dd gs_left        ; left arrow process
;    db 7fh,0          ; backspace
;    dd gs_backspace   ; backspace process
;    db 0              ;end of table
;     
; OUTPUT
;    eax = process pointer, or zero if key not found
; NOTES
;   source file: key_decode3.asm
;   see also crt_open, mouse_enable
;<
; * ----------------------------------------------
;*******
  global key_decode3
key_decode3:
  mov	edi,kbuf	;get inkey ptr
check_next:
  cmpsb			;inkey match table entry
  je	first_char_match ;jmp if char match
kd3_10:
  lodsb			;get next table char
  or	al,al		;scan to end of table key string
  jnz	kd3_10		;skip to end of table key
  add	esi,4		;move past process
  cmp	byte [esi],0	;check if end of table
  jne	key_decode3	;jmp if another table entry
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
  