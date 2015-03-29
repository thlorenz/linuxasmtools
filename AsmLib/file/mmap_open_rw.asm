
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
  [section .text]
;--------------------------------------------------------
;****f* file/mmap_open_rw *
; NAME
;>1 file
;   mmap_open_rw - map file into memory for read/write
; INPUTS
;    ebx = pointer to file path (asciiz filename)
;          (full path to file or local file)
;    ecx = size of memory area to allocate for file
;          (small memory usage encouraged)
; OUTPUT
;    eax - either positive length of file or
;                 negative error code
;    ebx - file descriptor (fd)
;    ecx - ptr to file contents         
; NOTES
;   source file: mmap_open_rw.asm
;   see also: mmapfile.asm for read only version
;   see mmap_close.asm for writing mmap_open_rw data out
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
;    
;<
; * ----------------------------------------------
;*******
  extern lib_buf
  global mmap_fd	;used by mmap_open_rw_close
  global mmap_open_rw
mmap_open_rw:
;  mov	[fname_ptr],ebx
  mov	[mmap_len1],ecx
  mov	eax,5
  mov	ecx,2		;open read/write
  mov	edx,666q	;permissions
  int	80h		;open file
  or	eax, eax
  js	mor_exit
  mov	[mmap_fd1],eax		;save fd (handle)
; check file size
  mov	ebx,eax		;get fd
  mov	ecx,lib_buf	;get buffer
  mov	eax,108		;fstat
  int	80h
  or	eax,eax
  js	mor_exit	;exit if error
  mov	ecx,[ecx + 20]	;get length
; An mmap structure is filled out and handed off to the system call,
; and the function returns.
;sys_mmap 0,dword [ecx + 20],PROT_READ,MAP_SHARED,ebx,0
  push	ecx			;save file size
  cmp	dword [mmap_len1],0	;did caller supply length
  jnz	mor_10			;jmp if no supplied len
  mov	[mmap_len1],ecx		;set read length
mor_10:
  mov	ebx,mmap_parm1
  mov	eax,5ah
  int	80h
  mov	ebx,[mmap_fd1]	;get fd
  pop	ecx			;restore file size
  cmp   ecx,[mmap_len1]
  jb	mor_exit		;jmp file size smaller than buffer	
  mov	ecx,[mmap_len1]	;get length of file
mor_exit:
  xchg	eax,ecx		;swap data ptr and file length
;
; eax = garbage or file length
; ecx = return code from kernel or data ptr
;
  cmp	ecx,-200
  jb	mor_exit2	;jmp if good data, eax=len ecx=data ptr
  mov	eax,ecx		;restore error code to eax
mor_exit2:
  or	eax,eax
  ret


;-----------
  [section .data]
;fname_ptr	dd	0

mmap_parm1:
  dd	0	;start - suggest memory address to allocate
mmap_len1:
  dd	0	;length, from stat
  dd	3	;prot (PROT_READ + PROT_WRITE)
  dd	1	;flags (MAP_SHARED)
mmap_fd1:
  dd	0	;fd (handle)
  dd	0	;offset into file to start reading
  [section .text]

