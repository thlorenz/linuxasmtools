
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

  extern byte2hexstr
  extern crt_write

;---------------------
;>1 log-error
;  write_hex_byte_stdout - display hex char
; INPUTS
;    al = binary for conversion to hex
; OUTPUT:
;    ebx = 1 for stdout
; NOTES
;   source file: write_hex.asm
;<
; * ----------------------------------------------
;---------------------
;>1 log-error
;  write_hex_byte_to_file - write hex for byte to file
; INPUTS
;    al = binary for conversion to hex char
;    ebx = open file fd
; OUTPUT:
; NOTES
;   source file: write_hex.asm
;<
; * ----------------------------------------------
;------------------------------
; input: al = char to display in hex
;
  global write_hex_byte_stdout
  global write_hex_byte_to_file
write_hex_byte_stdout:
  mov	ebx,1
write_hex_byte_to_file:
  mov	[wdump_fd],ebx	;save open fd
  push eax
  push ebx
  push ecx
  push edx
;convert to hex ascii
  mov	bl,al		;move binary to -al-
  mov	edi,sah_out	;destination for hex ascii
  call	byte2hexstr	;convert byte to hex
;display hex
  mov	ecx,sah_out
  mov	ebx,[wdump_fd]
  mov	edx,3
  call	crt_write

  pop edx
  pop ecx
  pop ebx
  pop eax
  ret
;-------------------------
  [section .data]
sah_out:	db	0,0,' '
wdump_fd:	dd	0
  [section .text]
