
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
  extern lib_buf

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


;****f* file/dir_read *
; NAME
;>1 dir
;  dir_read - open, read, close a directory structure
; INPUTS
;     ebx = directory path
;     edi = buffer to hold directory info
;     ecx = size of buffer 
; OUTPUT
;    eax = negative error# if problems, -1 = buffer too small
;        = size of read if eax is positive
;    ebx = dir size if eax=-1
; NOTES
;   source file: file_dir.asm
;   kernel open(5) getdents(141) close(6)
;<
; * ----------------------------------------------
;*******
;---------------------------------------------------------------
; read directory at default_path
;
  global dir_read
dir_read:
  mov	[dr_buf_size],ecx
  mov	[dr_buf],edi
  cld
  mov	al,0
  rep	stosb

  mov	eax,5			;open
;the following instruction may not be needed?  The code works
;even if ecx = 200000h and other  values.  Possibly it is needed
;if we create a directory.  Anyway, the code appears in some
;traces of "c" programs, so we will leave it in.
  mov	ecx,200000q		;directory
  int	80h

  or	eax,eax
  js	dr_exit1		;exit if error

  mov	ebx,eax
  mov	[dr_fd],ebx
  mov	eax,108
  mov	ecx,lib_buf + 200	;use lib_buf for fstat buffer
  int	80h
  or	eax,eax
  js	dr_exit2		;jmp if file does not exist

  mov	eax,-1			;preload error
  mov	ebx,[lib_buf + 200 + stat_struc.st_size]
  cmp	ebx,[dr_buf_size]
  ja	dr_exit2		;exit if buffer too small

  mov	edx,[dr_buf_size]	;get buffer size
  mov	ecx,[dr_buf]		;get buffer
dr_rd_lp:
  mov	ebx,[dr_fd]		;restore fd
  mov	eax,141
  int	80h			;read
  or	eax,eax
  js	dr_cont			;jmp if error
  jz	dr_got_all		;jmp if everything read
  add	ecx,eax			;move buffe ptr fwd
  sub	edx,eax			;adjust size of buffer
  jmp	short dr_rd_lp
dr_got_all:
;stuff some zeros at end of directory data.  This appears
;to be the best way to terminate loops processing the
;directory data.
dr_exit2:
;  xor	eax,eax			;zero eax
;  mov	[ecx],eax		;store 0 to inode field
;  mov	[ecx+4],eax		;store 0 to offset field
;  mov	[ecx+8],eax		;store 0 to size +
;compute length of read
  sub	ecx,[dr_buf]		;compute size of read
  mov	eax,ecx
dr_cont:
  push	eax			;save size of read/error
  mov	ebx,[dr_fd]
  mov	eax,6
  int	80h			;close
  pop	eax
dr_exit1:
dr_exit:
  or	eax,eax
  ret
  
  [section .data]
dr_fd:		dd	0
dr_buf_size	dd	0
dr_buf		dd	0
  [section .text]
