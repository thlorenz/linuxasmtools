
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

  mov	eax,new
  mov	ebx,chain
  call	chain_double
  mov	eax,new
  call	unchain_double
  mov	eax,1
  int	80h


  [section .data]
chain:
pkt1:	dd	pkt2
	dd	0
pkt2:	dd	0
	dd	pkt1

new:	dd	0,0

  [section .text]

%undef DEBUG
%include "unchain_double.asm"
%define DEBUG


%endif

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;>1 memory
;  chain_double - chain (add) to doubly linked list
;             each link has two dwords at top, the forward
;             pointer and back pointer.
;  INPUTS     eax = ptr to new link
;             ebx = ptr to insert point, any illegal value inserts
;                   at end of chain. Typically -1 is insert at end.
;                   Setting ebx to chain start will not create a new
;                   start link, instead the link is placed after the
;                   header link.  For this reason the header link is
;                   usually a dummy pointer that is the start of chain.
;             To start a new chain, create a dummy link and set
;             it chain pointers (first dword) to zero and the second
;             dword to zero.  The first dword is forward ptr and the
;             second is back pointer
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
;  NOTE       source file is chain_double.asm
;             Doubly linked lists are much faster to access
;             but take more memory.
;
;<
;  * ----------------------------------------------

  global chain_double
chain_double:
  push	esi
  push	ebx
  mov	esi,[ebx]	;get existing fwd ptr
  mov	[ebx],eax	;insert our fwd ptr
  mov	[eax],esi	;point our link at orig. fwd ptr

  or	esi,esi		;check if at end of chain
  jnz	cd_normal
  mov	[eax+4],ebx
  jmp	short cd_exit
cd_normal:
  mov	ebx,[esi+4]	;get bak ptr for new pkt
  mov	[eax+4],ebx
  mov	[esi+4],eax
cd_exit:
  pop	ebx
  pop	esi
  ret

