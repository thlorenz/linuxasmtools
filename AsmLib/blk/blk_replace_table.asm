
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
 extern blk_replace_all

 [section .text]

;****f* blk/blk_replace_table *
; NAME
;>1 blk
;  blk_replace_table - replace strings using table
; INPUTS
;    ebx = replace table with pairs of asciiz strings.
;    example:
;      db "find str1",0,   "replacement text1",0
;      db "find str2",0,   "replacement text2",0
;      db "find_str3",0,   0
;      db 0 ;;end of table
;    edi = buffer with text
;    ebp = file end ptr
;    ch = case flag for find str, 0df=ignore case 0ffh=use case
; OUTPUT
;    buffer modified
;    ebp = adjusted buffer end ptr
; NOTES
;   source file: blk_replace_table.asm
;<
; * ----------------------------------------------
;*******
;---------------------------------------------
  global blk_replace_table
blk_replace_table:
  mov	ch,0ffh			;match case
;
; get search string
;
tr_main_lp:
  mov	esi,ebx			;esi = ptr to find str
tr_lp1:
  inc	ebx
  mov	al,[ebx]
  or	al,al
  jnz	tr_lp1			;loop till end of find str

  inc	ebx
  mov	eax,ebx			;eax = ptr to replace str

  push	ebx	;save table ptr
  push	edi	;save buffer top
  call	blk_replace_all
  pop	edi
  pop	ebx
;
; scan to end of replaee str
;
tr_lp2:
  mov	al,[ebx]
  or	al,al
  jz	tr_cont
  inc	ebx
  jmp	tr_lp2

tr_cont:
  inc	ebx		;move to start of find str
  cmp	byte [ebx],0
  jne	tr_main_lp
tr_done:
  ret

