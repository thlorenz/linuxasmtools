
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
;----------------------------------------------------------
;>1 sound
;  compute_wave_count - compute number of waves
; INPUTS
;    eax = duration in ms
;    ebx = frequency of sound
; OUTPUT:
;    eax = number of waves
;          negative if error
; NOTES
;   source file: compute_wave_count.asm
;<
; * ----------------------------------------------
  global compute_wave_count
compute_wave_count:
  push	eax			;save duration in ms
  mov	eax,1000000		;get million
  xor	edx,edx	
  div	ebx			;compute u-seconds per cycle
  mov	[usec_per_cycle],eax
;compute total usec
  pop	eax			;get length of tone in ms
  mov	ebx,1000
  mul	ebx			;compute lenght in usec
;compute
  mov	ebx,[usec_per_cycle]
  cmp	eax,ebx			;verify we have at least one wave
  jb	cwc_error
  div	ebx			;compute total waves
  jmp	short cwc_exit
cwc_error:
  mov	eax,-1
  jmp	short cwc_exit
cwc_exit:
  ret
;-------
  [section .data]
usec_per_cycle:	dd 0
  [section .text]
;----
