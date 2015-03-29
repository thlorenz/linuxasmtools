
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

 global _start
 global main
_start:
main:    ;080487B4
  cld
  mov	eax,bss_end
  mov	ebx,pathx
  call	dir_open_indexed

  mov	eax,1
  int	80h

pathx: db '/usr/share/doc/',0

  [section .bss]
bss_end:
  [section .text]
%endif
;-------------------------------------------

  extern  dir_open
  extern  dir_index

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


;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -( SEARCH  )
;>1 dir
;  dir_open_indexed - open a directory and index
;
;  INPUTS
;     eax = end of .bss section memory
;           Used to allocate memory.  This section
;           must be at end of program.
;     ebx = directory path
;
;     calling example:
;           mov  eax,last_bss
;           mov	 ebx,dir_path
;           call dir_open_indexed
;           or   eax,eax
;           js   error 
;           ( normal code here)
;           [section .data]
;           dir_path: db "/home/sam",0
;           [section .bss]
;           last_bss:
;           
;
;  OUTPUT     eax = negative if error else dir_block ptr
;     struc dir_block
;      .handle			;set by dir_open
;      .allocation_end		;end of allocated memory
;      .dir_start_ptr		;ptr to start of dir records
;      .dir_end_ptr		;ptr to end of dir records
;      .index_ptr		;set by dir_index
;      .record_count		;set by dir_index
;      .work_buf_ptr		;future use by dir_sort
;      dir_block_struc_size
;     endstruc
;
;  NOTE
;     source file is dir_open_indexed.asm
;     related functions are: dir_open - allocate memory & read
;                            dir_index - allocate memory & index
;                            dir_open_indexed - dir_open + dir_index
;                            dir_sort - allocate memory & sort
;                            dir_open_sorted - open,index,sort
;                            dir_close - release memory & file
;
;<
;  * ----------------------------------------------

  global dir_open_indexed
dir_open_indexed:
  call	dir_open
  or	eax,eax
  js	doi_exit		;jmp if error
  call	dir_index
doi_exit:
  ret
