
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
;****f* str_conv/hexascii2nibble *
; NAME
;>1 str_conv
;  hexascii2nibble - convert one hex ascii char to nibble
; INPUTS
;    esi = ptr to hex ascii data
;    ebx = zero or previous sum
; OUTPUT
;    ebx = contains hex in low 4 bits, the previous contents
;          are shifted left by 4
; NOTES
;   source file: ascii2hex.asm
;<
; * ----------------------------------------------
;*******
;****f* str_conv/hexascii2byte *
; NAME
;>1 str_conv
;  hexascii2byte - convert two hex ascii char to byte
; INPUTS
;    esi = ptr to hex ascii data
;    ebx = zero or previous sum
; OUTPUT
;    ebx = contains hex , the previous contents
;          are shifted left
; NOTES
;   source file: ascii2hex.asm
;<
; * ----------------------------------------------
;*******
;****f* str_conv/hexascii2word *
; NAME
;>1 str_conv
;  hexascii2word - convert four hex ascii char to word
; INPUTS
;    esi = ptr to hex ascii data
;    ebx = zero or previous sum
; OUTPUT
;    ebx = contains hex , the previous contents
;          are shifted left
; NOTES
;   source file: ascii2hex.asm
;<
; * ----------------------------------------------
;*******
;****f* str_conv/hexascii2dword *
; NAME
;>1 str_conv
;  hexascii2dword - convert eight hex ascii char to dword
; INPUTS
;    esi = ptr to hex ascii data
;    ebx = zero or previous sum
; OUTPUT
;    ebx = contains hex , the previous contents
;          are shifted left
; NOTES
;   source file: ascii2hex.asm
;<
; * ----------------------------------------------
;*******

  global hexascii2dword,hexascii2word,hexascii2byte,hexascii2nibble
hexascii2dword:
  call	hexascii2word
hexascii2word:
  call	hexascii2byte
hexascii2byte:
  call	hexascii2nibble
hexascii2nibble:
  shl	ebx,4		;adjust any previous result
  lodsb
  sub	al,'0'
  cmp	al,9
  jle	h_ok
  sub	al,7
h_ok:
  or	bl,al
  ret