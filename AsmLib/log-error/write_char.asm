
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

  extern crt_write
;---------------------
;>1 log-error
;  write_char_to_stdout - display ascii char
; INPUTS
;    al = ascii char
; OUTPUT:
;    ebx set to 1 for stdout
; NOTES
;   source file: write_char.asm
;<
; * ----------------------------------------------
;---------------------
;>1 log-error
;  write_char_to_file - write byte to open fd
; INPUTS
;    al = byte to write
;    ebx = open fd
; OUTPUT:
;    all registers preserved
; NOTES
;   source file: write_char.asm
;<
; * ----------------------------------------------
;----------------------
;-------------------------
; input: al = character to display
  global write_char_to_stdout
  global write_char_to_file
write_char_to_stdout:
  mov	ebx,1
write_char_to_file:
  push edx
  push ecx
  push eax
  mov ecx, esp     ; character's on the stack
  mov edx, 1       ; just one
  call	crt_write
  pop eax
  pop ecx
  pop edx
  ret
;---------------------------

