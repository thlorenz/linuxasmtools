
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
  extern blk_clear
  extern bit_set_list
;  extern lib_buf
;----------------------
;****f* sys/wait_event *
; NAME
;>1 sys
;   wait_event - poll fd input/output status
; INPUTS
;    esi = array of dword fd's terminated by -1
;    eax = max wait time(usec), or zero to wait forever, and
;          minus 1 for immediate return of status
; OUTPUT
;    eax = 0 child has died? signal?
;        = negative, then error/signal active(-4)
;        = positive number of events pending
;    ecx = ptr to array of bits set for each fd with
;          pending actions, bit 1 represents stdin (fd 0).
;          fd's must be in numerical order (small to large).
; NOTES
;    source file wait_event.asm
;    note: see bit_test, bit_set_list
;<
;  * ---------------------------------------------------
;*******
  global wait_event
wait_event:
  push	eax		;save wait forever flag
  mov	ecx,20
  mov	edi,event_buf	;temp buffer for array
  call	blk_clear

  call	bit_set_list	;set bits
  mov	ebx,[esi-8]	;get value of highest fd
  inc	ebx		;ebx = highest fd +1
  mov	ecx,edi		;ecx = bit array ptr (input)
  xor	edx,edx		;edx = 0 (no write bit array)
  xor	esi,esi		;esi = 0 (no exceptfds bit array)

  pop	edi		;get wait flag
  or	edi,edi
  js	we_fast_rtn	;jmp if immediate return
  jz	we_forever
;edi = number of microseconds to wait
  mov	[_time+4],edi	;set microseconds
we_fast_rtn:
  mov	edi,_time	;assume stored time is zero
we_forever:	
  mov	eax,142
  int	80h
  ret

  [section .data]
_time:	dd	0	;zero seconds, returns status immediatly
	dd	0	;microseconds to wait
event_buf: dd	0,0,0,0,0,0,0
;bits representing fd numbers to poll, stdin=bit#1
  [section .text]

