
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
;  sort_dword_array - use bubble sort on array of dwords
;    array is sorted in place and must be in
;    a .bss or .text section that is writable.
;    negative numbers are assumed to be smaller and will be
;    at top of sort.
; INPUTS
;   edi = pointer to array
;   edx = number of array items
;
; output:
;    ecx,ebx=0 if more than 2 items in array
;    esi=ptr to last array entry if more than 2 items in array
;    all other registers unchanged.
;    array entries are reordered in acending order
; destroys:
;   eax, esi, ecx
;   eflags
; NOTES
;   source file: sort_dword_array.asm
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
  mov	edx,4
  call	sort_dword_array
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

  global sort_dword_array
sort_dword_array:
  cld
outloop:
  xor	ebx,ebx			;clear exchange flag
  mov	ecx,edx			;get loop count
  mov	esi,edi			;get array ptr
  dec	ecx			;adjust loop count
  jecxz sd_exit			;exit if 1 array entry
  js	sd_exit			;exit if 0 or negativ array entries
loop1:
  lodsd				;get trail smallest
  cmp	eax,[esi]		;is next entry bigger
  jle	sd_10      		;jmp if next item bigger
  xchg	eax,[esi]		;swap to get new biggest
  mov	[esi-4],eax
  inc	ebx			;set exchange flag
sd_10:
  loop	loop1    
  or	ebx,ebx			;any exchanges?
  jnz	outloop			;if exchanges then do it again
sd_exit:
  ret

;-----------
;-----------
