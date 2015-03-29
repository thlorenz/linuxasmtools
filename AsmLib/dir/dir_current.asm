
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
;***************  file:  dir_current.asm  *********************


;--------------------------------------------
;>1 dir
;   dir_current - get current working directory
; INPUTS    none
;
; OUTPUT    eax = size of path string or negative error#
;           ebx = ptr to path if eax positive
;           ecx - modified                     
;          
; NOTES:  Source file is dir_current.asm
;         Error returns from this function are
;         possible, but almost never occur.
;<
;--------------------------------------------
  extern lib_buf

  global dir_current
dir_current:
  mov	eax,183		;kernel code to get dir
  mov	ebx,lib_buf
  mov	ecx,300
  int	byte 80h
  ret
;-----------------------------------------
%ifdef DEBUG
global main,_start
main:
_start:
  nop
  call	dir_current
  mov	eax,1
  int	byte 80h

%endif
