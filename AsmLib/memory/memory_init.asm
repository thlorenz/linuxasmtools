
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
;*******
;>1 memory
;  memory_init - get top of allocated memory
; INPUTS
;  none
; OUTPUT
;    eax = start adr for next allocation using brk
;    ebx = first start address found by call to
;          memory_init or zero if this is first
;          call to memory_init
; NOTES
;    source file: memory_init.asm
;    This function returns the top of allocated
;    memory.  Once the top is known, the brk kernel call
;    can be used to allocate pieces of memory.
;<
;  * ----------------------------------------------
;*******
  global memory_init

memory_init:
  xor	ebx,ebx
  mov	eax,45
  int	byte 80h
  mov	ebx,[alloc_top]
  or	ebx,ebx
  jnz	mi_exit
  mov	[alloc_top],eax
mi_exit:
  or	eax,eax		;set sign
  ret

;-------------------------------------------------
  [section .data]
alloc_top: dd 0     
  [section .text]
;--------------------------------------------------
%ifdef DEBUG

  global main,_start
main:
_start:
  nop
  call	memory_init

  mov	ebx,eax
  add	ebx,1000h
  mov	eax,45
  int	byte 80h	;allocate some memory

  call	memory_init

  mov	eax,1
  int	byte 80h
;--------
%endif
    