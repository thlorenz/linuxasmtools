
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

;------------------ ascii_to_xkey.inc -----------------------

  extern key_translate_table

;---------------------
;>1 keyboard
;  ascii_to_xkey - ascii code to x key code
; INPUTS
;  al = ascii key
; OUTPUT:
;  "js" flag set if printable ascii, (ah has 80h bit set)
;  ah=flag
;   00=unshifted  01-shifted
;  al= x code
;
; NOTES
;   source file: ascii_to_xkey
;   This function can not be used for special keys with
;   extended ascii representation.
;<
; * ----------------------------------------------

  global ascii_to_xkey
ascii_to_xkey:
  movzx eax,al		;clear upper eax bits
  mov	esi,key_translate_table
  mov	ah,al		;move ascii key to ah
  mov	ecx,8		;x code start
atx_lp:
  lodsb			;get flag
  lodsb			;get unshifted key
  cmp	al,ah		;
  je	unshifted_match
  lodsb
  cmp	al,ah
  je	shifted_match
  inc	ecx
  cmp	ecx,255
  jne	atx_lp		;loop till end of table
;key was not in table
  neg	eax
  jmp	short atx_exit
unshifted_match:
  mov	ah,0
  mov	al,cl
  jmp	atx_exit
shifted_match:
  mov	ah,1
  mov	al,cl
atx_exit:
  or	eax,eax
  ret


  [section .text]

%ifdef DEBUG
  global _start
_start:
  mov	al,'a'
  call	ascii_to_xkey
  mov	al,'A'
  call	ascii_to_xkey
  mov	eax,1
  int	byte 80h
%endif