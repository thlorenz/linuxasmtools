
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
;****f* str_conv/ascii_to_dword *
;
; NAME
;>1 str_conv
;  ascii_to_dword - convert decimal ascii string to binary
; INPUTS
;    esi = ptr to ascii string
; OUTPUT
;    ecx = binary value
;    esi = ptr past end of ascii string
; NOTES
;    source file: ascii_to_dword.asm
;<
;  * ----------------------------------------------
;*******
 global ascii_to_dword
ascii_to_dword:
  xor	ecx,ecx
  xor	eax,eax
  mov	bl,9
  cld
atd_lp:
  lodsb
  sub al,'0'
  js atd_exit
  cmp al,bl
  ja atd_exit
  lea ecx,[ecx+4*ecx]
  lea ecx,[2*ecx+eax]
  jmp short atd_lp
atd_exit:
  ret
