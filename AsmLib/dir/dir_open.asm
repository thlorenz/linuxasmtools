
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
%undef DEBUG

  [section .text]  

%ifdef DEBUG

 global _start
 global main
_start:
main:    ;080487B4
  cld
  mov	eax,prog_end
  mov	ebx,pathx
  call	dir_open
  or	eax,eax
  js	err
  call	dir_close
err:
  mov	eax,1
  int	80h

dir_close:
  push	eax		;mov	[block],eax
  mov	ebx,[eax + dir_block.handle]
  mov	eax,6		;close
  int	80h  
  pop	ebx		;get start of allocated memory
  mov	eax,45
  int	80h
  ret


  [section .data]
pathx: db '/usr/share/doc/',0
  [section .bss]
prog_end:
%endif
;-------------------------------------------

extern lib_buf

%ifndef INCLUDES
  struc	stat_struc
.st_dev: resd 1
.st_ino: resd 1
.st_mode: resw 1
.st_nlink: resw 1
.st_uid: resw 1
.st_gid: resw 1
.st_rdev: resd 1
.st_size: resd 1
.st_blksize: resd 1
.st_blocks: resd 1
.st_atime: resd 1
.__unused1: resd 1
.st_mtime: resd 1
.__unused2: resd 1
.st_ctime: resd 1
.__unused3: resd 1
.__unused4: resd 1
.__unused5: resd 1
;  ---  stat_struc_size
  endstruc

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

 extern dir_read_grow
;%include "dir_read_grow.inc"

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;>1 dir
;  dir_open - allocate memory and read directory
;     A dir_block is created and returned
;     to caller (see outputs)
;  INPUTS
;     eax = end of .bss section memory
;           Used to allocate memory.  This section
;           must be at end of program.
;     ebx = directory path
;
;     calling example:
;           mov  eax,last_bss
;           mov	 ebx,dir_path
;           call dir_open
;           or   eax,eax
;           js   error 
;           ( normal code here)
;           [section .data]
;           dir_path: db "/home/sam",0
;           [section .bss]
;           last_bss:
;           
;
;
;  OUTPUT     eax = negative if error, else it contains
;                   a ptr to the following block.
;
;     struc dir_block
;      .handle			;set by dir_open
;      .allocation_end		;end of allocated memory
;      .dir_start_ptr		;ptr to start of dir records
;      .dir_end_ptr		;ptr to end of dir records, + 8 zeros
;      .index_ptr		;set by dir_index
;      .record_count		;set by dir_index
;      .work_buf_ptr		;set by dir_sort
;      dir_block_struc_size
;     endstruc
;
;  NOTE
;     source file is dir_open.asm
;     related functions are: dir_open - allocate memory & read
;                            dir_index - allocate memory & index
;                            dir_open_indexed - dir_open + dir_index
;                            dir_sort - allocate memory & sort
;                            dir_open_sorted - open,index,sort
;                            dir_close_file - release file
;                            dir_close_memory - release memory
;                            dir_close - release file and memory
;
;<
;  * ----------------------------------------------

  global dir_open
dir_open:
  cld
  mov	[bss_ptr],eax
  add	eax,dir_block_struc_size;move past block at start
  mov	[file_ptr],eax		;save buffer start point
  call	dir_read_grow
  or	eax,eax
  js	do_exit			;jmp if allocaton  error
;build dir_block at top of memory
;     struc dir_block
;      .handle			;set by dir_open
;      .allocation_end		;end of allocated memory
;      .dir_start_ptr		;ptr to start of dir records
;      .dir_end_ptr		;ptr to end of dir records
;      .index_ptr		;set by dir_index
;      .record_count		;set by dir_index
;      .work_buf_ptr		;set by dir_sort
;      dir_block_struc_size
  mov	edi,[bss_ptr]
;  xor	eax,eax			;set handle to zero
  stosd
  mov	eax,ecx			;[file_end]
  add	eax,16			;add in pad
  stosd				;store allocation end
  mov	eax,[file_ptr]	
  stosd				;store file start
  mov	eax,ecx			;[file_end]
  add	eax,16
  stosd				;store file end
  mov	eax,[bss_ptr]		;get ptr to dir block
do_exit:
  ret
;------------
  [section .data]

bss_ptr	dd	0
file_ptr dd	0
  [section .text]
