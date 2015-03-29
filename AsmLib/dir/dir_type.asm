
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
;%difine LIBRARY

  [section .text]  
;  extern sort_merge
  extern dir_status

%ifdef DEBUG

  extern dir_open_indexed
  extern dir_close

 global _start
 global main
_start:
main:    ;080487B4
  cld
  mov	eax,bss_end
  mov	ebx,pathx
  call	dir_open_indexed
  call	dir_type
  call	dir_close
  mov	eax,1
  int	80h

pathx: db '/usr/share/doc/',0

  [section .bss]
bss_end:
  [section .text]
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

%endif

; structure describing a directory entry
struc dtype
.d_size	resd 1	;byte size for fstat .st_size
.d_mode	resw 1	;type information from fstat .st_mode 
.d_uid  resw 1  ;owner code
.d_len   resb 1  ;length byte from dent structure
.d_type  resb 1  ;type code 1=dir 2=symlink 3=file
.d_nam resb 1	;directory name (variable length)
endstruc


;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;>1 dir
;  dir_type - Add type information to indexed directory
;     dir_type is called by dir_sort_by_name and dir_sort_by_type.
;     Normally it is not called as a standalone function.
;  INPUTS
;     esi = ptr to path of this directory (ends with '/')
;     eax = ptr to open dir_block
;
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
;     Note: dir_type is usually called after dir_index
;           or dir_open_indexed
;
;  OUTPUT     eax = negative if error, else it contains
;                   a ptr to the dir_block
;     The index now points to a directory entries with
;     the following structure:
;
;     struc dtype
;      .d_size	resd 1	;byte size for fstat .st_size
;      .d_mode	resw 1	;type information from fstat .st_mode 
;      .d_uid   resw 1  ;owner code
;      .d_len   resb 1  ;length byte from dent structure
;      .d_type  resb 1  ;type code 1=dir 2=symlink 3=file
;      .d_nam resb 1	;directory name (variable length)
;     endstruc
;
;  NOTE
;     source file is dir_type.asm
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
;store file codes in dirent's, put codes infront of file name.
; 3=regular file
; 2=symlink
; 1=dir

  global dir_type
dir_type:
  push	eax
  mov	[our_path],esi
  mov	ebp,[eax + dir_block.index_ptr]	;sort_pointers
gt_loop1:
  mov	edi,[ebp]
  or	edi,edi
  jz	gt_done		;jmp if empty directory
  add	edi,10			;move to filename
  mov	esi,[our_path]
  call	build_path

  mov	ebx,[our_path]		;default_path
  call	dir_status

  or	eax,eax
  js	gt_err			;jmp if file not found
;
; decode file type
;
  mov	ax,0f000h
  and	ax,[ecx+stat_struc.st_mode]
  mov	al,3
  cmp	ah,80h
  je	gt_store		;jmp if regular file
  mov	al,2
  cmp	ah,0a0h
  je	gt_store		;jmp if sym link
  mov	al,1			;assume it is directory
gt_store:
  mov	ebx,[ebp]		;get pointer to name
  mov	[ebx+9],al		;store code
;store st_size from fstat -> d_size
  mov	eax,[ecx+stat_struc.st_size]
  mov	[ebx + dtype.d_size],eax
;store st_mode from fstat -> d_type
  mov	ax,[ecx+stat_struc.st_mode]
  mov	[ebx + dtype.d_mode],ax
;store st_uid for fstat -> d_uid
  mov	ax,[ecx+stat_struc.st_uid]
  mov	[ebx + dtype.d_uid],ax
;move to next index 
  add	ebp,4
  jmp	short gt_loop1
;  dec	dword [loop_count]
;  jnz	gt_loop1
gt_err:

gt_done:
  pop	eax
  ret
;
;-----------------------------------------------------------------
; build path for execution or open
;  input: edi = filename
;         esi = path base ending with '/'
;
build_path:
  lodsb
  cmp	al,0
  jne	build_path	;loop till end of path
  dec	esi
bp_lp1:
  cmp	byte [esi],'/'
  je	bp_append
  dec	esi
  jmp	short bp_lp1	;scan back till '/' found
bp_append:
  xchg	esi,edi
  inc	edi		;move past '/'
bp_lp2:
  lodsb
  stosb
  cmp	al,0
  jne	bp_lp2		;loop till name appended
  ret

  [section .data]
our_path	dd	0
  [section .text]
