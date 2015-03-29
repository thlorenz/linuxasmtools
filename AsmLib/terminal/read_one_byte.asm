
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

;>1 terminal
;  read_one_byte - read one byte from stdin
; INPUTS
;    ecx = storage ptr
; OUTPUT
;    [ecx] = ptr beyond key stored
; NOTES
;    source file: read_one_byte.asm
;    The terminal is assumed to be in raw mode.
;    Normally this program is only called from
;    key_mouse or other keyboard handlers.
;<
; * ----------------------------------------------
  global read_one_byte
read_one_byte:
  mov	edx,1				;read one key
  mov	eax,3				;sys_read
  mov	ebx,0				;stdin
  int	0x80
  cmp	al,1
  jne	rok_exit
  add	ecx,eax			;move buffer pointer
rok_exit:
  ret

