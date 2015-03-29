
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
;****f* file/mmap_open_ro *
; NAME
;>1 file
;  mmap_open_ro - returns a read only pointer to file data
; INPUTS
;    ebx = poiter to asciiz filename
;    ecx = optional buffer size
;          set to zero to read complete file
;    lib_buf - temporary library buffer utilized        
; OUTPUT
;    eax - read length (file length if fits in buffer)
;          if error eax will have negative error code.
;    ebx - fd (file descriptor)
;    ecx - pointer to file contents
; NOTES
;   source file: mmap_open_ro.asm
;    
;   notes: the lib_buf buffer is used to hold fstat status
;   of file.  see man fstat for format.
;    
;   The mmap functions should be used for files that
;   do not change length.  To append data or truncate
;   files the non-mmap routines are prefered.  The
;   advantage of mmap is speed and freedom from buffer
;   handling.  The mmap functions are:
;    mmap_open_rw - open for read and write
;    mmap_open_ro - open read only
;    mmap_close   - close file and felease buffer
;
;  mmap data may not be written to disk immediatly, if
;  that is desired the kernel msync function can be used.
;<
; * ----------------------------------------------
;*******

  [section .text]
;

  global  mmap_open_ro
  extern lib_buf

mmap_open_ro:
  mov	[mmap_len],ecx	;save buffer size
  xor	ecx, ecx
  mov	eax,5
  int	80h		;open file
  or	eax, eax
  js	mapfile_exit
  mov	ebx,eax		;get fd
  mov	ecx,lib_buf	;get buffer
  mov	eax,108		;fstat
  int	80h
; An mmap structure is filled out and handed off to the system call,
; and the function returns.
;sys_mmap 0,dword [ecx + 20],PROT_READ,MAP_SHARED,ebx,0

  mov	[mmap_fd],ebx		;save fd (handle)
  mov	ecx,[ecx + 20]		;get length
  push	ecx
  cmp	dword [mmap_len],0
  jne	mmap_10			;jmp if user supplied buffer size
  mov	[mmap_len],ecx
mmap_10:
  mov	ebx,mmap_parm
  mov	eax,5ah
  int	80h
  mov	ebx,[mmap_fd]		;get file handle (fd)
  pop	ecx			;restore file length
  cmp	ecx,[mmap_len]
  jb	mapfile_exit		;jmp if buffer smaller than file
  mov	ecx,[mmap_len]		;get read length
mapfile_exit:
  xchg	eax,ecx		;swap data ptr and file length
;
; eax = garbage or file length
; ecx = return code from kernel or data ptr
;
  cmp	ecx,-200
  jb	mapfile_exit2	;jmp if good data, eax=len ecx=data ptr
  mov	eax,ecx		;restore error code to eax
mapfile_exit2:
  or	eax,eax
  ret


;-----------
  [section .data]
mmap_parm:
  dd	0	;start
mmap_len:
  dd	0	;length, from stat
  dd	1	;prot (PROT_READ)
  dd	1	;flags (MAP_SHARED)
mmap_fd:
  dd	0	;fd (handle)
  dd	0	;offset
  [section .text]

