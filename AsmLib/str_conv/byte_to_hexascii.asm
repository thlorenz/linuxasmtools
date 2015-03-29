
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
;****f* str_conv/byte_to_hexascii *
;
; NAME
;>1 str_conv
;  byte_to_hexascii - binary byte to hex ascii
; INPUTS
;    al = binary hex byte
; OUTPUT
;    ax = hex ascii
; NOTES
;    source file: byte_to_hexascii.asm
;<
;  * ----------------------------------------------
;*******
 global byte_to_hexascii
byte_to_hexascii:
  mov	ah,al
  shr	al,1
  shr	al,1
  shr	al,1
  shr	al,1
  cmp	al,10
  sbb	al,69h
  das
  xchg	al,ah
  and	al,0fh
  cmp	al,10
  sbb	al,69h
  das
  xchg  al,ah
  ret
