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

%include "../include/signal.inc"
;---------------------------------------------------
  extern installed_sig_mask
  extern open_tty
  extern lib_buf
  extern signal_attach

struc termio_struc
.c_iflag: resd 1
.c_oflag: resd 1
.c_cflag: resd 1
.c_lflag: resd 1
.c_line: resb 1
.c_cc: resb 19
endstruc
;termio_struc_size:

;---------------------------------------------------
;>1 key_sig
;key_setup - setup signal driven key handling
; INPUT
;   none
; OUTPUT
;   none
; NOTE
;   source file key_setup.asm
;   The "key" routines work together and other keyboard
;   functions should be avoided.  The "key" family is:
;   key_fread - flush and read
;   key_read - read key
;   key_check - check if key avail.
;   key_put - push a key back to buffer
;<

  global key_setup
key_setup:
  or	[installed_sig_mask],dword _IO	;set SIGIO
;  or	[installed_sig_mask],dword _URG
  call	open_tty	;sets fd in ebx
;ebx = fd, read termios
  mov	edx,termios1
  mov	ecx,5401h
  mov eax,54
  int	80h
;read another copy of termios
  mov	edx,lib_buf
  mov	ecx,5401h
  mov eax,54
  int	80h
;set raw mode
  and	byte [edx + termio_struc.c_lflag],~0bh ;set raw mode
  or	byte [edx + termio_struc.c_iflag +1],01 ;
  and	byte [edx + termio_struc.c_iflag+1],~14h ;disable IXON,IXOFF
;output raw termios
  mov	ecx,5402h
  mov eax,54
  int	80h
;ebx is fd to attach, attach keyboard to SIGIO
  mov	eax,SIGIO	;tty fd
  mov	ecx,_IO		;mask
;  mov	eax,SIGURG
;  mov	ecx,_URG
  mov	dl,1		;keyboard flag
  call	signal_attach
ks_error:
  ret
;---------------------------------------------------
  [section .data]
  global termios1
termios1:  times 36 db 0
  [section .text]
