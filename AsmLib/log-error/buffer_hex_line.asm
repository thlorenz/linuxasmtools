
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
  extern byteto_hexascii
;---------------------
;>1 log-error
;  buffer_hex_line - dump hex line to buffer
; INPUTS
;    ecx = dump length
;    esi = ptr to binary data
;    edi = buffer ptr
;    edx = flag 0=no ascii append 1=ascii append
; OUTPUT:
; NOTES
;   source file: buffer_hex_line.asm
;<
; * ----------------------------------------------
;--------------------
; inputs: esi=ptr to dump data
;         ecx=remaining bytes to dump
  global buffer_hex_line
buffer_hex_line:
  push ecx
  push esi
  push esi
  mov	byte [ascii_append],dl
;write a max of 16 bytes
  cmp	ecx,16
  jbe	dhl_04		;jmp if less than 16
  mov	ecx,16
dhl_04:
  push	ecx
dhl_lp1:
  lodsb			;get binary byte
  call	byteto_hexascii		;buffer hex
  dec ecx		;
  jnz dhl_lp1		;jmp if more data to dump
;now add ascii on right
  pop	ecx		;restore line length
  cmp	byte [ascii_append],0
  jne	dhl_cont
  pop	esi
  jmp	short dhl_skip	;skip ascii if 0
dhl_cont:
  cmp	ecx,16
  je	dhl_08		;jmp if full line
;compute space over lenght
  push  ecx
  sub	ecx,16
  neg	ecx
  lea	ecx,[ecx+ecx *2] ;multiply by 3
dhl_lps:
  mov	al,' '
  stosb
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
  stosb
  dec	ecx
;  sub ecx, byte 1
  jnz dhl_lp2
dhl_skip:
  mov al,0ah		;get line feed char
  stosb		;buffer hex
  pop esi
  pop ecx
dump_90:
  ret
;-------------------------
  [section .data]
ascii_append: db 0
  [section .text]
