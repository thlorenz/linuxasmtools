
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


;add the line "[section .text align=1]" to every source (*.asm) file
;in current directory
;
  [section .text align=1]


  extern dir_walk
  extern dir_current
  extern str_move
  extern memory_init
  extern block_read_all
  extern block_write_all

 global _start
_start:
  call	dir_current
  mov	esi,ebx		;get ptr to path
  mov	edi,our_path
  call	str_move
;setup to walk path
  call	memory_init   ;set eax to buffer location

  mov	esi,our_path
  mov	ebx,file_mask
  mov	ch,2		;return masked files
  mov	cl,3		;depth
  mov	edx,file_process
  call	dir_walk
    
  mov	eax,1
  int	80h

;---------------------------------------------
;input: eax=ptr to path
;       ecx=ptr to filename at end of path
;output: eax=0 says continue
file_process:
  push	eax
  mov	ebx,eax		;path to ecx
  mov	ecx,file_buffer
  mov	edx,file_buffer_size
  call	block_read_all

  mov	esi,eax		;save size of file
  add	esi,append_size
  pop	ebx		;get filename
  xor	edx,edx		;default write premissions
  mov	ecx,out_buffer
  call	block_write_all
  xor	eax,eax
  ret
	    
;------------------
  section .data

file_mask: db '*asm',0

our_path: times 100 db 0

out_buffer:
  db 0ah,'  [section .text align=1]',0ah
append_size equ $ - out_buffer
file_buffer_size equ 200000
file_buffer:
  times file_buffer_size db 0

;----------------------
  section .bss
