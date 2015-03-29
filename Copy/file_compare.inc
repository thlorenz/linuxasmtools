
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
  extern file_open
  extern file_close
  extern file_open
  extern file_read

buffer_size	equ	4096

;****f* file/file_compare *
;
; NAME
;>1 file
;  file_compare - copy one file
; INPUTS
;    ebx = ptr to full path for file1
;    edx = ptr to full path for file2
;    eax = 4096 byte buffer ptr
;    ecx = 4096 byte buffer ptr
; OUTPUT
;    eax = negative error code, open/read error
;          zero for success
;          positive value = miscompare
;          flags set for jz, jnz, js
; NOTES
;    source file: file_compare.asm
;<
; * ----------------------------------------------
;*******
  global file_compare
file_compare:
  mov	[buf1_ptr],eax
  mov	[buf2_ptr],ecx
  mov	[file2_path_ptr],edx
  xor	ecx,ecx			;open read only
  call	file_open
  js	cf_exit			;exit if open failure
  mov	[cf_from_handle],eax
  mov	ebx,[file2_path_ptr]	;get file2 path
  xor	ecx,ecx			;open read only
  call	file_open
  js	cf_exit			;exit if open failure
  mov	[cf_to_handle],eax
;
; read block
;
cf_loop:
  mov	ebx,[cf_from_handle]
  mov	edx,buffer_size		;buffer size
  mov	ecx,[buf1_ptr]		;buffer
  call	file_read
  js	cf_exit 		;exit if error
  mov	[last_read_size],eax	;save size
;
; read file2
;
  mov	ebx,[cf_to_handle]
  mov	edx,buffer_size		;buffer size
  mov	ecx,[buf2_ptr]		;buffer
  call	file_read
  js	cf_exit 		;exit if error
  cmp	eax,[last_read_size]	;files same size
  jne	cf_fail_exit		;jmp if miscompare
  or	eax,eax			;check if eax=0
  jz	cf_exit			;jmp if all data read
;
  mov	ecx,eax
  mov	esi,[buf1_ptr]
  mov	edi,[buf2_ptr]
  repe	cmpsb
  je	cf_loop
cf_fail_exit:
  mov	eax,1			;set fail flag
;
cf_exit:
  push	eax			;save return status
  mov	ebx,[cf_to_handle]
  call	file_close
  mov	ebx,[cf_from_handle]
  call	file_close
  pop	eax			;restore return status

  or	eax,eax
  ret

  [section .data]
buf1_ptr	dd	0
buf2_ptr	dd	0
file2_path_ptr	dd	0
cf_from_handle	dd	0
cf_to_handle	dd	0
last_read_size	dd	0
  [section .text]

