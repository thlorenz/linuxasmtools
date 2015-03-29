
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

 extern raw_set1,raw_unset1
 extern crt_str
 extern delay
 extern key_poll
 extern read_stdin
 extern kbuf
; extern crt_type
 extern lib_buf
;-------------------------------------------------
;****f* terminal/terminal_report *
; NAME
;>1 terminal
;  terminal_report - get report using screen codes
; INPUTS
;    ecx = request string
; OUTPUT
;    [kbuf] has result string if eax=positive
; NOTES
;    source file:  terminal_report.asm
;<
;  * ----------------------------------------------
;-------------------------------------------------
; input:  ecx = string ptr
; output: key_buf has report if eax=0 or positive
;
  global terminal_report
terminal_report:
  push	ecx
  call	raw_set1
  pop	ecx
  call	crt_str			;send string
  mov	ecx,20
gr_loop:
  push	ecx
  mov	eax,10
  call	delay
  call	key_poll
  pop	ecx
  jnz	gr_ready
  loop	gr_loop			;keep waiting
  xor	eax,eax
  dec	eax			;set fail code (-1)
  jmp	short gr_exit
;a key is ready
gr_ready:
  call	read_stdin
gr_exit:
  push	eax
  call	raw_unset1
  pop	eax
  ret


;----------------------------------  
; [section .data]
;term_text	db	"TERM",0


;----------------------------------------------------------------


%ifdef DEBUG
  [section .text]

  extern env_stack
  global main,_start
main:
_start:
  nop
  call	env_stack
  mov	ebp,table
xloop:
  mov	ecx,eol
  call	crt_str
  mov	ecx,ebp
  inc	ecx		;move past ESC
  call	crt_str		;show string we are sending
  mov	ecx,ebp
  call	terminal_report	;send string and get report
  or	eax,eax
  js	fail
  mov	ecx,success
  call	crt_str
  mov	ecx,kbuf + 1
  call	crt_str
  jmp	short tail
fail:
  mov	ecx,failx
  call	crt_str
tail:
  mov	ecx,eol
  call	crt_str
  mov	esi,ebp
next_string:
  lodsb
  or	al,al
  jnz	next_string
  mov	ebp,esi
  cmp	byte [esi],0
  jne	xloop		;jmp if more strings
;check $TERM
  mov	ecx,eol
  call	crt_str
  call	crt_type
  mov	ecx,lib_buf
  call	crt_str
  mov	ecx,eol
  call	crt_str

  mov	eax,1
  int	byte 80h
;--------
  [section .data]
eol: db 0ah,0
success: db ' -ok- ',0
failx: db ' -no response- ',0

table:
  db 1bh,'[c',0
  db 1bh,'[0c',0
  db 1bh,'Z',0
  db 1bh,'[0x',0
  db 1bh,"[18t",0	;win text size report
  db 1bh,"[24;t",0	;win lines request
  db 1bh,"[14t",0
  db 1bh,"[19t",0
  db 1bh,"[11t",0
  db 1bh,'[5n',0
  db 1bh,'[6n',0
  db 0

  [section .text]
%endif

