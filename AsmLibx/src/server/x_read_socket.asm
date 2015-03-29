
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
  extern lib_buf
%ifndef DEBUG
  extern socket_fd
  extern list_block
  extern x_flush
%endif
  extern delay
  extern list_check_front
  extern list_get_from_front

  extern poll_socket
;%include "poll_socket.inc"
;---------------------
;>1 server
;  x_read_socket - read x server socket
; INPUTS
;    eax = wait length in milliseconds
;          0=no wait,immediate check for data
;         -1=forever
;    ecx = buffer for data
;    edx = buffer length
;
;    note: the sequence number queue set
;          by x_send_request may be used.
;
; OUTPUT:
;    success state          
;     flag set (jns) if success - expected reply or event
;     eax = number of bytes in buffer
;     ecx = reply buffer ptr 
;    fail state
;     flags - set for js
;     eax = negative error
;           -1=reply read error (buffer error)
;           -2=error packet in buffer
;           -3=reply out of sequence
;           -4=timeout expired or servers in tryagain loop
;           -5=unexpected event while waiting for reply.
;           -6=socket died
;           -x=all other errors are from kernel
;   
; NOTES
;   source file: x_read_socket.asm
;   see file event_info.inc for reply codes
;   This is the low level function used by all other
;   x server packet read functions.  See also,
;   x_wait_event
;   x_wait_reply
;   x_wait_big_reply
;   window_event_decode
;<
; * ----------------------------------------------
  global x_read_socket
x_read_socket:
  mov	[poll_timeout],eax
  mov	[pkt_buf],ecx
  mov	[pkt_buf_length],edx
  mov	[timeout],byte 80
;
  call	x_flush

; The following kludge allows programs to create windows.
; Occasionally windows will appear witout the delay, and
; occasionally windows will fail even with the  delay.
; ?? what is happening ??  
;  mov	eax,2
;  call	delay
  jmp	short data_waiting	;;
x_read_socket3:
  mov	eax,[socket_fd]
  mov	edx,[poll_timeout]	;
  call	poll_socket
  jnz	data_waiting
  mov	eax,-4			;
  jmp	x_read_socket_exit
data_waiting:
  mov ebx, [socket_fd]
  mov eax,3		; __NR_read
  mov	ecx,[pkt_buf]
  mov	edx,32		;standard read size
  int byte 80h
  cmp	eax,-11		;try again?
  jne	x_read_socket4	;jmp if posible good read
;  mov	eax,10
;  call	delay
  dec	dword [timeout]
  mov	eax,[timeout]
  or	eax,eax
  jnz	x_read_socket3	;loop back = retry
  mov	eax,-1
  jmp	short x_read_socket_exit
;check if good read
x_read_socket4:
  or	eax,eax
  js	x_read_socket_exit	;exit if error
  jnz	x_read_socket4a		;jmp if socket data read
  mov	eax,-6			;eax=0, socket dead, exit
  jmp	short x_read_socket_exit
x_read_socket4a:
%ifdef DEBUG
;;  call	rdump
%endif
  cmp	byte [ecx],0		;error packet?
  jne	x_read_socket5		;jmp if not error packet

;; note; do we need to pop possible reply packet here?

  mov	eax,-2			;get code = error packet
  jmp	short x_read_socket_exit
;check if waiting for reply, eax=read cnt, ecx=buf ptr
x_read_socket5:
  mov	edx,list_block
  push	eax
  call	list_check_front	;point at seq# on top of list
  pop	eax			;restore read count
  js	x_read_socket_exit	;exit if not reply (expected event?)
;verify this is a reply
  cmp	byte [ecx],1		;reply packet
  jne	x_read_socket5a		;jmp if not replay  
;this should be reply event,check seq#, esi=event ptr
  mov	bx,[ecx+2]		;get seq# from reply
  cmp	bx,[esi]		;check against list
  je	x_read_socket7		;jmp if sequence# match, expected pkt
;this is unexpected packet,check if event or reply
x_read_socket5a:
;  cmp	byte [ecx],1		;is this a reply packet
;  je	x_read_socket6		;jmp if reply
  mov	eax,-5
  jmp	short x_read_socket_exit
x_read_socket6:
  mov	eax,-3			;reply out of sequence
  jmp	short x_read_socket_exit
;we have expected reply,pop list, read tail if more data
x_read_socket7:
  push	eax
  call	list_get_from_front
  pop	eax			;restore read length
  mov	edx,[ecx+4]		;get remaining pkt data count
  or	edx,edx
  jz	x_read_socket_exit	;jmp if all pkt data read
  add	ecx,32			;advance buffer ptr
  shl	edx,2			;convert to byte count
;read rest of packet
  mov ebx, [socket_fd]
  mov eax,3		; __NR_read
  int byte 80h
  or	eax,eax
  js	x_read_socket_exit
  add	eax,32		;restore correct packet length
  sub	ecx,32		;restore buffer start
x_read_socket_exit:
  or	eax,eax
  ret
;--------------------------
  [section .data]
pkt_buf	dd 0
pkt_buf_length dd 0
poll_timeout dd 0

timeout: dd 0		;used if server says try again later

  [section .text]

%ifdef DEBUG
  extern hex_dump_stdout
  extern socket_fd
  extern list_block
  extern x_flush
  extern crt_str

rdump:
  push	eax
  push	ecx

  push	ecx
  push	eax
  mov	ecx,reciev_msg
  call	crt_str
  pop	ecx			;get buffer len
  pop	esi			;get buffer ptr
  call	hex_dump_stdout

  pop	ecx
  pop	eax
  ret

  [section .data]
reciev_msg: db 'reply dump',0ah,0
%endif


  [section .text]
