
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

  extern file_open
  extern file_write
  extern file_close
  extern dword_to_ascii
;  extern dword_to_l_ascii
  extern strlen1
  extern dword_to_hexascii

  [section .text]
  
;---------------------------------------------------------
;  log_open - open file named "log" in local driectory
; INPUTS
;  * none
; OUTPUT
;  * none (all registers restored)
;  [fd_open_flg] - global open fd for log
; NOTES
;  * source file: log.asm
;  * ----------------------------------------------

  global log_open
log_open:
  cld
  cmp	dword [fd_open_flg],0
  jne	lo_exit			;exit if log already open
  pusha
  mov	ebx,log_filename
  mov	ecx,1102q		;open read/write & create
  mov	edx,644q
  call	file_open
  mov	[fd_open_flg],eax
  popa
lo_exit:
  ret  
;-------
  [section .data]
log_filename: db "log",0
  global fd_open_flg
fd_open_flg:	dd	0		;file descriptor

  [section .text]
;---------------------------------------------------------
;****f* err/log_close *
; NAME
;  log_close - close log file in local driectory
; INPUTS
;  * none
; OUTPUT
;  * none (all registers unchanged)
; NOTES
;  * source file: log.asm
;  * This function is optional for most applications. Normally,
;  * all files are closed when a program terminates.
;  * ----------------------------------------------
;*******

  global log_close
log_close:
  pusha
  mov	ebx,[fd_open_flg]
  call	file_close
  popa
  ret
;---------------------------------------------------------
;****f* err/log_num *
; NAME
;>1 log-error
;  log_num - write number to file called "log"
; INPUTS
;    eax = binary number for log file
;          (convert to decimal ascii then written)
; OUTPUT
;    none (all registers unchanged)
;    file "log" will have <space>number<space> appended.
; NOTES
;    source file: log.asm
;<
;  * ----------------------------------------------
;*******
  global log_num
log_num:
  call	log_open
  pusha
  mov	edi,number
;  mov	esi,4			;store 4 digits
;  call	dword_to_l_ascii
  call	dword_to_ascii
  mov	al,' '
  stosb				;put space after number
  mov	byte  [edi],0		;put zero at end
  mov	ebx,[fd_open_flg]
  mov	ecx,number_start	;data to write
  mov	edx,edi			;edx= end of write
  sub	edx,ecx         	;compute write length
  call	file_write
  popa
  ret
;---------
  [section .data]
number_start: db ' '
number: times 10 db 0
  [section .text]
;---------------------------------------------------------
;****f* err/log_hex *
; NAME
;>1 log-error
;  log_hex - write hex to file called "log"
; INPUTS
;    eax = binary number for log file
;          (converted to hex ascii then written)
; OUTPUT
;    none (all registers unchanged)
;    file "log" will have <space>number<space> appended.
; NOTES
;    source file: log.asm
;<
;  * ----------------------------------------------
;*******
  global log_hex
log_hex:
  call	log_open
  pusha
  mov	edi,hex_number
  mov	ecx,eax			;hex in ecx
  call	dword_to_hexascii
  mov	ebx,[fd_open_flg]
  mov	edx,12			;write 10 bytes
  mov	ecx,hex_number_start	;data to write
  call	file_write
  popa
  ret
;-----------
  [section .data]
hex_number_start: db ' 0x'
hex_number: db '00000000 '
  [section .text]
;---------------------------------------------------------
;****f* err/log_str *
; NAME
;>1 log-error
;  log_str - write string to file called "log"
; INPUTS
;    esi = string ptr for log file
; OUTPUT
;    none (all registers unchaged)
;    file "log" will have string appended to end
; NOTES
;    source file: log.asm
;<
;  * ----------------------------------------------
;*******
  global log_str
log_str:
  call	log_open
  pusha
  call	strlen1		;returns length in ecx
  mov	ebx,[fd_open_flg]
  mov	edx,ecx			;write x bytes
  mov	ecx,esi			;data to write
  call	file_write
  popa
  ret
  
;---------------------------------------------------------
;****f* err/log_regtxt *
; NAME
;>1 log-error
;  log_regtxt - write string in -eax- to file called "log"
; INPUTS
;    eax = 4 character ascii string
; OUTPUT
;    none (all registers unchanged)
;    file "log" will have string appended to end
; NOTES
;    source file: log.asm
;<
;  * ----------------------------------------------
;*******
  global log_regtxt
log_regtxt:
  call	log_open
  pusha
  mov	[number],eax
  mov	ebx,[fd_open_flg]
  mov	edx,4			;write 4 bytes
  mov	ecx,number		;data to write
  call	file_write
  popa
  ret
;---------------------------------------------------------
;****f* err/log_eol *
; NAME
;>1 log-error
;  log_eol - write eol (end of line) to "log"
; INPUTS
;    none
; OUTPUT
;    none (all registers unchaged)
;    file "log" will have eol (0ah) appended to end
; NOTES
;    source file: log.asm
;<
;  * ----------------------------------------------
;*******
  global log_eol
log_eol:
  call	log_open
  pusha
  mov	ebx,[fd_open_flg]
  mov	edx,1			;write 1 bytes
  mov	ecx,eol_msg		;data to write
  call	file_write
  popa
  ret
;-----------
eol_msg: db 0ah

