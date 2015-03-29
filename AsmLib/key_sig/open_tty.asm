;-------------------------------------------------

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
;   along with this program.  If not, see <http://www.gnu.org/licenses/.


  [section .text align=1]

  extern sys_open

;---------------------------------------------------
;---------------------------------------------------
;#1 key_sig
;open_tty - open device /dev/tty
; INPUT
;   none
; OUTPUT
;   global tty_fd is set
;   ebx = fd
; NOTE
;    source file /key/open_tty.asm
;#
;------------------------------------------------
  global open_tty
open_tty:
  mov	ebx,[tty_fd]
  cmp	ebx,dword 1
  jne	ot_exit		;jmp if tty open
  mov	ebx,tty_dev
;  mov	ecx,2		;mode = read/write
  mov	ecx,0000q      ;mode = read only
  mov	edx,0666h	;premissions
  call	sys_open
  or	eax,eax
  js	ot_exit		;jmp if no /dev/tty
  mov	[tty_fd],eax
  mov	ebx,eax
ot_exit:
  ret
;-------
  [section .data]
global tty_fd
tty_fd: dd 1	;default is stdin
tty_dev	db '/dev/tty',0
  global ks1,ks2
ks1:	times 16 db 0 ;key string 1
ks2:	times 16 db 0 ;key stirng 2

  [section .text]
