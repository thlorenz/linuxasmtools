
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
;----------------------------------------------------  
;>1 crt
;   crt_str - display asciiz string at curent cursor position
; INPUTS
;    ecx = ptr to string
; OUTPUT
;   uses current color, see crt_set_color, crt_clear
; NOTES
;   source  file crt_str.asm
;<
;  * ---------------------------------------------------
;*******
	%define stdout 0x1
	%define stderr 0x2


   global crt_str
crt_str:
  xor edx, edx
count_again:	
  cmp [ecx + edx], byte 0x0
  je crt_write
  inc edx
  jmp short count_again
;----------------------------------------------------  
;>1 crt
;   crt_write - display block of data
; INPUTS
;    ecx = ptr to data
;    edx = length of block
; OUTPUT
;   uses current color, see crt_set_color, crt_clear
; NOTES
;   source  file crt_str.asm
;<
;  * ---------------------------------------------------
  global crt_write
crt_write:
  mov eax, 0x4			; system call 0x4 (write)
  mov ebx, stdout			; file desc. is stdout
  int byte 0x80
  ret
