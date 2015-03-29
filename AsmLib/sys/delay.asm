
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
    
;****f* sys/delay *
; NAME
;>1 sys
;   delay - delay microseconds or seconds
; INPUTS
;    eax = if positive it is micoseconds to delay
;          if negative it is seconds to delay
; OUTPUT
;    none
; NOTES
;    source file delay.asm
;<
;  * ---------------------------------------------------
;*******
  global delay
delay:
  or	eax,eax
  js	delay_10	;jmp if seconds
  mov	dword [time+4],eax
  mov	dword [time],0
  jmp	short delay_20
delay_10:
  neg	eax
  mov	dword [time],eax
  mov	dword [time+4],0
delay_20:
  mov	eax,162
  mov	ebx,time
  mov	edx,dummy
  int	80h
  ret
;----------
  [section .data]
time:  dd	0,1000
dummy: dd	0,0
  [section .text]


