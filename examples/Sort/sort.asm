
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

; sort program, called as:   test_sort infile outfile
;
; sorts infile and stores at outfile.  This version
; does not allocate memory, so file and index must
; fit in 300k
;
; The merge_sort is a binary sort and does not check
; for end of line characters.  This may place short
; lines in the wrong place if the sort key picks up
; data beyond the eol.

 extern block_read_all
 extern block_open_write
 extern block_write
 extern block_close
 extern sort_merge_lines


 [section .text]
 global _start
 global main
_start:
main:    ;080487B4

  pop	ebx
  cmp	ebx,3			;should be 3
  je	sort1
  jmp	all_done
sort1:
  pop	ebx			;get ptr to executable name
  pop	ebx			;get file name paramater
  pop	eax			;get file2
  mov	[out_file],eax
;read file
  mov	ecx,buffer		;pointer to read file into
  mov	edx,200000		;max buffer size
  call	block_read_all
  or	eax,eax
  jns	sort2
  jmp	all_done		;jmp if error
;index file
sort2:
 add	eax,ecx			;compute buffer end
 mov	[buffer_end],eax
 add	eax,4
 and	eax,-3			;put eax on dword buondry
 mov	[index_start],eax	;save index build area

 mov	esi,buffer
 mov	edi,[index_start]
 mov	eax,esi
i_lpx:
cmp	esi,[buffer_end]
 je	i_done
 stosd				;store first index
i_loop:
 cmp	esi,[buffer_end]
 jae	i_done
 lodsb
 cmp	al,0ah
 jne	i_loop
 mov	eax,esi
 jmp	short i_lpx
i_done:
  xor	eax,eax
  stosd				;put zero at end of index

  sub	edi,[index_start]
  shr	edi,2			;compute number of indexes
  sub	edi,1
  mov	[number_of_records],edi
  
  mov	ebp,[index_start]
  mov	ebx,20		;length of sort key
  mov	ecx,[number_of_records]	;number of records
  mov	edx,0		;column of sort key
  call	sort_merge_lines
;write output file
;
; open destination
;
  mov	ebx,[out_file]
  mov	edx,0
  call	block_open_write
  js	all_done
  mov	[handle],eax
;setup for write
  mov	esi,[index_start]

write_loop:
  cmp	[esi],dword 0		;is this the end of list
  je	write_done
  lodsd				;get next index
  mov	ecx,eax			;get ptr to data
;find record length
  push	esi
  mov	esi,ecx			;point at record
  mov	edx,0
wl_loop:
  inc	edx
  lodsb
  cmp	al,0ah
  je	wl_end
  cmp	al,09
  je	wl_loop
  cmp	al,0
  jne	wl_loop
wl_end:
  pop	esi
;
; write block
;
  mov	ebx,[handle]
  call	block_write
  jmp	write_loop
write_done:
  mov	ebx,[handle]
  call	block_close

all_done:
  mov	eax,1
  int	80h

  [section .data]

out_file	dd	0
buffer_end	dd	0
index_start	dd	0
number_of_records dd	0
handle		dd	0
  [section .text]

  [section .bss]
buffer:	resb	300000

