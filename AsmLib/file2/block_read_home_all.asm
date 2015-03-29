
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
;  block_read_home_all - read file and close it
; INPUTS
;    ebx = pointer to file name
;    ecx = buffer pointer
;    edx = buffer max size
; OUTPUT
;    eax = negative if error (error number)
;    eax = positive file handle if success
;          flags are set for js jns jump
; NOTES
;    source file:  block_read_all.asm
;<
;  * ----------------------------------------------
;*******
  global block_read_home_all
block_read_home_all:
  push	ecx
  push	edx
  call	block_open_home_read
  pop	edx
  pop	ecx
  js	brha_exit
  call	block_read
  push	eax
  call	block_close
  pop	eax
  or	eax,eax
brha_exit:  
  ret
