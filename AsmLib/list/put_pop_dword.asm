
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
;---------------------------------------------------------------------
;>1 list
;  put_pop_dword_setup - setup dword list
; INPUTS
;    eax = buffer ptr (will hold list)
; OUTPUT
;    none (no  registers changed)
; NOTES
;   source file: put_pop_dword.asm
;   this function works with:
;      put_pop_dword_setup - defines list
;      put_dword  - adds dword to list top
;      pop_dword  - returns dword from top
;<
; * ----------------------------------------------
; input: eax=buffer ptr
;
  global put_pop_dword_setup
put_pop_dword_setup:
  mov	[dword_top_ptr],eax
  mov	[dword_put_ptr],eax
  ret
;---------------------------------------------------------------------
;>1 list
;  put_dword - add dword to top of list
; INPUTS
;    eax = dword value added to list
; OUTPUT
;    none (no  registers changed)
; NOTES
;   source file: put_pop_dword.asm
;   this function works with:
;      put_pop_dword_setup - defines list
;      put_dword  - adds dword to list top
;      pop_dword  - returns dword from top
;<
;-----------------------------------
; input: eax=put value
;
  global put_dword
put_dword:
  push	ebx
  mov	ebx,[dword_put_ptr]
  mov	[ebx],eax
  add	ebx,byte 4
  mov	[dword_put_ptr],ebx
  pop	ebx
  ret
;---------------------------------------------------------------------
;>1 list
;  pop_dword - remove dwort from top of list
; INPUTS
;    none
; OUTPUT
;    if no carry, eax = popped value
;    if    carry, at top of list
; NOTES
;   source file: put_pop_dword.asm
;   this function works with:
;      put_pop_dword_setup - defines list
;      put_dword  - adds dword to list top
;      pop_dword  - returns dword from top
;<
;-----------------------------------
; output: carry set if at top already
;         eax = value if no carry
  global pop_dword
pop_dword:
  push	esi
  mov	esi,[dword_put_ptr]
  cmp	esi,[dword_top_ptr]
  je	pd_error	;exit if at top
  sub	esi,4		;move to last push
  mov	eax,[esi]	;get last push
  mov	[dword_put_ptr],esi
  clc
  jmp	short pd_exit
pd_error:
  stc
pd_exit:
  pop	esi
  ret
  

;--------------
  [section .data]
dword_top_ptr: dd 0
dword_put_ptr: dd 0

%ifdef DEBUG
  [section .text]
global main,_start

main:
_start:
  mov	eax,buf
  call	put_pop_dword_setup
  mov	eax,12345678h
  call	put_dword
  xor	eax,eax
  call	pop_dword
  mov	eax,1
  int	80h
;-------------
  [section .data]
buf: times 3 dd 0
%endif

  [section .text]

