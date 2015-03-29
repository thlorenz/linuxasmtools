
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
;  signals_ending - get mask for pending signals
; INPUTS  none
; OUTPUT  bits in ebx
;              (dword) 0000 0001 = signal 1
;                      0001 0000 = signal 17
;         [ebx] data is accessed as dword not bytes?
; NOTES
;    See file /err/install_signals for more documentation.
;<
; *  ----------------------------------------------
;*******
  global signals_pending
signals_pending:
  mov	ebx,pend_mask
  mov	eax,73
  int	80h
  mov	ebx,[ebx]	;get mask bits
  ret

  [section .data]
pend_mask:	dd	0
  [section .text]  
  