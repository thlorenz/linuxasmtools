
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
;  key_decode1 - decode non-aplha key strings and get process
; INPUTS
;    kbuf - global library buffer with key string
;    esi = table of key strings and processes
;          first table entry is alpha key process
;          middle entries are non alpha keys
;          final process is called if no match
;    example
;    dd	gs_normal_char ;alpha key process
;    db 1bh,5bh,48h,0  ; pad_home
;    dd gs_home        ; home process 
;    db 1bh,5bh,44h,0  ; pad_left
;    dd gs_left        ; left arrow process
;    db 7fh,0          ; backspace
;    dd gs_backspace   ; backspace process
;    db 0              ;end of table
;    dd no_match       ;no-match process
;     
; OUTPUT
;    eax = process pointer
; NOTES
;   source file: key_decode.asm
;   see also crt_open, mouse_enable
;<
; * ----------------------------------------------
;*******
  global key_decode1
key_decode1:
  mov	al,[kbuf]
  call	is_alpha
  je	ka_exit		;jmp if alpha key
;
; key is not alpha, scan key strings
;
not_alpha:
  add	esi,4		;move past alpha process at top of table
ka_lp:
  mov	edi,kbuf
  cmpsb
  je	first_char_match
ka_10:
  lodsb
  or	al,al		;scan to end of table key string
  jnz	ka_10
  add	esi,4		;move past process
  cmp	byte [esi],0	;check if end of table
  je	get_process
  jmp	ka_lp
first_char_match:
  cmp	byte [esi],0	;check if all match
  jne	check_next
  cmp	byte [edi],0
  je	get_process
  jmp	ka_10		;go restart search
check_next:
  cmpsb
  je	first_char_match
  jmp	ka_10
get_process:
  inc	esi		;move past zero
ka_exit:
  lodsd			;get process
  ret
;****f* key_mouse/key_decode2 *
;
; NAME
;>1 menu
;  key_decode2 - decode aplha key strings and get process
; INPUTS
;    esi = table of key strings and processes
;    kbuf - global library buffer with alpha key
;    example
;    db "a"            ; a key
;    dd a_process      ;
;    db 'b'            ; b key
;    dd b_process      ;
;    db 0              ; end of table 
;     
; OUTPUT
;    eax = process pointer if no carry
;          carry = key not found
; NOTES
;   source file: key_decode.asm
;   see also crt_open, mouse_enable
;<
; * ----------------------------------------------
;*******
  global key_decode2
key_decode2:
  mov	ah,[kbuf]	;get key typed
kd2_10:
  lodsb
  or	al,al	
  jz	kd2_nomatch	;exit if no more table entries
  cmp	al,ah
  je	kd2_match
  add	esi,4		;move to next table entry
  jmp   short kd2_10
kd2_match:
  lodsd			;get process
  clc
  jmp	short kd2_exit2
kd2_nomatch:
  stc
kd2_exit2:
  ret

