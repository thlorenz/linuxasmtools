
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
  extern dword_to_ascii
;---------------------------------------------------
;>1 process
;  get_proc_info - extract info from kernel /proc/./stat
; INPUTS
;    eax = pid of process to get status entry from
;    ebx = index to item (see below and "man proc")
;          if index is positive eax=ptr to ascii string
;          if index is negative eax= bin value of item
;    some common indexs are:
;          0-pid              7-tpgid
;          1-process name    17-priority 
;          2-state           27-stack
;          3-ppid            28-current esp
;          4-group           29-current eip
;          5-session         31-blocked signals
;          6-tty             32-ignored signals
;                            33-caught signals
;                            37-exit signal
; OUTPUT
;    eax = return status, negative if error
;    ebx = ptr to string (terminated by space) or
;          binary value of item requested.
;    [lib_buf] contains /stat dir until next lib
;          call.  See "man proc" for format.
;    possible error is: bad pid
; NOTES
;    source file: get_proc_info.asm
;<

  extern str_move
  extern file_simple_read
  extern ascii_to_dword
  [section .text]
;
  global get_proc_info
get_proc_info:
  push	eax
  mov	[proc_item],ebx
  mov	edi,lib_buf+400
  mov	esi,proc_pre
  call	str_move
  pop	eax
  call	dword_to_ascii
  mov	esi,proc_post
  call	str_move
  mov	ebx,lib_buf+400		;file name
  mov	ecx,lib_buf		;buffer
  mov	edx,600			;buffer size
  call	file_simple_read
  js	gpi_exit		;exit if error
  mov	byte [lib_buf+eax],' '	;put space at end
;find entry of interest
  mov	esi,lib_buf		;search start ptr
  mov	ecx,[proc_item]
  or	ecx,ecx
  jns	gpi_10			;jmp if positive
  neg	ecx
gpi_10:
  jecxz	gpi_50			;jmp if item found
  lodsb
  cmp	al,' '
  ja	gpi_10			;loop if inside item
;separator at end of item found
gpi_20:
  lodsb				;get next
  cmp	al,' '
  jbe	gpi_20			;loop if another separator
  dec	esi			;move back to start of item
  dec	ecx			;dec item count
  jmp	short gpi_10		;loop back
;item found, check if binary wanted, esi=ptr to string
gpi_50:
  mov	ecx,[proc_item]		;get item#
  or	ecx,ecx
  jns	gpi_70			;jmp if string wanted 
;convert string to number
  call	ascii_to_dword
  mov	ebx,ecx
  jmp	short gpi_80
gpi_70:
  mov	ebx,esi
gpi_80:
  xor	eax,eax
gpi_exit:
  ret
;--------------------
  [section .data]
proc_item:	dd	0	;item number, negative=return binary
proc_pre:	db	'/proc/',0
proc_post:	db	'/stat',0
  [section .text]
