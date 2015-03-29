
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
;------------------- poll_socket ----------------------------------
;>1 server
;  poll_socket - check if key avail.
; INPUTS
;    eax = fd (file descriptor)
;    edx = milliscond wait count,
;          -1=forever, 0=immediate return
; OUTPUT
;    flags set "js" - error (check before jnz)
;              "jz" - no event waiting, or timeout
;              "jnz" - event ready 
; NOTES
;    source file: poll_socket.asm
;<
; * ----------------------------------------------
 global poll_socket  
poll_socket:
  mov	[poll_tbl],eax		;save fd
  mov	eax,168			;poll
  mov	ebx,poll_tbl
  mov	ecx,1			;one structure at poll_tbl
;  mov	edx,2			;wait xx ms
  int	80h
  or	eax,eax
  js	poll_exit
  jz	poll_exit
  test	byte [poll_data],1
poll_exit: 
  ret


  [section .data]
;  global poll_data
poll_tbl	dd	0	;stdin
		dw	1	;events of interest,data to read
poll_data	dw	-1	;return from poll
  [section .text]


