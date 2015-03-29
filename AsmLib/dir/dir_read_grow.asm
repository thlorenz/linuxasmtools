
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
;%define INCLUDES
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
  call	dir_read_grow
  or	eax,eax
  js	err
err:
  mov	eax,1
  int	80h


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
%endif

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -( SEARCH  )
;>1 dir
;  dir_read_grow - allocate memory and read directory
;  INPUTS
;     eax = end of .bss section memory
;           Used to allocate memory.  This section
;           must be at end of program.
;     ebx = directory path
;
;     calling example:
;           mov  eax,last_bss
;           mov	 ebx,dir_path
;           call dir_read_grow
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
;                   length of read.
;             if eax positive then 8 bytes of zeros are stuffed
;                at end of buffer and   ecx=end of data ptr
;
;  NOTE
;     source file is dir_read_grow.asm
;<
;  * ----------------------------------------------

  global dir_read_grow
dir_read_grow:
  cld
  mov	[bss_avail_ptr],eax
;open directory
  mov	eax,5			;open
;the following instruction may not be needed? Or maybe it
;should be zero?  The code works OK and appears in traces
;some "c" programs, so we will leave it in.
  mov	ecx,200000q		;directory
  int	80h
  or	eax,eax
  jns	do_status		;jmp if success
  jmp	do_exitx
do_status:
  mov	[handle],eax
;get directory information
  mov	eax,108			;dir status
  mov	ebx,[handle]
  mov	ecx,lib_buf
  int	80h
;allocate memory
  mov	ebx,[bss_avail_ptr]		;get start of allocation area
  mov	eax,[lib_buf + stat_struc.st_size]
  add	ebx,eax			;compute file end
  add	ebx,16			;add in some pad
  add	eax,16			;add in some pad
  mov	[length],eax

  mov	ecx,[bss_avail_ptr]	;get buffer
  mov	edx,eax			;get buffer size
;note: we can not always rely on the
;size from .st_size.  On knoppix the /usr/share/doc
;directory returns 12000 but the actual size is much bigger.

; ecx = buffer ptr
; edx = new buffer size
; ebx = new buffer end
dr_al_lp:
  mov	eax,45
  int	80h			;allocate memory
  or	eax,eax
  js	do_error		;jmp if allocaton  error
  
; ecx = buffer ptr
; edx = buffer size
dr_rd_lp:
  mov	ebx,[handle]		;restore fd
  mov	eax,141
  int	80h			;read
  or	eax,eax
  js	do_error		;jmp if error, zero buffer to be safe
  jz	do_exit1		;jmp if everything read
  add	ecx,eax			;move buffe ptr fwd
  sub	edx,eax			;adjust size of buffer
  cmp	edx,250
  ja	dr_rd_lp		;jmp if buffer big enough
  mov	ebx,ecx			;compute new end of memory
  add	ebx,2086
  add	edx,2086
  jmp	short dr_al_lp

do_exit1:
  mov	[file_end],ecx		;save end of read
  xor	eax,eax
  mov	[ecx],eax		;put zero at end of file
  mov	[ecx+4],eax		;put another zero at end

  mov	ebx,[handle]
  mov	eax,6			;close
  int	80h  

  mov	eax,[file_end]
  sub	eax,[bss_avail_ptr]	;compute size of read
  jmp	short do_exitx
do_error:
  push	eax			;save error code
  mov	ebx,[handle]		;close dir
  mov	eax,6
  int	80h
  pop	eax			;restore error code
do_exitx:
  ret
;----------------------------
  [section .data]

bss_avail_ptr	dd	0
handle	dd	0
length	dd	0	;file length
file_end dd	0
  [section .text]
