
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
  extern dword_to_ascii
  extern str_move
  extern lib_buf
  extern file_simple_read

;****f* process/check_process *
; NAME
;>1 process
;  check_process - get process status from /proc
; INPUTS
;    ebx = pid (process id)
; OUTPUT
;    al = "U" unknown pid
;    al = "S" sleeping
;    al = "R" running
;    al = "T" stopped
;    al = "Z" zombie
;    al = "D" uninterruptable wait
; NOTES
;    source file: check_process.asm
;<
;  * ----------------------------------------------
;*******
  global check_process
check_process:
  cld
  mov	eax,37
  mov	ecx,0		;status check only
  int	80h
  or	eax,eax
  mov	al,'U'		;unknown pid
  js	cp_exit

  mov	eax,ebx
  mov	edi,destination
  call	dword_to_ascii
  mov	al,'/'
  stosb
  mov	esi,pstatus
  call	str_move

  mov	ebx,proc_entry
  mov	ecx,lib_buf
  mov	edx,200		;buf size
  call	file_simple_read
  mov	eax,'ate:'
  mov	edx,40		;search length
keep_looking:
  cmp	dword [ecx],eax
  je	got_it
  inc	ecx
  dec	edx
  jnz	keep_looking
  mov	al,'D'		;force dead status
  jmp	cp_exit
got_it:  
  mov	al,byte [ecx + 5]
cp_exit:
  ret
;--------------
  [section .data]
fd:	dd	0
proc_entry: db '/proc/'
destination: db 0,0,0,0,0,0,0,0,0,0
pstatus db 'status',0
