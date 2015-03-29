
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
;---------------- x_check_event ----------------------

  extern socket_fd
  extern poll_socket
  extern list_block
  extern list_check_front
;---------------------
;>1 server
;  x_check_event - check if events ready or pending
; INPUTS
;   none
; OUTPUT:
;   eax = -1 "js" error
;          0 "jz" no socket pkts, no pending replies
;          1  socket pkt avail.
;          2  expecting reply
;          3  socket pkt avail. & expecting reply
; NOTES
;   source file: x_check_event.asm
;<
; * ----------------------------------------------
  global x_check_event
x_check_event:
  mov	edx,list_block
  call	list_check_front ;returns "js" if empty list (eax=-1)
  push	eax		;eax=0 if entry found, else -1
  mov	eax,[socket_fd]
  xor	edx,edx		;return immediatly
  call	poll_socket		;returns jz = no data waiting
;                       ;        js = error
;                       ;        jnz = no data waiting or error
  pop	eax		;eax=0 if pending, -1 if no pending
  js	ce_exit		;jmp if error
  jz	no_poll		;jmp if no poll data    
;poll found data, eax=0 if pend  -1 if no pend
  or	eax,eax
  mov	eax,01h		;set found poll
  jz	have_pending
  jmp	short ce_exit	;exit if found poll, no pending
no_poll:		;no poll data, eax=0(pending) -1(no pending)
  or	eax,eax
  jz	have_pending
;no poll data, no pending
  xor	eax,eax
  jmp	short ce_exit   ;no poll, no pend (eax=0)
have_pending:
  or	al,2		;no poll, have pend  (eax=2)
ce_exit:		; 1h=poll hit  2h=pend hit -1=error
  or	eax,eax
  ret

  [section .text]
