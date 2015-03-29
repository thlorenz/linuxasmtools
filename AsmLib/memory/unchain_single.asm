
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
%define DEBUG
%undef DEBUG
%define LIBRARY

  [section .text]  

%ifdef DEBUG

 global _start
 global main
_start:
main:
;add a link to chain
  mov	eax,chain+4
  mov	esi,chain
  mov	ebx,chain		;insert point
  xor	edi,edi
  call	chain_single
  mov	eax,chain+8
  mov	esi,chain
  mov	ebx,chain+4
  xor	edi,edi
  call	chain_single
;add to end
  mov	eax,chain+0ch
  mov	esi,chain
  mov	ebx,-1
  xor	edi,edi
  call	chain_single
;unchain the links
  mov	esi,chain
  mov	ebx,chain+8
  xor	edi,edi
  call	unchain_single
  mov	esi,chain
  mov	ebx,chain+4
  xor	edi,edi
  call	unchain_single
  mov	ebx,chain+4
  mov	esi,chain
  xor	edi,edi
  call	unchain_single



  mov	eax,1
  int	80h

  [section .data]
chain:	times 8 dd 0
  [section .text]

%undef DEBUG
%include "chain_single.asm"
%define DEBUG

%endif

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;>1 memory
;  unchain_single - unchain (remove) link from singly linked list
;  INPUTS     esi = chain start, used if edi=0
;             ebx = link to remove
;             edi = link preceeding the removal point if
;                   known, else zero
;  OUTPUT     carry set = link was not found in chain
;             if no carry then success
;             ebx     = unchanged
;             esi,edi = modified
;
;             complete chain consists of a start link
;             followed by a succession of pointers ending
;             with a zero pointer.  Each link points to the
;             next link.  A null chain has a start link of
;             zero.
;
;  NOTE       source file is unchain_single.asm
;
;<
;  * ----------------------------------------------

  global unchain_single
unchain_single:
  or	edi,edi
  jnz	us_20		;jmp if bak-chain found
us_lp1:
  cmp	[esi],ebx	;are we at unchain point
  je	us_30
  cmp	[esi],dword 0	;are we at end
  je	us_40		;jmp if at end of chain
  mov	esi,[esi]	;get fwd-chain
  jmp	short us_lp1	;loop
us_20:
  mov	esi,edi
;we have found the unchain point
; esi points to bak-link  edi points to fwd link  ebx is new link
us_30:
  mov	edi,[ebx]	;get new fwd chian
  mov	[esi],edi	;point bak-link at new-link
  clc
  jmp	short us_exit
;we were provided the bak-link (edi)
;ebx=ptr to link for removal
us_40:
  stc
us_exit:
  ret

