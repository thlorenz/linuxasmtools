
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
;--------------------------------------------------------------------
;****f* str/str_replace_all *
; NAME
;>1 str_cmp
;  str_replace_all - replace all occurances of str1 in str2
; INPUTS
;    esi = str1 -asciiz string ending with any char 0h-6h
;    edi = str2 -asciiz string ending with any char 0h-6h
;    eax = ptr to replacement string
; OUTPUT
;    carry set if replacement occured
;    if no carry - ebp = new str2 end point
;    if no carry - edi = ptr to end of inserted string
; NOTES
;    source file: /str_cmp/str_replace_all.asm
;<
;  * ----------------------------------------------
;*******
  extern blk_replace_all
  global str_replace_all
str_replace_all:
  push	eax		;save replacement string ptr
  push	edi		;save string 2 (buffer) pointer
; find end of string2
sra_lp1:
  cmp	byte [edi],0
  je	sra_end1
  inc	edi
  jmp	short sra_lp1	;loop till end of str2
sra_end1:
  mov	ebp,edi		;ebp=end of str1
  pop	edi		;restore str2 start
  pop	eax		;restore replacement str ptr
  mov	ch,-1		;set use case flag
  call	blk_replace_all
  ret
