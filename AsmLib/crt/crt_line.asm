
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
 extern lib_buf
 extern move_cursor
 extern crt_str
 extern mov_color

;****f* crt/crt_line *
; NAME
;>1 crt
;  crt_line - display line with embedded color codes
;     and fit line into window area
; INPUTS
;    ebx = ptr to color list, each color def is dword
;    ch = starting row 1+
;    cl = starting column 1+
;    dl = max line length, must be 1+
;    esi = ptr to data for line, each line end with 0ah, or 0
;      color codes start at 1 (first color in table)
;      color codes 1-9 are possible.
;    edi = scroll counter
; OUTPUT
;    line is built in buffer lib_buf then displayed
;    esi - points at char beyond 0ah
; NOTES
;   source file: crt_line.asm
;<
; * ----------------------------------------------
;*******
  global crt_line
crt_line:
  mov	[cl_scroll],edi
  mov	edi,lib_buf
  mov	dh,0		;current column
cl_lp0:
  xor	eax,eax		;clear eax for color lookup
cl_lp1:
  lodsb
  cmp	al,09h		;check if  tab
  jne	cl_check	;jmp if not tab
;process tab
  mov	al,' '
tab_lp:
  call	stuff_char
  test	dh,7
  jz	cl_lp1
  jmp	short tab_lp

cl_check:
  cmp	al,0ah
  jbe	cl_code		;jmp if end of line or color
  call	stuff_char
  jnz	cl_lp1		;loop if not right edge of window
; adjust input data ptr to end of line, for callers convience
cl_lp2:
  lodsb
  or	al,al
  jz	cl_line		;jmp if end of line found
  cmp	al,0ah
  jne	cl_lp2
  jmp	short cl_line	;jmp if at right edge of window
cl_code:
  je	cl_eol		;jmp if eol character 0ah found
  or	al,al
  jz	cl_eol		;jmp if eol character
  dec	al
; look up color
  shl	eax,2
  add	eax,ebx		;compute ptr to color
  mov	eax,[eax]	;get color
  call	mov_color
  jmp	short cl_lp0	;continue
; end of line found, fill to right edge
cl_eol:
  mov	al,' '
  call	stuff_char
  jnz	cl_eol
; line is built, now display
cl_line:  
  mov	byte [edi],0	;terminate line
; move cursor
  mov	eax,ecx		;get row and column
  call	move_cursor
; display line
  mov	ecx,lib_buf
  call	crt_str
  ret
;--------------------------------------------
; input edi = stuff ptr
;        al = character to buffer
;        dl = display column
;       [scroll] = scroll counter
; output: dl = new display column
;         flag = jz set if end of display
;       edi = updated stuff ptr
;
stuff_char:
  cmp	dword [cl_scroll],0
  je	sc_cont			;jmp if no scroll
  dec	dword [cl_scroll]
  or	eax,eax			;remove jz flag for exit state
  jmp	sc_exit
sc_cont:
  stosb				;store char
  inc	dh			;bump column 
  dec	dl			;dec window size
sc_exit:
  ret

;------------------
  [section .data]
cl_scroll:	dd	0
  [section .text]
