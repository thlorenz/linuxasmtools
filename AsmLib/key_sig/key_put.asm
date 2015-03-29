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
;---------------------------------------------------
;>1 key_sig
;key_put - insert key back into buffer
;  we can put a max of two key strings, each a max of 13 bytes
;  Strings are pushed on top of key stack. 
; INPUT
;   eax=ptr to key string (zero terminated)
; OUTPUT
;   none
; NOTE
;   source file key_put.asm
;<
  extern str_move
  extern ks1,ks2

  global key_put
key_put:
  mov	esi,ks1
  cmp	[esi],byte 0	;any strings stored?
  je	kp_20		;jmp if no stored keys
;move ks1 > ks2
  mov	edi,ks2
  movsd
  movsd
  movsd
  movsd
;move "put" key to avail1
kp_20:
  mov	edi,ks1
  mov	esi,eax
  call	str_move
  ret
;-------

;---------------------------------------------------
