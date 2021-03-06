
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
;>1 str_conv
;  byte2ascii - convert binary 1-255 to 3 ascii chars 
; INPUTS
;     al  = binary value
;     edi = start of storage area
; OUTPUT
;    edi = ptr to end of stored string
;    eax,edx destroyed
; NOTES
;    source file: byte2ascii.asm
;    If input (al) equals zero, nothing is stored.
;<
;  * ----------------------------------------------
;*******
  global byte2ascii
byte2ascii:
  or	al,al
  jz	bta_exit	;exit if zero
  mov	dl,100
  div	dl
  or	al,'0'
  stosb
  mov	al,ah
  aam
  add	ax,'00'
  xchg  ah,al
  stosw
bta_exit:
  ret

;---------------------------
%ifdef DEBUG

 global main,_start
main:
_start:
  mov	al,255
  mov	edi,stuff
  call	byte2ascii
err:
  mov	eax,1
  int	80h

;--------------
  [section .data]
stuff: dd	0,0,0
;--------------
 [section .text]

%endif

