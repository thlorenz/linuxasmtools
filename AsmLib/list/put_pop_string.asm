
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

  extern str_move
;---------------------------------------------------------------------
;>1 list
;  put_pop_string_setup - setup string list
; INPUTS
;    eax = buffer ptr (will hold list)
; OUTPUT
;    none (no  registers changed)
; NOTES
;   source file: put_pop_string.asm
;   This function works with:
;     put_pop_string_setup  - defines list
;     put_string - adds string to top of list
;     pop_string - extracts string from top
;<
;------------------------------------
; input: eax=buffer ptr
;
put_pop_string_setup:
  mov	[string_top_ptr],eax
  mov	[string_put_ptr],eax
  ret
;---------------------------------------------------------------------
;>1 list
;  put_string - add string to top of list
; INPUTS
;    esi = ptr to string
; OUTPUT
;    esi points to end of string (past zero)
; NOTES
;   source file: put_pop_string.asm
;   This function works with:
;     put_pop_string_setup  - defines list
;     put_string - adds string to top of list
;     pop_string - extracts string from top
;<
;-----------------------------------
; input: esi=put value
; output: esi=ptr to end of input string
put_string:
  push	edi
  mov	edi,[string_put_ptr]
  call	str_move
  inc	edi			;move past zero at end
  mov	[string_put_ptr],edi
  pop	edi
  ret
;---------------------------------------------------------------------
;>1 list
;  pop_string - return string at top of list
; INPUTS
;    edi = buffer to hold string
; OUTPUT
;    if no-carry edi points at end of string (zero byte)
;    if    carry (at top of list, no string available)
; NOTES
;   source file: put_pop_string.asm
;   This function works with:
;     put_pop_string_setup  - defines list
;     put_string - adds string to top of list
;     pop_string - extracts string from top
;<
; * ----------------------------------------------
;-----------------------------------
; input: edi=storage loc for string
; output: carry set if at top already
;         edi = ptr to zero at end of string if "no carry"
pop_string:
  push	esi
  mov	esi,[string_put_ptr]
  cmp	esi,[string_top_ptr]
  je	ps_error	;exit if at top
  dec	esi		;move to zero at end of prev string
ps_lp:
  dec	esi
  cmp	esi,[string_top_ptr]
  jbe	ps_at_top
  cmp	byte [esi],0
  jne	ps_lp
  inc	esi		;move past zero
ps_at_top:
  mov	[string_put_ptr],esi
  call	str_move
  clc
  jmp	short ps_exit
ps_error:
  stc
ps_exit:
  pop	esi
  ret
;--------------
  [section .data]
string_top_ptr: dd 0
string_put_ptr: dd 0

%ifdef DEBUG
  [section .text]
global main,_start

main:
_start:
  mov	eax,buf
  call	put_pop_string_setup
  mov	esi,buf
  call	put_string
  mov	edi,buf2
  call	pop_string
  mov	eax,1
  int	80h
;-------------
  [section .data]
buf: db "string",0
buf2: db '        '
%endif

  [section .text]


