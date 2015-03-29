
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

;****f* sort/sort_selection *
; NAME
;>1 sort
;  sort_selection - use selection sort with ptr list
; INPUTS
;    ebp - pointer to pointers for each record
;          last pointer equals zero
;    edx = column to use as sort data
;          0=first column
;    ecx = length of sort
; OUTPUT
;    pointers ordered by decending  records 
; NOTES
;   source file: sort_selection.asm
;   The index must have at least one entry.
;<
; * ----------------------------------------------
;*******
;
  global sort_selection
sort_selection:
  mov	[sort_field_length],ecx
  cmp	dword [ebp],0			;check if nothing to sort
  jz	ss_done
ss_lp1:
  mov	ebx,ebp
  add	ebx,4
  cmp	dword [ebx],0			;check if sort done
  je	ss_done
; do compare
ss_lp2:
  mov	esi,[ebp]			;get current selection
  mov	edi,[ebx]			;get challenger
  mov	ecx,[sort_field_length]
  add	esi,edx				;move to selected column
  add	edi,edx				;move to selected column
  repe	cmpsb				;compare
  jbe	next_challenger			;jmp if not smaller
; we have found a smaller entry
  mov	eax,[ebp]	;get old lowest
  xchg	eax,[ebx]	;put at challenger's space
  mov	[ebp],eax	;put challenger at top
next_challenger:
  add	ebx,4		;move to next challenger
  cmp	dword [ebx],0	;at end of this pass?
  jne	ss_lp2		;loop till done
; move past current small and start again
  add	ebp,4
  jmp	ss_lp1	
ss_done:
  ret
;-----------
  [section .data]
sort_field_length  dd	0
  [section .text]
;-----------
