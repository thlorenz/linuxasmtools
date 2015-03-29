%define DEBUG

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

  extern env_stack
  extern str_move
  extern read_window_size
  extern crt_rows,crt_columns
  extern block_write_all
  extern build_current_path

;  extern browse_dir
%include "browse_dir.inc"

  [section .text]  
;-----------------------------------------------------------
;>1 plugin
;  file_browse - display and traverse directories
; INPUTS
;    If file is passed as parameter it is
;    used as starting point for browse
;
;    If no parameters are supplied the current
;    directory is used as starting point for browse.

;    the following keys are recognized:
;      right arrow - move into directory
;      left arrow - go back one directory
;      up arrow - move file select bar up
;      down arrow - move file select bar down
;      pgup/pgdn - move page up or down
;      ESC - exit without selecting
;    - <enter> exit and select file
; OUTPUT
;    file /tmp/tmp.dir contains selected filename.
;    if no file selected, tmp.dir has lenght of zero. 
; NOTES
;   file: file_browse.asm
;   This file is a standalone ELF binary.
;
;   file_browse is used as a plugin by AsmEdit to pick
;   files for editing.      
;<
; * ----------------------------------------------

 global _start
_start:
  cld
  call	env_stack
;setup memory for allocation
  mov	eax,45
  xor	ebx,ebx		;request memory allocation adr
  int	byte 80h
  mov	[wrk_buf_ptr],eax
  mov	esi,wrk_buf_ptr	;get ptr to structure
  cmp	byte [crt_rows],0
  jne	dbl_20			;jmp if row data available
  call	read_window_size
dbl_20:
  mov	al,[crt_columns]
  shr	al,1
  mov	[win_clumns],al

  add	al,2
  shr	al,1
  mov	[win_loc_column],al

  xor	eax,eax
  mov	al,[crt_rows]
  sub	al,2
  mov	[win_rws],al

  mov	[win_loc_row],byte 2
  
;check if caller supplied a path
  mov	esi,esp
  lodsd				;get parameter count
  dec	eax
  jz	get_current_dir
  lodsd				;get executable addess
  lodsd
  cmp	byte [eax],'/'		;full path?
  je	full_path_entered
  mov	ebp,eax
  mov	ebx,pathx
  call	build_current_path
  jmp	do_browse

full_path_entered:
  mov	esi,eax
  mov	edi,pathx
  call	str_move
  jmp	short do_browse

get_current_dir:
  mov	ebx,pathx
  mov	ecx,129			;size of pathx
  mov	eax,183			;get cwd
  int	80h

do_browse:
  mov	esi,wrk_buf_ptr		;get struc ptr
  call	browse_dir
;if eax=0 the ebx is full path ptr
   or	eax,eax
   jz	write_path
;   cmp	eax,-1
;   je	escape
;   jmp	fail_exit
;escape:
  mov	ebx,out_file_name	;name of out file
  mov	ecx,dummy		;data to write (none)
  mov	edx,0			;file permissions
  mov	esi,0			;buffer size
  call	block_write_all
fail_exit:
  mov	eax,1
  jmp	bd_exit
write_path:
  mov	esi,ebx
end_loop:
  lodsb
  or	al,al
  jnz	end_loop		;loop till end of path
  sub	esi,ebx			;compute length in esi

  mov	ecx,ebx			;data to write -> ecx
  mov	ebx,out_file_name
  mov	edx,0
  call	block_write_all
  xor	eax,eax			;set success status
bd_exit:
  mov	ebx,eax
  mov	eax,1
  int	80h

  [section .data]

out_file_name	db	'/tmp/tmp.dir',0
dummy:	db	0
;
; input data block from caller
;
wrk_buf_ptr:        dd 0	;pointer to .bss area for allocation
dirclr             dd 31003734h	;color of directories in list
linkclr            dd 30003634h       ;color of symlinks in list
selectclr          dd 30003436h       ;color of select bar
fileclr            dd 30003734h	;normal window color, and list color
win_loc_row     db 1       ;top row number for window
win_loc_column  db 1	;top left column number
win_rws:            db 0	;number of rows in our window
win_clumns:         db 0	;number of columns
box_flg	     db 1	;0=no box 1=box
start_path_ptr    dd pathx	;path to start browsing
execlr           dd 30003234h ;green
devclr           dd 30003334h ;red
miscclr          dd 30003034h ;black
input_struc_size equ $ - wrk_buf_ptr

pathx times 200 db 0
;



 [section .text]

%ifndef DEBUG
struc dir_block
.handle			resd 1 ;set by dir_open
.allocation_end		resd 1 ;end of allocated memory
.dir_start_ptr		resd 1 ;ptr to start of dir records
.dir_end_ptr		resd 1 ;ptr to end of dir records
.index_ptr		resd 1 ;set by dir_index
.record_count		resd 1 ;set by dir_index
.work_buf_ptr		resd 1 ;set by dir_sort
dir_block_struc_size
endstruc
%endif

; structure describing a directory entry (dirent) on disk
struc dents
.d_ino	resd 1	;inode number
.d_off	resd 1	;offset to next dirent from top of file
.d_reclen resw 1;length of this dirent
.d_name resb 1	;directory name (variable length)
endstruc

;*********************************************************************
  [section .bss align=4]
;bss_start:	resb	0
; note dir_open puts dir_block struc 
;_handle			resd 1 ;set by dir_open
;_allocation_end		resd 1 ;end of allocated memory
;_dir_start_ptr		resd 1 ;ptr to start of dir records
;_dir_end_ptr		resd 1 ;ptr to end of dir records
;_index_ptr		resd 1 ;set by dir_index
;_record_count		resd 1 ;set by dir_index
;_work_buf_ptr		resd 1 ;set by dir_sort

