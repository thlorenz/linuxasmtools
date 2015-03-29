
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
;  chain_single - chain (add) link to singly linked list
;  INPUTS     eax = ptr to new link
;             esi = ptr to chain start, used if edi=0
;             ebx = ptr to insert point, any illegal value inserts
;                   at end of chain. Typically -1 is insert at end.
;                   Setting ebx to chain start will not create a new
;                   start link, instead the link is placed after the
;                   header link.  For this reason the header link is
;                   usually a dummy pointer that is the start of chain.
;             edi = ptr link preceeding the insert point if
;                   known, else zero
;             To start a new chain, create  initial link and set
;             it chain pointer (first dword) to zero.  Insert the
;             first link at the chain start and following links
;             at normal insert point.
;             zero and use it as chain start point
;  OUTPUT
;             eax,esi,edi  changed
;             ebx          unchanged
;
;             complete chain consists of a start link
;             followed by a succession of pointers ending
;             with a zero pointer.  Each link points to the
;             next link.  A null chain has a start link of
;             zero.  The last link has a forward pointer of
;             zero.
;
;  NOTE       source file is chain_single.asm
;             Typical usage is to define a packet of information
;             with the chain dword at top of each packet.  These
;             packets can then be sorted or collected by inserting
;             packets at the desired location.
;
;<
;  * ----------------------------------------------

  global chain_single
chain_single:
  or	edi,edi
  jnz	cs_20		;jmp if bak-chain found
  cmp	esi,ebx
  je	cs_30		;special check for start of chain
cs_lp1:
  cmp	[esi],ebx
  je	cs_30		;jmp if at insert point
  cmp	[esi],dword 0
  je	cs_30		;jmp if at end of chain
  mov	esi,[esi]
  jmp	short cs_lp1
cs_20:
  mov	esi,edi
;we have found the insert point
; esi points to bak-link  [esi] points to fwd link  eax is new link
cs_30:
  mov	edi,[esi]	;get old fwd_link
  mov	[eax],edi	;insert into our new link
  mov	[esi],eax	;point bak-link at new-link
cs_exit:
  ret

