
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
  extern terminfo_extract_key
  extern str_move
  [section .text]

;****f* terminal/terminfo_decode_setup *
; NAME
;>1 terminal
;  terminfo_decode_setup - setup to decode keyboard keys
; INPUTS
;     the routines env_stack and terminfo_read must be
;       called before using this function. Also the
;       buffer filled by terminfo_read must be unmodified.
;     eax = ptr to key decode table with following format:
;          
;           times 3*entries db 0  ;padding for expansion
;           db x    ;format flag 1=terminfo_key_decode1 format
;                                2=terminfo_key_decode2 format
;           (insert key definitions here, see decode routines for
;            format)
;           db 0    ;end of table
; OUTPUT
;     the table input with [eax] is rewritten and all padding
;     flags removed.  It is now ready for terminfo_key_decode
;     routines.
;
; NOTES
;   Source file: terminfo_decode_setup.asm
;   See asmref terminfo entry for more information
;   Use this function with terminfo_key_decode1, and
;   terminfo_key_decode2
;<
; * ----------------------------------------------
; extern terminfo_flags
;*******
  global terminfo_decode_setup
terminfo_decode_setup:
  mov	edi,eax			;output ptr
  mov	esi,eax			;input ptr setup
tds_lp1:
  lodsb				;get padding byte
  or	al,al
  jz	tds_lp1			;skip over pad
  mov	bl,al			;get format flag
  push	ebx
;we are now at top of data
  cmp	bl,1			;is this decode1 format
  jne	tds_lp2			;jmp if decode2 format
  movsd				;move the alpha dword
;process each key entry
tds_lp2:
  lodsb				;get key def
  cmp	al,0ffh			;is this a terminfo lookup
  jne	tds_40			;jmp if non-lookup char
  lodsw				;get terminfo code
  and	eax,0fffh		;isolate key value
;lookup key in terminfo
  call	terminfo_extract_key	;returns ebx=ptr to key string
  cmp	bx,-1
  jne	tds_30			;jmp if valid string found
;terminfo did not have this key, use alternative string
  lodsd				;get terminfo process, and discard
tds_15:
  lodsb				;get operator
  cmp	al,-4			;end of terminfo def?
  je	tds_tail		;jmp if end of terminfo def

tds_17:
  call	str_move		;store next def
  inc	edi			;terminate string
  movsd				;move process address
  cmp	[esi],byte -4		;end of defs
  jne	tds_17
  lodsb				;dump def end flag
  jmp	short tds_tail		;go look for another def
;terminfo key string found, store it, look for (and) operator
tds_30:
  push	esi
  mov	esi,ebx
  call	str_move
  inc	edi
  pop	esi
  movsd				;move processing address
  lodsb				;get operator
  cmp	al,-4			;check if end of def
  je	tds_tail		;jmp if end of def
  cmp	al,-3			;is this a (and)
  je	tds_17			;jmp if and
;skip this (or) part of terminfo def
tds_35:
  lodsb
  or	al,al
  jnz	tds_35			;skip over string
  lodsd				;skip over process
  cmp	[esi],byte -4		;end of def
  jne	tds_35
  lodsb				;discard -4 (end of def)
  jmp	short tds_tail
;put non terminfo key string in table
tds_40:
  stosb				;save first key
  call	str_move		;store key string
  inc	edi			;move past zero at end
tds_50:
  movsd				;move process address
tds_tail:
  cmp	[esi],byte 0
  jne	tds_lp2			;loop till end of table
  xor	eax,eax
  stosb				;terminate table
  pop	ebx
  cmp	bl,1			;is this format 1
  jne	tds_exit
  inc	esi			;move to dword at end
  movsd				;move final dd
tds_exit:
  ret
;----------
  [section .data]
dummy	db 07h,0	;bell (error)
  [section .text]
;-------------------------------------------------
%ifdef DEBUG
 extern terminfo_read

  extern env_stack
  global main,_start
main:
_start:
  call	env_stack
  mov	eax,buf
  call	terminfo_read

  mov	eax,decode_table
  call	terminfo_decode_setup

  mov	eax,1
  int	byte 80h

dog: nop
cat: nop
zorro: nop
unknown: nop
alpha: db 'alpha'
error: db 'error'
;---------
  [section .data]
buf	times 4096 db 0
decode_table:
  times 10 db 0	;pad
  db 1	;flag
  dd    alpha
  db	-1,
  dw	66	;f1
;  dw	500	;illegal
  dd	zorro
  db    -2      ;or
  db    '1',0
  dd	zorro
  db    '2',0
  dd    zorro
  db    -4

  db	'1',0
  dd	cat

  db	0	;end of table
  dd	error

  [section .text]
%endif

