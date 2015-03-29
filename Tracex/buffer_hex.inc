
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
;  buffer_hex - dump hex line to buffer
; INPUTS
;    ecx = dump length (reduced by 16 each call)
;    esi = ptr to binary data 
;    edi = output buffer ptr
; OUTPUT:
;    edi = advanced to 0ah at end of buffer
;    esi = advanced by 16
;    ecx = decreased by 16
;    flags = state after ecx decremented by 16
; NOTES
;   source file: buffer_hex.asm
;<
; * ----------------------------------------------
;--------------------
; inputs: esi=ptr to dump data
;         ecx=remaining bytes to dump
  global buffer_hex
buffer_hex:
  jecxz dhl_exit	;exit if data length=0
  push ecx
  push esi
;write a max of 16 bytes
  cmp	ecx,16
  jbe	dhl_10		;jmp if less than 16
  mov	ecx,16
dhl_10:
  mov	[dhl_count],ecx
dhl_lp1:
  lodsb			;get binary byte
  call	byteto_hexascii	;buffer hex
  mov	al,' '
  stosb
  dec ecx		;
  jnz dhl_lp1		;jmp if more data to dump
;space over to ascii column
  mov	ecx,[dhl_count]
dhl_20:
  cmp	ecx,16
  je	dhl_30		;jmp if at correct column
  stosb
  stosb
  stosb
  inc	ecx
  jmp	short dhl_20
dhl_30:
  pop esi
;setup to add ascii
  push	esi
  stosb
  stosb			;space over for ascii

  mov	ecx,[dhl_count]
dhl_lp2:
  lodsb			;get binary byte
  cmp al, 127		;check if possible ascii
  ja dhl_40		;jmp if possible illegal ascii
  cmp al, 20h		;check if possible ascii
  jae dhl_50 		;jmp if not safe to display
dhl_40:
  mov al, '.'		;get substitute display char
dhl_50:
  stosb
  dec	ecx
  jnz dhl_lp2
dhl_skip:

  mov al,0ah		;get line feed char
  stosb		;buffer hex
  pop	esi
  pop	ecx
  add esi,[dhl_count]
  sub ecx,[dhl_count]
dhl_exit:
  ret
;-------------------------
  [section .data]
dhl_count:	dd 0
  [section .text]

