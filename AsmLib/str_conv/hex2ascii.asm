
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
;****f* str_conv/nibble2hexascii *
; NAME
;>1 str_conv
;  nibble2hexascii - convert one nibble to hex ascii and store
; INPUTS
;     ebx = nibble
;     edi = storage point for ascii
;       example: to store nibbles sequentially
;       mov bl,nibble
;       mov edi,storage
;       call nibble2hexascii
;       add edi,2		;move to next store location 
; OUTPUT
;    one ascii character stored at [edi]
;      edi decremented by one
;      ebx is shifted right
; NOTES
;    source file: hex2ascii.asm
;    See also: nibble2hexstr
;<
;  * ----------------------------------------------
;*******
;****f* str_conv/byte2hexascii *
; NAME
;>1 str_conv
;  byte2hexascii - convert one byte to hex ascii and store
; INPUTS
;     ebx = byte of data
;     edi = storage point for ascii +1 
;      example: to store byte  sequentially
;      mov   bl,hexbyte
;      mov   edi,buffer + 1
;      call  byte2hexascii
;      add   edi,3 
; OUTPUT
;    two ascii characters stored at [edi]
;      edi decremented by two
;      ebx is shifted right 
; NOTES
;    source file: hex2ascii.asm
;    See also: byte2hexstr
;<
;  * ----------------------------------------------
;*******
;****f* str_conv/word2hexascii *
; NAME
;>1 str_conv
;  word2hexascii - convert one word to hex ascii and store
; INPUTS
;     ebx = word
;     edi = storage point for ascii +3
;      example: to store word  sequentially
;      mov   bx,hexword
;      mov   edi,buffer + 3
;      call  word2hexascii
;      add   edi,5 
; OUTPUT
;    four ascii characters stored at [edi]
;      edi decremented by four
;      ebx is shifted right 
; NOTES
;    source file: hex2ascii.asm
;    See Also: word2hexstr
;<
;  * ----------------------------------------------
;*******
;****f* str_conv/dword2hexascii *
; NAME
;>1 str_conv
;  dword2hexascii - convert dword to hex ascii and store
; INPUTS
;     ebx = dword
;     edi = storage point for ascii +7
;      example: to store dwords sequentially
;      mov   ebx,hexdword
;      mov   edi,buffer + 7
;      call  dword2hexascii
;      add   edi,9 
; OUTPUT
;    eight ascii character stored at [edi]
;      edi decremented by eight
;      ebx is shifted right 
; NOTES
;    source file: hex2ascii.asm
;    See also: dword2hexstr
;<
;  * ----------------------------------------------
;*******
  global dword2hexascii,word2hexascii,byte2hexascii,nibble2hexascii
dword2hexascii:
  call	word2hexascii
word2hexascii:
  call	byte2hexascii
byte2hexascii:
  call	nibble2hexascii
nibble2hexascii:
  mov	eax,ebx
  shr	ebx,4
  and	al,0fh
  add	al,'0'
  cmp	al,'9'
  jle	n_ok
  add	al,"A"-'9'-1
n_ok:
  mov	byte [edi],al
  dec	edi
  ret
  