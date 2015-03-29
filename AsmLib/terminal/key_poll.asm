
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

;>1 terminal
;  key_poll - check if key avail.
; INPUTS
;    terminal must be in raw mode
; OUTPUT
;    zero flag for jz set if no key available
; NOTES
;    source file: key_mouse.asm
;<
; * ----------------------------------------------
 global key_poll  
key_poll:
  push	ecx
  mov	eax,168			;poll
  mov	ebx,poll_tbl
  mov	ecx,1			;one structure at poll_tbl
  mov	edx,2			;wait xx ms
  int	80h
  test	byte [poll_rtn],1
  pop	ecx
  ret


  [section .data]
  global poll_rtn
poll_tbl	dd	0	;stdin
		dw	1	;events of interest
poll_rtn	dw	-1	;return from poll
  [section .text]


