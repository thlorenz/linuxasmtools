
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
%ifdef DEBUG

 [section .text]

 extern signal_handler_status
 extern signal_install
 extern signal_send

 global _start
 global main
_start:
main:    ;080487B4
  cld

  mov	ebx,10
  call	signal_handler_status

  mov	eax,[edx]		;edx = ptr to sig block

;install handler for 10
  mov	ebx,10			;install handler for signal 10
  mov	ecx,data_block
  call	signal_install
;check handler status

  mov	ebx,10
  call	signal_handler_status

  mov	eax,[edx]		;edx = ptr to sig block

; test - signal_send --- handler installed

  mov	eax,20
  int	80h			;get our pid
  mov	[our_pid],eax
  mov	ebx,eax			;send signal to ourself
  mov	ecx,10			;send signal 10
  call	signal_send

  mov	al,[got_signal]
;disable our local handler
  mov	ebx,10
  call	signal_handler_default
;check status
  mov	ebx,10
  call	signal_handler_status
  mov	eax,[edx]		;edx = ptr to sig block
;
; test - signal_send --- no handler

  mov	eax,20
  int	80h			;get our pid
  mov	[our_pid],eax
  mov	ebx,eax			;send signal to ourself
  mov	ecx,10			;send signal 10
  call	signal_send

  mov	al,[got_signal]

; completly remove all handlers

  mov	ebx,10
  call	signal_handler_none
;check status
  mov	ebx,10
  call	signal_handler_status
  mov	eax,[edx]		;edx = ptr to sig block
; test - signal_send --- no handler

  mov	eax,20
  int	80h			;get our pid
  mov	[our_pid],eax
  mov	ebx,eax			;send signal to ourself
  mov	ecx,10			;send signal 10
  call	signal_send

  mov	al,[got_signal]

  mov	eax,1
  int	80h

;---------
  [section .data]

got_signal: db 0
data_block:
  dd	handler
  dd	200h		;signals to ignore while handling this sig
  dd	0		;1 arguement
  dd	0		;unused
buffer  times 20 db 0
our_pid	dd	0

  [section .text]
;
; dummy signal handler
;
handler:
	inc	byte [got_signal]
	ret

%endif

;----------------------------------------------------------------
;>1 signal
;  signal_handler_default - set default handler for signal
; INPUTS  ebx = signal number
; OUTPUT  eax = error or
;               old signal handler address
; NOTES
;    See file /err/install_signals for more documentation.
;    This function uses kernel call sigaction to set
;    handler state of SIG_DFL
;<
; *  ----------------------------------------------
;*******
  global signal_handler_default
signal_handler_default:
  xor	eax,eax			;get "default" handler flag
  jmp	short set_action

;----------------------------------------------------------------
;>1 signal
;  signal_handler_none - set no handler for signal
; INPUTS  ebx = signal number
; OUTPUT  eax = error of
;               old signal handler address
; NOTES
;    See file /err/install_signals for more documentation.
;    This function uses kernel call sigaction to set
;    handler state of SIG_IGN
;<
; *  ----------------------------------------------
;*******
  global signal_handler_none
signal_handler_none:
  mov	eax,1		;get "SIG_IGN" handler flag
set_action:
  mov	ecx,sig_block
  mov	[ecx],eax	;stuff our flag
  xor	edx,edx
  mov	eax,67		;sigaction kernel call
  int	80h
  ret


  [section .data]
sig_block: dd	0,0,0,0
  [section .text]
  