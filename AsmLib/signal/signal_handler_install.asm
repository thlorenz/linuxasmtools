
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

;----------------------------------------------------------------
;>1 signal
;  signal_install_list - install signals
; INPUTS
;     ebp = pointer to  table describing each signal to install.
;     The table is terminated with a zero byte in the signal number
;     field.
;       Sanple table entry for to install the SIGILL signal.
;     db 4			;signal number = illegal action SIGILL
;     dd handleIll		;handler for signal
;     dd 0                      ;mask (signals to ignore while handling this sig)
;     dd 4			;set siginfo telling kernel to pass status data to handler
;     dd 0			;always zero
;     db 0                      ;end of table or next signal number
; OUTPUT eax (0) success
;            EINVAL (-22) not catchable
;            EFAULT (-14) memory error
;            EINTR  (-4)  sys call interrupted
;            ebp = bad signal table entry ptr if error   
; NOTES
;    See file /err/install_signals for more documentation.
;<
; *  ----------------------------------------------
;*******
  global signal_install_list
signal_install_list:
	sub	ebx,ebx
	mov	bl,[ebp]	;get signal number
	inc	ebp		;move to top of sa_block
	mov	ecx,ebp
        call	signal_install
        or	eax,eax
	js	is_exit		;exit if error
	add	ebp,16		;move to next table entry
	cmp	byte [ebp],0	;done?
	jnz	signal_install_list	;loop till done
is_exit:
	ret
;----------------------------------------------------------------
;>1 signal
;  signal_install - install signal
; INPUTS  ebx = signal number
;         ecx = ptr to data block as follows:
;               dd handler
;               dd mask (signals to ignore while handling this sig)
;               dd flags 04h =  3 arguments -> handler instead of 1
;               dd 0 (dummy unused field)
; OUTPUT eax (0) success
;            EINVAL (-22) not catchable
;            EFAULT (-14) memory error
;            EINTR  (-4)  sys call interrupted
;   
; NOTES
;    See file /err/install_signals for more documentation.
;<
; *  ----------------------------------------------
;*******
  global signal_install
signal_install:
	xor	edx,edx
	mov	eax,67		;kernel code for sigaction
	int	80h		;install signal handler
;        call	error_check
	ret

  