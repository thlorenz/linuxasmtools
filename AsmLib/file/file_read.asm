
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
  extern build_homepath,build_current_path
  extern file_open_rd,file_close
  extern blk_make_hole
  extern file_read

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
;****f* file/build_file_open *
; NAME
;>1 file
;  build_file_open - build path and open file
; INPUTS
;    ebp = ptr to file name
;    ebx = ptr to enviornment pointers if bit 2 of al set
;    al  = flags 
;           bit 1 (0000 0001) = full path or local file
;           bit 2 (0000 0010) = full path or file at $HOME/[base]
;           (this register optional if full path is provided)
;           (it is ok to set both bits, local path checked first)
; OUTPUT
;    eax contains a negative error code or file handle
;        flags set for js/jns jmp
;    edx = file permissions if eax positive
; NOTES
;   source file:  file_read.asm
;<
; * ----------------------------------------------
;*******
 global build_file_open
build_file_open:
  mov	[fflag],al		;save flags
  mov	[env_ptrs],ebx	;save enviornment

  cmp	byte [ebp],'/'		;check if full path provided
  je	ofx_20			; jmp if full path
  test	al,01h			;check if file in current dir
  jz	ofx_10			; jmp if file in current dir
;
; file is local (current dir) , ask kernel for our location.
;
ofx_05:
  mov	ebx,lib_buf
  call	build_current_path	;ebx=buffer, ebp=append str
  js	ofx_exit		;jmp if error
;
; check if file exists in local directory
;
  call	file_open_rd		;in: ebx=filename ptr
  jns	ofx_exit		;jmp if file found
;
; file is not local, check if $HOME/[base] bit set
;
  test	byte [fflag],2
  jz	ofx_exit		;jmp if $HOME bit not set
;
; check for file at $HOME
;
ofx_10:
  mov	ebx,[env_ptrs]
  mov	edi,lib_buf
  call	build_homepath		;ebx=env ptr, edi=buffer, ebp = append str
  js	ofx_exit		;jmp if error
  mov	ebp,lib_buf
;
ofx_20:
  mov	ebx,ebp		;move filename ptr to ecx for open
;
; ebx now points to full path of file
;
ofx_22:
  call	file_open_rd		;in: ebx=filename ptr
ofx_exit:
  or	eax,eax
  ret

;****f* file/file_read_all *
;
; NAME
;>1 file
;  file_read_all - open,read entire file,close
; INPUTS
;    ebp = ptr to file name
;    edx = buffer size
;    ecx = buffer ptr
;    ebx = ptr to enviornment pointers if bit 2 of al set
;    al  = flags 
;           bit 1 (0000 0001) = full path or local file
;           bit 2 (0000 0010) = full path or file at $HOME/[base]
;           (this register optional if full path is provided)
;           (it is ok to set both bits, local path checked first)
; OUTPUT
;    eax = negative error (sign bit set for js,jns jump)
;          buffer too small returns error code -2
;    ebp = file permissions if eax positive
;    eax= lenght of read
;    ecx= buffer pointer if eax positive
;    edx= reported file size (save as read)
; NOTES
;   source file: file_read.asm
;   If file does not fit into buffer provided an error is
;   returned.
;<
; * ----------------------------------------------
;*******
  global file_read_all
file_read_all:
  mov	[file_end],edx		;either size or end ptr for file
  mov	[buffer_ptr],ecx	;save buffer
  call	build_file_open
  js	fra_exit		;jmp if open failed
;
; we have found the file and opened it.  The file descriptor is in eax
;                                        Permissions are in edx
;;  mov	[file_permissions],edx
;;  mov	[file_handle],eax	;save file handle
  mov	ebx,eax			;move handle to ebx
  mov	edx,[lib_buf + 200 + stat_struc.st_size]
;
; compute buffer size needed to read file
;
  cmp	edx,[file_end]		;compare file size to buffer size
  mov	eax,-2			;preload error code, buffer too small
  ja	fra_exit 		;jmp if buffer too small
;
; read file, ebx=handle, edx=buffer size, ecx=buffer ptr
;
  mov	ecx,[buffer_ptr]	;buffer
  call	file_read
  js	fra_exit		;jmp if error
;
; get file attributes
;
  mov	ebp,[lib_buf + 200 + stat_struc.st_mode]
  and	ebp,777q
;
; eax = exit code   ebx = file descriptor
;  
fra_close_file:
  push	eax
  call	file_close
  pop	eax
fra_exit:
  or	eax,eax
  ret  

;****f* file/file_read_grow *
;
; NAME
;>1 file
;  file_read_grow - open and read entire file, expand buffer if necessary
; INPUTS
;    ebx = ptr to enviornment pointers if bit 2 of al set
;    ebp = ptr to file name
;    ecx = ptr to buffer
;    edi = ptr to segment end (needed for expand kernel call)
;    edx = ptr to end of current file
;    al  = flags  (0000 0000) = full path provided
;           bit 1 (0000 0001) = full path or local file
;           bit 2 (0000 0010) = full path or file at $HOME/[base]
;           bit 5 (0001 0000) = insert file
; OUTPUT
;    eax = either negative error or positive file length
;    ebp = file permissions if eax positive
;    ecx = buffer pointer for read
; NOTES
;    source file: file_read.asm
;<
; * ----------------------------------------------
;*******

  global file_read_grow
file_read_grow:
  mov	[seg_end],edi
  mov	[buffer_ptr],ecx
  call	build_file_open
  js	fr_exitx
;
; we have found the file and opened it.  The file descriptor is in eax
; compute file end ptr
;
  mov	[file_handle],eax	;save file handle
  mov	ebx,[buffer_ptr]
  test	byte [fflag],10h	;is this an insert
  jz	fr_20			;jmp if not insert
  mov	ebx,[file_end]		;
fr_20:
  add	ebx,[lib_buf + 200 + stat_struc.st_size]
  cmp	ebx,[seg_end]		;is buffer big enough?
  jb	fr_40			;jmp if buffer ok  
;
; we need a bigger buffer, try to expand buffer
;
  mov	eax,45			;extend segment to address in ebx
  int	80h			;  call SysBrk
  or	eax,eax
fr_exitx:
  js	fr_exit			;jmp if error
  mov	[seg_end],ebx
;
; we have room in buffer, now check if insert or normal read
;
fr_40:
  test	byte [fflag],10h	;check if insert
  jz	fr_read			; jmp if not insert
  mov	eax,[file_len]		;get file lenght
  mov	edi,[buffer_ptr]	;get insert point for data
  call blk_make_hole

fr_read:
  mov	ebx,[file_handle]	;open file handle
  mov	ecx,[buffer_ptr]	;buffer
  mov	edx,[lib_buf + 200 + stat_struc.st_size] ;lenght of read
  call	file_read		;go read file
;
; get file attributes
;
 
  mov	ebp,[lib_buf + 200 + stat_struc.st_mode]
  and	ebp,777q
;
; eax = exit code   ebx = file descriptor
;  
fr_close_file:
  push	eax
  mov	eax,6
  int	80h		;close file
  pop	eax
fr_exit:
  or	eax,eax
  ret  


;---------
 [section .data]
buffer_ptr	dd	0	;callers buf ptr
fflag		db	0	;callers flags
file_end	dd	0	;end of data in buffer or file size
seg_end		dd	0	;end of buffer
;;file_permissions resd	1	;file permissions

env_ptrs	dd	0
file_handle	dd	0
file_len	dd	0
 [section .text]
