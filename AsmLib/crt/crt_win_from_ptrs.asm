
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

  extern crt_line
;---------------------------------------------
;****f* crt/crt_win_from_ptrs *
; NAME
;>1 crt
;  crt_win_from_ptrs - display window using ptrs to lines
; INPUTS
;    ebx = ptr to color table
;    ch  = starting row
;    cl  = starting col
;    dl = number of cols
;    dh = number of rows
;    ebp = ptr to list of line ptrs
;    edi = adjustment to pointers in pointer list (ebp).
;          negative number ok, display starts at [ptr + edi]       
;    each line terminated with 0ah or 0
;    codes 1-9 found in line are color info.
; OUTPUT
;
; NOTES
;   source file: crt_ptr_window.asm
;<
; * ----------------------------------------------
;*******
  global crt_win_from_ptrs
crt_win_from_ptrs:
;swfp_lp:
  mov	esi,[ebp]	;get ptr to next line
  or	esi,esi		;check if end of table
  jnz	swfp_10		;jmp if line ok
  mov	esi,swfp_blank
  sub	ebp,4		;move to prev line
  jmp	short swfp_20
swfp_10:
  add	esi,edi		;move to desired column
swfp_20:
  push	edi
  push	ecx
  push	edx
  push	ebx
  xor	edi,edi		;set scroll to zero
  call	crt_line
  pop	ebx
  pop	edx
  pop	ecx
  pop	edi
  inc	ch		;move to next row
  add	ebp,4		;move to next line
  dec	dh
  jnz	crt_win_from_ptrs		;loop till done
  ret

swfp_blank:  db ' ',0ah

