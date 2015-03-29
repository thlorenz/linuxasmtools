
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
;  block_seek - seek to location in file
; INPUTS
;    ebx = file handle (identifier)
;    ecx = if positive seek point (byte location within file)
;          if negative seek forward from current pos ~ecx
;           
; OUTPUT
;    eax = negative if error (error number)
;    eax = positive file handle if success
;          flags are set for js jns jump
; NOTES
;    source file:  block_seek.asm
;    The block_seek routine is normally used with
;    block_open_update and block_open_home_update to
;    position the file pointer for reading and writing
;    records.
;<
;  * ----------------------------------------------
;*******
  global block_seek
block_seek:
  mov	eax,19		;kernel seek code
  xor	edx,edx		;preload simple seek relative start of file
  or	ecx,ecx
  jns	bs_20		;jmp if simple seek
  neg	ecx		;make seek forward count positive
  mov	edx,1		;enable seek relative to present position
bs_20:
  int	80h
  ret
