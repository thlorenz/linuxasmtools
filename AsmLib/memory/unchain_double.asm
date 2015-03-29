
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
%undef DEBUG
%define LIBRARY

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
;  unchain_double - unchain (remove) link from doubly link list
;             each link has two dwords at top, the forward
;             pointer and back pointer.
;  INPUTS     eax = ptr to link for removal
;
;  OUTPUT
;             no registers are changed.
;
;             complete chain consists of a start link
;             followed by a succession of pointers ending
;             with a zero pointer.  Each link points to the
;             next link.  A null chain has a start link of
;             zero.  The last link has a forward pointer of
;             zero.
;
;  NOTE       source file is unchain_double.asm
;             Doubly linked lists are much faster to access
;             but take more memory.
;
;<
;  * ----------------------------------------------

  global unchain_double
unchain_double:
  push	eax
  push	esi
  push	edi
  mov	esi,[eax+4]	;get bak link ptr
  mov	edi,[eax]	;get fwd link ptr

  or	edi,edi		;check if removing last link
  jnz	ud_normal
  mov	[esi],dword 0
  jmp	short ud_exit
ud_normal:
  mov	[esi],edi	;point fwd to next pkt
  mov	[edi+4],esi
ud_exit:
  pop	edi
  pop	esi
  pop	eax
  ret

