
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
;---------------- x_send_request.asm -------------------
%ifndef DEBUG
  extern x_connect
  extern socket_fd
%endif
  extern list_put_at_end
  extern delay
;---------------------
;>1 server
;  x_send_request - send request to x server
; INPUTS
;    ecx = packet ptr
;    edx = packet length, negative packet lenght
;          indicates a reply is expected.  Length
;          is can be set negative with "neg edx"
; OUTPUT:
;    flag set (jns) if success
;    flag set (js) if err, eax=error code
;    [sequence] - sequence number of packet sent
;        
; NOTES
;   source file: x_send_request.asm
;   If socket_fd is zero this functions connects to
;   x socket.  If the packet lenght is negative a
;   reply is expected and the sequence# is stored
;   for retrevial by x_read_socket
;<
; * ----------------------------------------------
  global x_send_request
x_send_request:
  global x_send
x_send:
  mov	ebx,[socket_fd]	;get socket fd
  or	ebx,ebx
  jnz	x_send2		;jmp if connected
  push	ecx
  push	edx
  call	x_connect	;connect to the server
  pop	edx
  pop	ecx
  js	x_send_exit	;exit if error
x_send2:
  inc	dword [sequence]
  or	edx,edx		;check if reply expected
  jns	x_send3		;jmp if no reply expected
  neg	edx		;make packet length positive
  push	edx
  push	ecx
  mov	edx,list_block
  mov	esi,sequence
  call	list_put_at_end
  pop	ecx
  pop	edx
x_send3:
  push	ecx
  push	edx
  mov	ebx,[socket_fd]
  call	poll_out
  pop	edx
  pop	ecx

;append to buffer
  cmp	edx,[x_buf_avail]
  jb	queue_packet
  call	x_flush		;flush before
queue_packet:
  sub	[x_buf_avail],edx
  mov	esi,ecx
  mov	edi,[x_buf_ptr]
  mov	ecx,edx
  rep	movsb
  mov	[x_buf_ptr],edi
  xor	eax,eax		;set exit flag
  ret
;  jmp	short x_send_exit
;---------------------
;>1 server
;  x_flush - send queued events to x server
;   the x_send_request function buffers all output
;   and sends if buffer becomes full or the program
;   waits for input.  This function flushes (sends)
;   the buffer to the x server.
; INPUTS
;    none
; OUTPUT:
;    sign flag set if error and eax modified
;    all other registers preserved.
;        
; NOTES
;   source file: x_send_request.asm
;<
; * ----------------------------------------------
;
; flush the buffer 
;
  global x_flush
x_flush:
  pusha
  mov	ecx,x_buf
  mov	edx,[x_buf_ptr]
  sub	edx,ecx
  or	edx,edx
  jz	x_send_exit	;exit if buffer empty  
  mov eax,4		; __NR_write
  mov ebx, [socket_fd]
  int byte 80h
  cmp	eax,-11		;is server busy
  jne	x_send4		;jmp if success or error
  jmp	short x_flush 
x_send4:
  mov	[x_buf_ptr],dword x_buf
  mov	[x_buf_avail],dword x_buf_size
%ifdef DEBUG
;;  call	dump
%endif
x_send_exit:
  mov	[save_eax],eax
  popa
  mov	eax,[save_eax]
  or	eax,eax
  ret
;---------------------

poll_out:
  mov	[polled_fd],ebx
  mov	eax,168
  mov	ebx,poll_block
  mov	ecx,1	;one fd
  mov	edx,-1	;timeout
  int	byte 80h
  test	[poll_response], byte 4
  ret
;---------------------
  [section .data]

poll_block:
polled_fd:   dd 0
	   dw 4	;write now will not block
poll_response:  dw -1

  global sequence,list_block
sequence: dd 0		;socket sequence#
;sequence# database control block
list_block:
       dd buffer     ;top of buffer
       dd buffer_end ;end of buffer
       dd 2          ;each entry x bytes long
       dd buffer     ;first entry ptr
       dd buffer     ;last entry ptr
;storage for sequence# expecting a reply
buffer: times 60 dw 0
buffer_end:

x_buf_size	equ  1024
x_buf_ptr	dd x_buf
x_buf_avail	dd x_buf_size
  global x_buf
x_buf	times x_buf_size db 0
x_buf2	times 3000 db 0
  global x_buf_size2
x_buf_size2 equ $ - x_buf
save_eax	dd 0
;-------------------------------------------------------------
  [section .text]


%ifdef DEBUG
  extern crt_str
  extern hex_dump_stdout
  extern write_hex_byte_stdout
  extern socket_fd
  extern x_connect

dump:
  push	ecx
  push	eax

  push	ecx
  push	edx
  mov	ecx,socket_txt
  call	crt_str
  mov	eax,[sequence]
  call	write_hex_byte_stdout
  mov	ecx,eol_msg
  call	crt_str    
  pop	ecx
  pop	esi
  call	hex_dump_stdout  

  pop	eax
  pop	ecx
  ret
;-----
  [section .data]
socket_txt: db 0ah,'Socket output - seq#=',0
eol_msg:	db 0ah,0
  [section .text]
%endif