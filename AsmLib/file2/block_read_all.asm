
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
  extern block_open_home_read
  extern block_read
  extern block_close

  [section .text]

;>1 file2
;  block_read_all - read file and close it
; INPUTS
;    ebx = pointer to file name
;          filename can be full path if first character is '/'
;          filename can be local if first char. is non '/' alpha 
;    ecx = buffer pointer
;    edx = max buffer size
; OUTPUT
;    eax = negative if error (error number)
;    eax = positive number of bytes read
;          flags are set for js jns jump.
;          If buffer is too small the read count will
;          match max buffer size. no error will be given.
; NOTES
;    source file:  block_read_all.asm
;<
;  * ----------------------------------------------
;*******
  global block_read_all
block_read_all:
  push	ecx
  push	edx
  mov	[total_read],dword 0
  call	block_open_read
  pop	edx
  pop	ecx
  js	bra_exit
read_loop:
  call	block_read
  or	eax,eax
  js	bra_skip
  jz	read_done
  add	[total_read],eax
  add	ecx,eax		;advance buffer pointer
  jmp	read_loop
bra_skip:
  mov	[total_read],eax ;put error status in output
read_done:
  call	block_close
  mov	eax,[total_read]
  or	eax,eax
bra_exit:  
  ret
;------------
  [section .data]
total_read dd 0
  [section .text]
