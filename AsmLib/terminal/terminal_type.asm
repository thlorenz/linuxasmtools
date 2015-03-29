
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

 extern terminal_report
; extern x_connect

  [section .text]
;-------------------------------------------------
; NAME
;>1 terminal
;  terminal_type - check if console or xterm
; INPUTS
;   Function env_stack must be called at start of
;   application to setup [enviro_ptrs]
; OUTPUT
;    al = 0 - unknown terminal
;         1 - x window, no terminal
;           [socket_fd] global set to socket fd (dword)
;           [root_win_pix_width] set (dword)
;           [root_win_pix_height] set (dword)
;         2 - console
;         3 - xterm clone
;          [socket_fd] global set to socket fd (dword)
;          [root_win_pix_width] set (dword)
;          [root_win_pix_height] set (dword)
;    [term_type] - global byte variable set using "al"
;         initially term_type is set -1, once terminal_type
;         has set term_type, the set value is returned and
;         no terminal interrogtion occurs.
; NOTES
;    source file:  terminal_type.asm
;
;<
;  * ----------------------------------------------
;*******
  extern find_env_variable,lib_buf
  global terminal_type
terminal_type:
  mov	al,[term_type]
  cmp	al,-1
  jne	tt_exit			;jmp if terminal type known already
  mov	ecx,term_text
  mov	edx,lib_buf
  call	find_env_variable
  cmp	edi,0
  je	tt_20			;jmp if no term variable found
;decode term variable
  mov	edi,lib_buf
  cmp	dword [edi],'xter'	;check if xterm
  je	xterm_type		;jmp if xterm
  cmp	dword [edi],'linu'
  je	linux_console		;jmp if console found
  cmp	dword [lib_buf],'dumb'
  je	just_x			;jmp if x window, no terminal 
;unknown terminal type
tt_20:
  mov	ecx,xterm_test
  call	terminal_report
  or	eax,eax
  jns	xterm_type		;termnal found, assume xterm type
;terminal does not respond to ctrl sequences, set unknown type
  jmp	short tt_exit	
just_x:
  mov	al,1			;set just x, no terminal
  jmp	short tt_exit		
linux_console:
  mov	al,2
  jmp	short tt_exit
xterm_type:
  mov	al,3			;xterm clone
tt_exit:
  mov	[term_type],al		;save terminal type
  ret
;----------------------------
  [section .data]
xterm_test: db 1bh,'[6n',0	;report cursor position
term_text	db	"TERM",0
  global term_type
term_type: db	-1
  [section .text]
;---------------------------
%ifdef NULL
;%ifdef DEBUG
  [section .text]

 extern raw_set1,raw_unset1
 extern crt_str
 extern delay
 extern key_poll
 extern read_stdin
 extern kbuf
  extern env_stack
  global main,_start
main:
_start:
  nop
  call	env_stack
  call	terminal_type
  mov	eax,1
  int	byte 80h
;--------

  [section .text]
%endif

