
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
;%define DEBUG

  [section .text]  

%ifdef DEBUG
  extern dir_open
  extern dir_close

 global _start
 global main
_start:
main:    ;080487B4
  cld
  mov	ebx,pathx
  mov	eax,p_end
  call	dir_open
;eax=dir_block
  push	eax
  call	dir_index
  pop	eax
;eax=negative if error
  call	dir_close
  mov	eax,1
  int	80h

;pathx: db '/usr/share/doc/',0
pathx:	db '/home/jeff/asm/test/dir/test',0

 [section .bss]
p_end:

%endif

%ifndef INCLUDES
;-------------------------------------------
; structure describing status of dir_xxxx library operations
struc dir_block
.handle			resd 1 ;set by dir_open
.allocation_end		resd 1 ;end of allocated memory
.dir_start_ptr		resd 1 ;ptr to start of dir records
.dir_end_ptr		resd 1 ;ptr to end of dir records
.index_ptr		resd 1 ;set by dir_index
.record_count		resd 1 ;set by dir_index
.work_buf_ptr		resd 1 ;set by dir_sort
dir_block_struc_size:
endstruc

; structure describing a directory entry (dirent) on disk
struc dents
.d_ino	resd 1	;inode number
.d_off	resd 1	;offset to next dirent from top of file
.d_reclen resw 1;length of this dirent
.d_name resb 1	;directory name (variable length)
endstruc
%endif

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -( SEARCH  )
;>1 dir
;  dir_index - index an open directory
;     allocates memory for an index and fills with pointers
;     to directory entries.  End of pointers is a zero ptr.
;     The records_count of dir_block structure is set and
;     so is .allocation_end.  index_ptr points to the index.
;  INPUTS
;     eax = ptr to dir_block (see following struc)    
;     struc dir_block
;      .handle			;set by dir_open
;      .allocation_end		;end of allocated memory
;      .dir_start_ptr		;ptr to start of dir records
;      .dir_end_ptr		;ptr to end of dir records
;      .index_ptr		;set by dir_index
;      .record_count		;set by dir_index
;      .work_buf_ptr		;set by dir_sort
;      dir_block_struc_size
;     endstruc
;
;  OUTPUT     eax = + if sucessful, else memory allocation error
;             The the index entries point to file name within
;             the dents structure.
;  NOTE
;     source file is dir_index.asm
;     related functions are: dir_open - allocate memory & read
;                            dir_index - allocate memory & index
;                            dir_open_indexed - dir_open + dir_index
;                            dir_sort - allocate memory & sort
;                            dir_open_sorted - open,index,sort
;                            dir_close - release memory & file
;
;<
;  * ----------------------------------------------

  global dir_index
dir_index:
  mov	[dir_block_ptr],eax	;save dir_block ptr
;count records to find size of memory to allocate for index
  mov	esi,[eax + dir_block.dir_start_ptr]
  xor	edx,edx				;record length reg
  mov	ecx,200000			;record counter
di_loop1:
  mov	dx,[esi + dents.d_reclen]	;get record length
  add	esi,edx				;move to next record
  cmp	[esi + dents.d_off],dword 0	;check for end of list
  jz	di_10				;jmp if end of dirents
  loop	di_loop1
di_10:
  neg	ecx
  add	ecx,200001			;compute dirent count
;align index start to dword boundry
  mov	ebx,[eax + dir_block.allocation_end] ;get end of memory
  add	ebx,8
  and	ebx,~7			;move to dword boundry
  mov	[eax + dir_block.index_ptr],ebx ;save index start
  mov	[eax + dir_block.record_count],ecx
;compute index end point
  shl	ecx,2			;compute total bytes in index
  add	ebx,ecx			;compute end of index
  add	ebx,8			;add extra memory
;allocate memory for index
  mov	eax,45
  int	80h			;allocate memory
  or	eax,eax
  js	di_error		;jmp if allocaton  error
  mov	edx,[dir_block_ptr]
  mov	[edx + dir_block.allocation_end],eax    
;setup to build index
  mov	eax,[edx + dir_block.dir_start_ptr]
  mov	edi,[edx + dir_block.index_ptr]
  mov	ecx,[edx + dir_block.record_count]
  xor	edx,edx
di_loop2:
  stosd					;store index entry
  mov	dx,[eax + dents.d_reclen]	;move to next dirent
  add	eax,edx				;move to next dirent
  loop	di_loop2			;loop till done
  xor	eax,eax
  stosd					;put zero at end
  mov	eax,[dir_block_ptr]
;remove two top . and .. entries from index
;  add	[eax + dir_block.index_ptr],dword 8 ;skip over first two indexes
;  sub	[eax + dir_block.record_count],dword 2 ;reduce index count by 2
;eax is positive here, indicating success for exit   
di_error: 
  ret
;------------
  [section .data]
dir_block_ptr: dd	0	;ptr to dir_block
  [section .text]
