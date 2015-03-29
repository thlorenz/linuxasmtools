
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
  extern block_open_write
  extern block_open_home_write
  extern block_write
  extern block_close

  [section .text]

;>1 file2
;  block_write_all - write file and close it
; INPUTS
;    ebx = pointer to file name
;          filename can be full path if first character is '/'
;          filename can be local if first char. is non '/' alpha
;    edx = file permissions or zero to use default 
;    ecx = buffer pointer
;    esi = buffer size
; OUTPUT
;    eax = negative if error (error number)
;    eax = positive number of bytes read
;          flags are set for js jns jump.
; NOTES
;    source file:  block_write_all.asm
;<
;  * ----------------------------------------------
;*******
  global block_write_all
block_write_all:
  push	ecx
  push	esi
  call	block_open_write
  pop	edx			;restore buffer size
  pop	ecx			;restore buffer pointer
  js	bra_exit		;jmp if error
  call	block_write
  js	bra_exit		;exit if write failled
  push	eax
  mov	eax,118			;fsync
  int	byte 80h		;filehandle in ebx
  call	block_close
  pop	eax
  cmp	eax,edx			;check if all bytes written
  jne	bra_exit		;jmp if write failed to write all
  or	eax,eax
bra_exit:  
  ret
