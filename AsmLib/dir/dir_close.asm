
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

 global _start
 global main
_start:
main:    ;080487B4
  cld
  mov	ebx,pathx
  call	dir_open

  mov	eax,1
  int	80h

pathx: db '/usr/share/doc/',0

%endif
;-------------------------------------------

%ifndef INCLUDES
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
%endif

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -( SEARCH  )
;>1 dir
;  dir_close - close a open directory and release memory
;
;  INPUTS
;     eax = dir_block ptr
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
;  OUTPUT     eax = 0 if sucessful
;
;  NOTE
;     source file is dir_open.asm
;     related functions are: dir_open - allocate memory & read
;                            dir_index - allocate memory & index
;                            dir_open_indexed - dir_open + dir_index
;                            dir_sort - allocate memory & sort
;                            dir_open_sorted - open,index,sort
;                            dir_close - release memory & file
;
;<
;  * ----------------------------------------------

  global dir_close
dir_close:
  push	eax		;mov	[block],eax
  mov	ebx,[eax + dir_block.handle]
  mov	eax,6		;close
  int	80h  
  pop	ebx		;get start of allocated memory
  mov	eax,45
  int	80h
  ret

  [section .text]
