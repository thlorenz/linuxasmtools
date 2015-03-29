
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

  extern block_open_read
  extern block_open_write
  extern file_read
  extern file_write
  extern file_close

;****f* file/file_copy *
;
; NAME
;>1 file
;  file_copy - copy one file
; INPUTS
;     ax = attributes for created file
;    ebx = ptr to (from) full path with filename
;    edx = ptr to (destination) path with filename
; OUTPUT
;    eax = negative error code or success if positive
; NOTES
;    source file: file_copy.asm
;<
; * ----------------------------------------------
;*******
  global file_copy
file_copy:
  push	eax
  push	edx
;
; open (from)
;
  call	block_open_read
  pop	ebx			;restore "to" path
  pop	edx			;restore attriburs
  js	fc_exit1		;exit if error
  mov	[fc_from_handle],eax
;
; open destination
;
  call	block_open_write
  js	fc_exit1
  mov	[fc_to_handle],eax
;
; read block
;
fc_loop:
  mov	ebx,[fc_from_handle]
  mov	edx,4096		;buffer size
  mov	ecx,buffer
  call	file_read
  js	fc_exit 		;exit if error
  jz	fc_exit			;jmp if all data written
;
; write block
;
  mov	ebx,[fc_to_handle]
  mov	edx,eax			;get size of last read
  mov	ecx,buffer
  call	file_write
  jmp	short fc_loop
;
fc_exit:
  mov	ebx,[fc_to_handle]
  call	file_close
fc_exit2:
  mov	ebx,[fc_from_handle]
  call	file_close
fc_exit1:
  ret

  [section .data]
fc_from_handle	dd	0
fc_to_handle	dd	0
  [section .text]

