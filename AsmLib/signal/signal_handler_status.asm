
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
;  signal_handler_status - check if our signal handler installed
; INPUTS  ebx = signal number
; OUTPUT  eax = (0) success
;         edx = ptr to   dd handler or ptr to SIG_DFL,SIG_IGN
;                        dd mask
;                        dd flag
;                        dd unused
;         initial status after load returned - 0,0,0,bfef0468
;         after handler installed   returned - handler,mask,flag,0
;         after handler removed returned     - pointer,0,0,ccc53fbc
;                                              (pointer) -> dd 0 or 1
; NOTES
;    See file /err/install_signals for more documentation.
;<
; *  ----------------------------------------------
;*******
  global signal_handler_status
signal_handler_status:
	xor	ecx,ecx		;
	mov	edx,bufx
	mov	[edx],ecx	;clear old values
	mov	[edx+4],ecx	;clear old values
	mov	eax,67		;kernel code for sigaction
	int	80h		;query signal handler
	ret

  [section .data]
bufx: dd	0,0,0,0,0
  [section .text]  