
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

  extern write_hex_line_stdout
  extern write_hex_line_to_file
;---------------------
;>1 log-error
;  hex_dump_file - dump hex to file
; INPUTS
;    ecx = dump length
;    ebx = open file descriptor (fd)
;    esi = ptr to binary data
; OUTPUT:
; NOTES
;   source file: hex_dump.asm
;<
; * ----------------------------------------------
  global hex_dump_file
hex_dump_file:
  push	eax
  or	ecx,ecx
  js	dump_done	;exit if error
hdf_lp:
  call write_hex_line_to_file    
  add	esi,byte 16
  sub	ecx,byte 16
  jz	dump_done
  jns	hdf_lp
dump_done:
  pop	eax
  ret
;---------------------
;>1 log-error
;  hex_dump_stdout - dump hex to stdout
; INPUTS
;    ecx = dump length
;    esi = ptr to binary data
; OUTPUT:
; NOTES
;   source file: hex_dump.asm
;<
; * ----------------------------------------------
;----------------------
; input: ecx=dump length if +
  global hex_dump_stdout
hex_dump_stdout:
  mov	ebx,1		;stdout
  push	eax
  or	ecx,ecx
  js	dump_done	;exit if error
hds_lp:
  call write_hex_line_stdout
  add	esi,byte 16
  sub	ecx,byte 16
  jz	dmp_done
  jns	hds_lp
dmp_done:
  pop	eax
  ret
;-------------------------
;---------------------------
