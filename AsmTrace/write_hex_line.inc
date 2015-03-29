  extern byteto_hexascii
  extern trace_peek_bytes

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


;--------------------
;---------------------
;>1 log-error
;  write_hex_line_to_file - dump hex line to file
; INPUTS
;    ecx = dump length
;    esi = ptr to binary data
;    edi = buffer ptr
; OUTPUT:
; NOTES
;<
; * ----------------------------------------------
;--------------------
buffer_hex_line:
  or	esi,esi
  jz	dump_90			;exit if null ptr
  push esi
  mov	eax,esi
  call	dwordto_hexascii	;put address first
  mov	al,'='
  stosb
;write a max of 16 bytes
  cmp	ecx,16
  jbe	dhl_04		;jmp if less than 16
  mov	ecx,16
dhl_04:
  push	ecx
dhl_lp1:
  mov	ebx,esi
  call	get_app_data
  inc	esi
;  lodsb			;get binary byte
  call	byteto_hexascii
  mov	al,' '
  stosb
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
  stosb
  dec	ecx
  jnz	dhl_lps
  pop	ecx
dhl_08:
  pop esi		;restore origional data ptr
dhl_lp2:
  mov	ebx,esi
  call	get_app_data
  inc	esi
;  lodsb			;get binary byte
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
dump_90:
  ret
;-------------------------
;esi = ptr to asciiz data
;edi = stuff point
buffer_ahex_line:
  push esi
  mov	eax,esi
  call	dwordto_hexascii	;put address first
  mov	al,'='
  stosb
;read data into buffer
  pop	edx			;restore address
  call	get_app_bytes
  or	eax,eax
  js	bal_done		;exit if error
;stuff a max of 15 bytes
  mov	ecx,15
  mov	esi,app_bytes
bal_lp:
  lodsb
  or	al,al
  jz	bal_done
  stosb
  loop	bal_lp
bal_done:
  ret


;-------------------------------------
;input: edx=app address
get_app_bytes:
  pusha
  mov	esi,app_bytes
  mov	edi,15 
  call	trace_peek_bytes
  mov	[return_status],eax
  popa
  mov	eax,[return_status]
  ret



  
  [section .data]
app_bytes: times 16 db 0
return_status	dd 0
  [section .text]
