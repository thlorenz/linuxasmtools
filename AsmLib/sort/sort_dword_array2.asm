
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

;%define DEBUG
;****f* sort/sort_selection *
; NAME
;>1 sort
;  sort_dword_array2 - use selection sort on array of dwords
;    array is sorted in place and must be in
;    a .bss or .text section that is writable.
;    negative numbers are assumed to be smaller and will be
;    at top of sort.
; INPUTS
;   edi = pointer to array
;   ecx = number of array items
;
; output:
;    all registers destroyed
;    array entries are reordered in acending order
; NOTES
;   source file: sort_dword_array2.asm
;   The selection sort is fairly fast for arrays in
;   random order.  The bubble sort is slow for most
;   jobs, but is fast on arrays that are partially
;   sorted.
;<
; * ----------------------------------------------
;*******
;

%ifdef DEBUG

 [section .text]
 global _start
 global main
_start:
main:    ;080487B4
  cld
  mov	edi,array
  mov	ecx,2
  call	sort_dword_array2
  mov	eax,1
  int	80h

  [section .data]
array:	dd	5
	dd	2
	dd	-1
	dd	1
  [section .text]
%endif
;----------------------------------------------------

  global sort_dword_array2
sort_dword_array2:
  jecxz	sd_exit			;exit if empty array
  cld
  jecxz	sd_exit			;exit if array only has one entry
  dec	ecx
loopa:
  mov	esi,edi
  lodsd				;get prime value
  mov	ebx,ecx
loopy:
  cmp	[esi],eax
  jge   loopb
  xchg  eax,[esi]
  add	esi,4
loopb:
  dec	ebx
  jnz	loopy
  stosd
  loop	loopa
sd_exit:
  ret

;-----------
;-----------
