
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
    
;>1 terminal
;   scroll_region - set scroll limits for terminal
; INPUTS
;    al = starting row 1+
;    ah = ending row (max 255)
;    ebx = fd for tty
; OUTPUT
;   none
; NOTES
;    source file scroll_region.asm
;<
;  * ---------------------------------------------------
;*******
  extern crt_str

  global scroll_region
scroll_region:
  push	ebx
  push	eax
  aam
  or	ax,'00'
  xchg	al,ah
  mov	[sr_top],ax
  pop	eax
  mov	al,ah
  aam
  or	ax,'00'
  mov	[sr_end],ax
  mov	ecx,scroll_string
  pop	ebx		;get fd
  mov	eax,04		;write
  mov	edx,scroll_string_end - scroll_string
  int	byte 80h			;set scroll region
  ret
;--------------------
  [section .data]

scroll_string:
 db 1bh
 db '['
sr_top:
 db '00'
 db ';'
sr_end:
 db '00'
 db 'r'
scroll_string_end:
 db 0

  [section .text]

