
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

 global _start, main
_start:
main:
  stc
  clc
  xor	eax,eax
  sub 	eax,byte 1
  rol   eax,1
  nop	;nop
  mov	eax,1 ;this is second comment
  int	byte 80h
;-----------
  [section .bss]
data1:
  resb	1	;data 1
data2:
  resb	2	;data 2
data3:
  resd	1	;data 3
