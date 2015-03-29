
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
; lookup_token.asm
  extern str_compare

  [section .text]
;>1 str_parse
;  lookup_token - check if token on list
; INPUTS
;    esi = pointer to token (string)
;    edi = pointer to list of legal tokens
;          Token list is terminated with
;          zero char after last string.
;
; OUTPUT
;    if flag <eq> set, ecx=token index.  First
;                 token is index 0
;       flag <ne> set, token not on list, ecx
;                 set to number of tokens on list
; NOTES
;   source file: lookup_token.asm
;<
; * ----------------------------------------------
;*******
  global lookup_token
lookup_token:
  mov	ebx,esi		;save token start
  xor	ecx,ecx		;set index to  zero
lt_lp1:
  call	str_compare
  je	lt_exit
  inc	ecx
  dec	edi		;move back to prev mismatch (fixes bug!)
lt_lp2:
  cmp	byte [edi],0
  je	lt_10		;jmp if end of table entry
  inc	edi
  jmp	short lt_lp2
lt_10:
  inc	edi		;move to next table entry
  mov	esi,ebx
  cmp	byte [edi],0	;end of table
  jne	lt_lp1
  cmp	ecx,ebx		;set flag for jne
lt_exit:
  ret
 

;---------------------------------------
%ifdef DEBUG
  global _start
_start:
  mov	esi,token1
  mov	edi,tlist
  call	lookup_token
  je	ok1
  nop			;error
ok1:
  mov	esi,token2
  mov	edi,tlist
  call	lookup_token	;should return ecx=1
  je	ok2
  nop			;error
ok2:
  mov	esi,token3
  mov	edi,tlist
  call	lookup_token
  jne	ok3		;
  nop			;error
ok3:
  mov	eax,1
  int	byte 80h


  [section .data]
token1: db 'dog',0
token2: db "cat",0
token3: db 'rat',0

tlist:
 db 'tiger',0
 db 'dog',0
 db 'cat',0
 db 0
%endif
  [section .text]
;---------------------------------------
