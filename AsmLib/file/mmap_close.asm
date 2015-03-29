
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
;****f* file/mmap_close *
; NAME
;>1 file
;   mmap_close - close memory mapped file and release memory
; INPUTS
;    eax = mmap fd (file descriptor)
;    ebx = ptr to file data
; OUTPUT
;    eax - pointer to file contents
;    (sign bit set if error)
;    ebx and ecx are destroyed
; NOTES
;   source file: mmap_close.asm
;   see mmap_open_rw.asm and mmap_open_ro for opening files
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
  global mmap_close
mmap_close:
;release memory block
  push	eax		;save fd
  mov	eax,91
; ebx = start address of file data
  int	80h
;
  pop	ebx		;get fd
  mov	eax,6		;close
  int	80h
mrc_exit:
  or	eax,eax
  ret

;----------------
  [section .text]
