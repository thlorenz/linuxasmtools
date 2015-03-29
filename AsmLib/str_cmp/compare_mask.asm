
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

;---------------------------------------------------------------
;>1 str_cmp
;compare_mask - compare string to masked template
; inputs: esi = mask ptr
;             mask can be *xxx or xxx*
;         edi = data ptr
; output: the flags je,jne are set.
;<
;------------
  global compare_mask
compare_mask:
  cmp	byte [esi],'*'		;check if tail match
  je	compare_tail		;jmp if tail match
;assume our compare string has '*' on end
ffs_clp1:
  cmp	byte [esi],0		;end of match?
  je	ffs_clp1a		;jmp if end of mask
  cmpsb				;compare strings
  je  ffs_clp1
  cmp	byte [esi -1],'*'	;did they compare ok
  jmp	short ffs_x		;exit
ffs_clp1a:
  cmp	byte [edi],0		;end of file name?
  jmp	ffs_x			;exit with je,jne flag

;our compare string start with a "*", do compare from end
compare_tail:
ffs_clp2:
  lodsb
  or	al,al
  jnz	ffs_clp2		;loop till end of string
  dec	esi
  xchg	esi,edi
ffs_clp3:
  lodsb
  or	al,al
  jnz	ffs_clp3		;loop till end of string
  dec	esi
;we are at end of both strings, edi=mask esi=entry
  std
ffs_clp4:
  cmpsb
  je	ffs_clp4		;loop if matching
  cld
  cmp	byte [edi+1],'*'	;did they match?
ffs_x:
  ret
