
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
  extern raw_set2
  extern raw_unset2
  
;>1 terminal
;   stdout_str - display asciiz string at cursor position
; INPUTS
;    ecx = ptr to string
; OUTPUT
;   uses current color, see stdout_set_color, stdout_clear
; NOTES
;   source file:  stdout_str.asm
;   
;   stdout_str first sets up terminal (termios) and then
;   outputs data.  See crt_str for faster routine that
;   does not set up terminal first.
;<
;  * ---------------------------------------------------
;*******
	%define stdout 0x1
	%define stderr 0x2

   global stdout_str
stdout_str:
  push	ecx
  call	raw_set2
  pop	ecx
  xor edx, edx
.count_again:	
  cmp [ecx + edx], byte 0x0
  je .done_count
  inc edx
  jmp .count_again
.done_count:	
  mov eax, 0x4			; system call 0x4 (write)
  mov ebx, stdout			; file desc. is stdout
  int 0x80
  call	raw_unset2
  ret
