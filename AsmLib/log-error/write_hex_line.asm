
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
  extern write_hex_byte_stdout
  extern write_char_to_file

;---------------------
;>1 log-error
;  write_hex_line_stdout - dump hex line to stdout
; INPUTS
;    ecx = dump length
;    esi = ptr to binary data
; OUTPUT:
; NOTES
;   source file: write_hex_line.asm
;<
; * ----------------------------------------------
;--------------------
;---------------------
;>1 log-error
;  write_hex_line_to_file - dump hex line to file
; INPUTS
;    ebx = open file fd
;    ecx = dump length
;    esi = ptr to binary data
; OUTPUT:
; NOTES
;   source file: write_hex_line.asm
;<
; * ----------------------------------------------
;--------------------
; inputs: esi=ptr to dump data
;         ecx=remaining bytes to dump
  global write_hex_line_stdout
  global write_hex_line_to_file
write_hex_line_stdout:
  mov	ebx,1
write_hex_line_to_file:
  mov	[dump_fd],ebx
  push ecx
  push esi
  push esi
;write a max of 16 bytes
  cmp	ecx,16
  jbe	dhl_04		;jmp if less than 16
  mov	ecx,16
dhl_04:
  push	ecx
dhl_lp1:
  lodsb			;get binary byte
  call write_hex_byte_stdout ;display as hex
  dec ecx		;
  jnz dhl_lp1		;jmp if more data to dump
;now add ascii on right
  pop	ecx		;restore line length
  cmp	ecx,16
  je	dhl_08		;jmp if full line
;compute space over lenght
  push  ecx
  sub	ecx,16
  neg	ecx
  lea	ecx,[ecx+ecx *2] ;multiply by 3
dhl_lps:
  mov	al,' '
  call  write_char_to_file
  dec	ecx
  jnz	dhl_lps
  pop	ecx
dhl_08:
  pop esi		;restore origional data ptr
dhl_lp2:
  lodsb			;get binary byte
  cmp al, 127		;check if possible ascii
  ja dhl_10		;jmp if possible illegal ascii
  cmp al, 20h		;check if possible ascii
  jae dhl_20 		;jmp if not safe to display
dhl_10:
  mov al, '.'		;get substitute display char
dhl_20:
  call write_char_to_file
  dec	ecx
;  sub ecx, byte 1
  jnz dhl_lp2
  mov al,0ah		;get line feed char
  call write_char_to_file
  pop esi
  pop ecx
dump_90:
  ret
;-------------------------
  [section .data]
dump_fd: dd	0
  [section .text]