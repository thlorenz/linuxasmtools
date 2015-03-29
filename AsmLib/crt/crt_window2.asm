
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
  extern crt_line
;****f* crt/crt_window2 *
; NAME
;>1 crt
;  crt_window2 - display window with embedded color
;    codes, window size is input.
; INPUTS
;    ebx = ptr to color list, each color def is dword
;    ch = starting row 1+
;    cl = starting column 1+
;    dl = max line length, must be 1+
;    dh = row count 1+
;    esi = ptr to data for line
;      color codes start at 1 (first color in table)
;      color codes 1-9 are possible.
;      number of lines must equal or greater than size
;      of window.
; PROCESSING:
;    crt_window2 is given a buffer with lines of text.
;    Each line ends with 0ah.  The lines are displayed
;    by calling crt_line.
;   
; OUTPUT
;    window displayed
; NOTES
;   source file:  crt_window2.asm
;<
; * ----------------------------------------------
;*******
  global crt_window2
crt_window2:
cw2_lp:
  push	ebx
  push	ecx
  push	edx
  mov	edi,0		;set scroll to 0
  call	crt_line
  pop	edx
  pop	ecx
  pop	ebx
  inc	ch		;move to next row
  dec	dh
  jnz	cw2_lp
  ret	  
