
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

;>1 file2
;  block_close - close file
; INPUTS
;    ebx = file handle (identifier)
; 
; OUTPUT
;    eax = negative if error (error number)
;    eax = positive file handle if success
;          flags are set for js jns jump
; NOTES
;    source file:  block_close.asm
;    The block_close function releases files
;    and is part of the normal file hanling
;    sequence of:  block_open...
;                  block_read...
;                  block_write...
;                  block_close
;<
;  * ----------------------------------------------
;*******
  global block_close
block_close:
  mov	eax,6
  int	80h
  or	eax,eax
  ret
