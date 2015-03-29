
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
;%define DEBUG

  [section .text]  

%ifdef DEBUG

 global _start
 global main
_start:
main:    ;080487B4

  mov	eax,1
  int	80h
%endif

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;>1 memory
;  set_memory - adjust memory end point
;             set_memory is a simple way of  managing memory for
;             a program.  It uses the kernel "brk" call to extend
;             or contract the .bss section end.
;  INPUTS     ebx = new end point for executing program
;
;  OUTPUT     eax = new end point if sucessful, or negative error
;
;  NOTE       source file is set_memory.asm
;
;<
;  * ----------------------------------------------

  global set_memory
set_memory:
  mov	eax,45
  int	80h
  ret

