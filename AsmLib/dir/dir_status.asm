
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



  [section .text]

;****f* file/dir_status *
;
; NAME
;>1 dir
;  dir_status - check if directory exists
; INPUTS
;     ebx = path for directory
; OUTPUT
;    eax = negative error if problems, js,jns flags
;          set for conditonal jump
;    ecx = fstat buffer ptr if success
;          (see lstat kernel call)
; NOTES
;   source file: file_dir.asm
;   kernel: lstat (107)
;   temp buffer lib_buf is used.
;<
; * ----------------------------------------------
;*******
  global dir_status
dir_status:
  mov	eax,107
  mov	ecx,lib_buf
  int	80h
  or	eax,eax
  ret
