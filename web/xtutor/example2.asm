;-----------------------------------------------------------------------
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


global _start
_start:
  call	env_stack
  call	x_list_extension
  call	show_extensions
    
  mov	eax,01
  int	byte 80h

;-----------
  [section .data]
crlf:	db 0ah
  [section .text]


show_extensions:
  lea	esi,[ecx+32]
  xor	eax,eax
  mov	al,[ecx+1]	;get number of items returned
  mov	ebp,eax		;save count
show_loop:
  call	line_feed
  lea	ecx,[esi+1]
  xor	edx,edx
  mov	dl,[esi]	;get length of name
  add	esi,edx		;move to next name
  inc	esi
  call	crt_write

  dec	ebp
  jnz	show_loop
  call	line_feed
  ret

line_feed:
  mov	ecx,crlf
  mov	edx,1
  call	crt_write
  ret
;---------- x_list_extension ------------------
;  x_list_extension - get list of extensions
; INPUTS
;    none
; OUTPUT:
;    failure - eax = negative error code
;              flags set for "js"
;    success - eax positive read length and flag set "jns"
;              ecx = buffer ptr with
;  resb 1  ;1 Reply
;  resb 1  ;number of names returned
;  resb 2  ;sequence number
;  resb 4  ;reply length
;  resb 24 ;unused
;  resb 1  ;lenght of extension n
;  resb x  ;extension n string

;  resb 1  ;length of extension n+1
;  resb x  ;extension n+1 string
; * ----------------------------------------------

x_list_extension:
  mov	ecx,list_extension_request
  mov	edx,(qer_end - list_extension_request)
  neg	edx		;indicate reply expected
  call	x_send_request
  js	ger_exit
  call	x_wait_reply
ger_exit:
  ret


  [section .data]
list_extension_request:
 db 99	;opcode
 db 0	;unused
 dw 1	;request lenght in dwords
qer_end:

  [section .text]


;--------------------------------------------------
;  env_stack - find stack ptrs to enviornment
; INPUTS
;    esp = stack ptr before any pops or pushes
; OUTPUT
;    ebp = ptr to enviroment pointers
;    [enviro_ptrs] set also
;  * ----------------------------------------------
env_stack:
  cld
  mov	esi,esp
es_lp:
  lodsd
  or	eax,eax
  jnz	es_lp		;loop till start of env ptrs
  mov	ebp,esi
  mov	[enviro_ptrs],esi
  ret
;--------------------------------------------------------

struc connect_reply
.reply_code	resb 1
		resb 1	;unused
.proto_major	resw 1
.proto_minor	resw 1
.append_len	resw 1	;dword len
.release_num	resd 1
.id_base	resd 1
.id_mask	resd 1
.motion_buf_len resd 1
.vendor_len	resw 1
.max_req_size	resw 1
.screen_cnt	resb 1	;number of screen struc's at end
.format_cnt	resb 1  ;number of format struc's at end
.img_byte_ordr	resb 1	;image byte order 0=lsb 1=msb
.map_byte_ordr	resb 1	;bitmap byte order 0=least sig first
.scan_unit	resb 1
.scan_pad	resb 1
.min_keycode	resb 1
.max_keycode	resb 1
		resd 1  ;unused
.vendor		resb 8  ;string here
.pad		resb 12 ;?
.formats:		;format strucs start here, followed by screen strucs
connect_reply_len:
endstruc

struc format
.depth		resb 1
.bytes_per_pix	resb 1
.scanline_pad	resb 1
		resb 5	;unused
format_len:
endstruc

struc screen
.root_win	resd 1
.color_map	resd 1
.white_pixel	resd 1
.black_pixel	resd 1
.event_mask	resd 1
.pix_width	resw 1
.pix_height	resw 1
.width_mil	resw 1
.height_mil	resw 1
.min_maps	resw 1
.max_maps	resw 1
.root_visual	resd 1
.backing	resb 1 ;0=never 1=when mapped 2=always
.save_under	resb 1 ;bool
.root_depth	resb 1
.depth_cnt	resb 1 ;number of depths that follow
;more data here
endstruc

;---------------------
;  x_connect - connect to x server
; INPUTS
;    env_stack library function must be called before
;              using x_connect
; OUTPUT:
;    flag set (jns) if success
;      and [socket_fd] global set to socket fd (dword)
;          [x_id_base] base for id assign (dword)
;          [root_win_id] set (dword)
;          [root_win_pix_width] set (word)
;          [root_win_pix_height] set (word)
;          [root_win_color_map] set (dword)
;          lib_buf has connection reply
;          connection_reply_length = size of reply
;    flag set (js) if err, eax=error code
;    ecx points to connection table as follows:
;         c_reply_code	db 0
;       		db 0	;unused
;         c_proto_major	dw 0
;         c_proto_minor	dw 0
;         c_append_len	dw 0	;dword len
;         c_release_num	dd 0
;         x_id_base	dd 0
;         c_id_mask	dd 0
;         c_motion_buf_len dd 0
;         c_vendor_len	dw 0
;         c_max_req_size	dw 0
;         c_screen_cnt	db 0	;number of screen struc's at end
;         c_format_cnt	db 0  ;number of format struc's at end
;         c_img_byte_ordr	db 0	;image byte order 0=lsb 1=msb
;         c_map_byte_ordr	db 0	;bitmap byte order 0=least sig first
;         c_scan_unit	db 0
;         c_scan_pad	db 0
;         c_min_keycode	db 0
;         c_max_keycode	db 0
;
;         c_depth		db 0
;         c_bytes_per_pix	db 0
;         c_scanline_pad	db 0
;                               db 0	;pad
;         root_win_id	dd 0
;         root_win_color_map	dd 0
;         c_white_pixel	dd 0
;         c_black_pixel	dd 0
;         c_event_mask	dd 0
;         root_win_pix_width	dw 0
;         root_win_pix_height	dw 0
;         c_width_mil	dw 0
;         c_height_mil	dw 0
;         c_min_maps	dw 0
;         c_max_maps	dw 0
;         c_root_visual	dd 0
;         c_backing	db 0 ;0=never 1=when mapped 2=always
;         c_save_under	db 0 ;bool
;         c_root_depth	db 0
;         c_depth_cnt	db 0 ;number of depths that follow
; * ----------------------------------------------

x_connect:
  xor	eax,eax
  cmp	dword [socket_fd],eax
  jne	err		;exit if already connected
;check if enviornment variable DISPLAY=:x set
  mov	ecx,display_var
  mov	edx,display_var_contents
  call	find_env_variable
  mov	al,[display_var_contents+1]
  or	al,al
  jz	x_conn_strt	;jmp if no display variable
  mov	[display_number],al   
x_conn_strt:
  call	get_authorization ;get server info
  js	err		;exit if error
  call	connect		;connect to socket
  js	err		;exit if error
  mov	[connection_reply_length],eax
  mov   esi, lib_buf
  cmp	byte [esi],1
  je	x_conn_ok
  mov	eax,-1
  jmp	short err
x_conn_ok:
;save data from connnecton reply
  mov	edi,c_reply_code
  mov	esi,lib_buf
  mov	ecx,(c_max_keycode+1) - c_reply_code
  rep	movsb

  mov	esi,lib_buf+connect_reply_len
  mov	ecx,4
  rep	movsb

;compute index to first screen struc
  xor	eax,eax
  mov	ax,[lib_buf+connect_reply.format_cnt]
  shl	eax,3		;multilpy by 8
  add	eax,connect_reply_len ;move to start of screen struc
  add	eax,lib_buf	;add in buffer start
  mov	esi,eax
  mov	ecx,36
  rep	movsb
  mov	ecx,c_reply_code
err:
  ret
;--------------
  [section .data]
connection_reply_length: dd 0
socket_fd:
xfd_array: dd 0,-1


c_reply_code	db 0
		db 0	;unused
c_proto_major	dw 0
c_proto_minor	dw 0
c_append_len	dw 0	;dword len
c_release_num	dd 0
x_id_base	dd 0
c_id_mask	dd 0
c_motion_buf_len dd 0
c_vendor_len	dw 0
c_max_req_size	dw 0
c_screen_cnt	db 0	;number of screen struc's at end
c_format_cnt	db 0  ;number of format struc's at end
c_img_byte_ordr	db 0	;image byte order 0=lsb 1=msb
c_map_byte_ordr	db 0	;bitmap byte order 0=least sig first
c_scan_unit	db 0
c_scan_pad	db 0
c_min_keycode	db 0
c_max_keycode	db 0

;struc format
c_depth		db 0
c_bytes_per_pix	db 0
c_scanline_pad	db 0
                db 0	;pad
;format_len
;endstruc

;struc screen
root_win_id	dd 0
root_win_color_map	dd 0
c_white_pixel	dd 0
c_black_pixel	dd 0
c_event_mask	dd 0
root_win_pix_width	dw 0
root_win_pix_height	dw 0
c_width_mil	dw 0
c_height_mil	dw 0
c_min_maps	dw 0
c_max_maps	dw 0
c_root_visual	dd 0
c_backing	db 0 ;0=never 1=when mapped 2=always
c_save_under	db 0 ;bool
c_root_depth	db 0
c_depth_cnt	db 0 ;number of depths that follow
;more data here
;endstruc
  [section .text]
;---------------------------------
;output: eax=negative if error,sign bit set
;        
connect:
; create a socket
  mov	eax,102		;socket
  mov	ebx,1		;create socket
  mov	ecx,socket_create_blk
  int	byte 80h
  or	eax,eax
  js	c_exit
  mov [socket_fd2],eax
  mov [socket_fd],eax
; connect to it
  mov	eax,102		;socket kernel function
  mov	ebx,3		;connect
  mov	ecx,socket_connect_blk
  int	byte 80h
  or	eax,eax
  js	c_exit
; make the socket non-blocking
  mov ebx, [socket_fd]
  mov ecx, 3		;F_GETFL (get flags)
  mov eax,55		;fcntl
  int byte 0x80
  or	eax,eax
  js	c_exit		;exit if error

  mov ebx, [socket_fd]
  mov ecx, 4		 ;F_SETFL (set flags)
  mov edx, eax
  or edx, 0x800		; NON_BLOCKING
  mov eax,55		;fcntl
  int byte 0x80
  or	eax,eax
  js	c_exit
; write a connection request to it
  mov eax,4		;write kernel function
  mov ebx, [socket_fd]
  mov ecx, conn_request
  mov edx, [conn_request_length]
  int byte 80h
  or	eax,eax
  js	c_exit	;exit if error
; wait for reply
  mov	eax,[socket_fd]
  mov	esi,xfd_array
  mov	[esi],eax	;store fd into array
  xor	eax,eax		;wait forever
  call	wait_event
  or	eax,eax		;error check
  js	conn_err
;test set bit, did our fd have an event?
  mov	eax,[socket_fd]
  mov	edi,ecx
  call	bit_test
  jc	read_conn_reply	;jmp if correct bit
conn_err:
  mov	eax,-1
  jmp	short c_exit
;read the connection reply
read_conn_reply:
  mov ebx, [socket_fd]
  call	read_fd
c_exit:
  or	eax,eax		;set return flag
  ret
;--------------------------------------
; check for x socket info
;input: [enviro_ptrs] - enviornment
;output: eax= negative if error
;        eax= connection packet setup if eax=positive
;
get_authorization:
  mov	ebx,[enviro_ptrs]
  mov	edi,auth_path
  call	env_home		;extract home path
  mov esi, auth_file_name
  mov ecx, auth_file_name_len
  rep movsb			;append .Xauthority to home path
open_xauth:
  mov eax,5			;open kernel function
  mov ebx, auth_path
  xor ecx, ecx			;readonly
  int byte 80h			;read file .Xauthority
  mov edi, conn_request_len	;in case no .Xauth found
  or	eax,eax
  js	no_auth			;jmp if file not found
;read and process Xauthority  file
  mov ebx, eax			;get handle in ebx
  call	read_fd
  js	gx_exit			;exit if error
  mov eax,6			;close kernel function
  int byte 80h
; copy authorization proto name and data
; to connect request data packet
  mov esi, lib_buf + 3      ; offset of host name length
  movzx eax, byte [esi]      ; host name length
  lea esi, [esi + eax + 2]   ; skip host name
  movzx eax, byte [esi]      ; length
  lea esi, [esi + eax + 2]   ; skip it
  movzx ecx, byte [esi]      ; this ought to be auth name length
  mov [conn_request.proto_str_len], cx
  inc esi
  mov edi, conn_request.proto_str
  rep movsb
  inc esi
  add edi,byte 3       ; round up for "pad"
  and edi,byte  -4
  movzx ecx, byte [esi]      ; length of auth data
  mov [conn_request.proto_data_len], cx
  inc esi
  rep movsb
  sub edi, conn_request
  add edi,byte 3
  and edi,byte -4
no_auth:
  mov [conn_request_length], edi
  xor	eax,eax		;set good return
gx_exit:
  or	eax,eax		;set result flag
  ret
;----------------------
  [section .data]

socket_create_blk:	;create a socket data
  dd	1	;PF_UNIX
  dd	1	;SOCK_STREAM
  dd	0	;

socket_connect_blk:
socket_fd2:
  dd 0
  dd socket_path
  dd socket_path_len
socket_path:
    dw    1     ; 1: AF_UNIX, AF_LOCAL  (/usr/include/linux/socket.h)
    db    "/tmp/.X11-unix/X"
display_number:
    db    "0"		;from display  variable
socket_path_len equ $ - socket_path

auth_file_name db '/.Xauthority', 0
auth_file_name_len equ $ - auth_file_name
auth_path	times 200 + 1 db 0


display_var: db 'DISPLAY',0
display_var_contents: times 8 db 0

; Connection Setup info
     align 4, db 0
conn_request:
.endian	db	6Ch	; LSB first
.unused	db	0
.major	dw	11
.minor	dw	0	; major/minor version
.proto_str_len dw	0	; protocol_string_len
.proto_data_len dw	0	; fill in at runtime
.unused2	dw	0
 conn_request_len equ $ - conn_request
.proto_str times 256 db 0	; enough for anybody

conn_request_length dd 0

local_fd	dd 0

  [section .text]
;----------------------
;input: ebx= fd
;output: eax = result & sign bit set
read_fd:
  mov	[local_fd],ebx	;save fd
  mov eax,3		;kernel read functin
  mov ecx, lib_buf
  mov edx, 700		;lib_buf_len
  int byte 80h		;read file
  jns	rf_exit		;jmp if good read
  cmp	eax,-11
  jne	rf_exit
  mov	eax,[local_fd]
  mov	ebx,-1		;wait forever
  call	poll_socket
  js	rf_exit		;exit if error
  mov	ebx,[local_fd]
  jmp	short read_fd
rf_exit:
  or	eax,eax
  ret

  [section .text]
;----------------------
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
;  * ---------------------------------------------------
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

  
;----------------------
;   blk_clear - clear array of bytes
; INPUTS
;    ecx = size of array (byte count)
;    edi = array pointer
;    the CLD flag is set
; OUTPUT
;    ecx = 0
;    edi = unchanged
;  * ---------------------------------------------------
blk_clear:
  push	eax
  push	edi
  xor	eax,eax
  rep	stosb
  pop	edi
  pop	eax
  ret

;----------------------
;bit_set_list - set bits in array
; INPUTS
;    esi = pointer to list of dword bit values
;          0 = bit 1 or 00000001h
;          -1 = end of list
;          values in increasing order
;    edi = array pointer
; OUTPUT
;    bits set in array
;    esi moved to end of list, beyond -1 entry
;  * ---------------------------------------------------
bit_set_list:
  push	edx
  push	eax
sa_loop:
  lodsd			;get bit value
  or	eax,eax
  js	sa_exit		;exit if done (end of list)
  mov	edx,eax
  shr	edx,5
  and	eax,1fh
  lea	edx,[edx*4 + edi] 
  bts	[edx],eax
  jmp	short sa_loop	;loop
sa_exit:
  pop	eax
  pop	edx
  ret
;------------------------------
;   bit_test - test array of bits
; INPUTS
;    eax = bit number
;          (0=bit 1) or 00000001h
;    edi = bit array pointer
; OUTPUT
;    carry = bit set
;    no-carry = bit cleared
;    registers unchanged
;  * ---------------------------------------------------
bit_test:
  push	edx
  mov	edx,eax
  shr	edx,5
  lea	edx,[edx*4 + edi]
  and	eax,1fh
  bt	dword [edx],eax	;check bit
  pop	edx
  ret
;------------------------------
;  env_home - search the enviornment for $HOME
; INPUTS
;     ebx = ptr to list of env pointers
;     edi = buffer to store $HOME contents
; OUTPUT
;    edi = ptr to zero at end of $HOME string
;  * ----------------------------------------------
env_home:
  or	ebx,ebx
  jz	fh_50		;jmp if home path not found
  mov	esi,[ebx]
  or	esi,esi
  jz	fh_50		;jmp if home path not found
  cmp	dword [esi],'HOME'
  jne	fh_12		;jmp if not found yet
  cmp	byte [esi + 4],'='
  je	fh_20		;jmp if HOME found
fh_12:
  add	ebx,byte 4
  jmp	short env_home		;loop  back and keep looking
fh_20:
  add	esi, 5		;move to start of home path
;
; assume edi points at execve_buf
;
  call	str_move
fh_50:
  ret  

  [section .data]
lib_buf	times 700 db 0
enviro_ptrs	dd	0		;from entry stack
  [section .text]
;----------------------------------
;  str_move - move asciiz string
; INPUTS
;    esi = input string ptr (asciiz)
;    edi = destination ptr
; OUTPUT
;    edi points at zero (end of moved asciiz string)
;  * ----------------------------------------------
str_move:
  cld
ms_loop:
  lodsb
  stosb
  or	al,al
  jnz	ms_loop	;loop till done
  dec	edi
  ret
;------------------- poll_socket ----------------------------------
;  poll_socket - check if key avail.
; INPUTS
;    eax = fd (file descriptor)
;    edx = milliscond wait count,
;          -1=forever, 0=immediate return
; OUTPUT
;    flags set "js" - error (check before jnz)
;              "jz" - no event waiting, or timeout
;              "jnz" - event ready 
; * ----------------------------------------------
poll_socket:
  mov	[poll_tbl],eax		;save fd
  mov	eax,168			;poll
  mov	ebx,poll_tbl
  mov	ecx,1			;one structure at poll_tbl
  int	80h
  or	eax,eax
  js	poll_exit
  jz	poll_exit
  test	byte [poll_data],1
poll_exit: 
  ret


  [section .data]
poll_tbl	dd	0	;stdin
		dw	1	;events of interest,data to read
poll_data	dw	-1	;return from poll
  [section .text]

;---------------------------------------
;  find_env_variable - search enviornment for variable name
; INPUTS
;    [enviro_ptrs] - setup by env_stack
;    ecx = ptr to variable name (asciiz)
;    edx = storage point for variable contents
; OUTPUT
;    data stored at edx, if edi is preloaded with
;    a zero it can be checked to see if variable found
;    edi - if success, edi points to end of varaible stored
; * ----------------------------------------------
find_env_variable:
  mov	ebx,[enviro_ptrs]
fev_10:
  or	ebx,ebx
  jz	fev_50
  mov edi,[ebx]
  or	edi,edi
  jz	near fev_50
  mov	esi,ecx		;get input variable name ptr
  call	str_match
  jne fev_12
  cmp [edi],byte '='
  je fev_20		;jmp if var= found
fev_12:
  add ebx,byte 4
  jmp short fev_10
;
; match found, store it
;
fev_20:
  inc	edi		;move past "="
  mov	esi,edi
  mov	edi,edx
  call	str_move
fev_50:
  ret
;--------------------------------------------------
;  str_match - compare asciiz string to buffer data, use case
; INPUTS
;    esi = string1 (asciiz string)
;    edi = string2 buffer
;    assumes direction flag set to -cld- forward state
; OUTPUT
;    flags set for je or jne
;    esi & edi point at end of strings if match
; * ----------------------------------------------
str_match:
	push	ecx
	call	strlen1			;find length of string1
	repe	cmpsb
	pop	ecx
	ret
;----------------------------------------------------
;  strlen1 - get lenght of esi string
; INPUTS
;    esi = pointer to asciiz string
; OUTPUT
;    ecx = lenght of string
;    all registers restored except for ecx
; * ----------------------------------------------
strlen1:
	push	eax
	push	edi
	cld
	mov	edi,esi
	sub	al,al			;set al=0
	mov	ecx,-1
	repnz	scasb
	not	ecx
	dec	ecx
	pop	edi
	pop	eax
	ret

;---------------------
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
;   If socket_fd is zero this functions connects to
;   x socket.  If the packet lenght is negative a
;   reply is expected and the sequence# is stored
;   for retrevial by x_read_socket
; * ----------------------------------------------
x_send_request:
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
; * ----------------------------------------------
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
x_buf	times x_buf_size db 0
save_eax	dd 0
;-------------------------------------------------------------
  [section .text]
;---------------- list_put_at_end.asm -------------------

struc list
.list_buf_top_ptr resd 1
.list_buf_end_ptr resd 1
.list_entry_size resd 1
.list_start_ptr resd 1
.list_tail_ptr resd 1
endstruc
;---------------------
;>1 list
;  list_put_at_end - add entry to end of list
; INPUTS
;    edx = list control block
;      struc list
;      .list_buf_top_ptr resd 1
;      .list_buf_end_ptr resd 1
;      .list_entry_size resd 1
;      .list_start_ptr resd 1
;      .list_tail_ptr resd 1
;      endstruc
;
;    Initially the control block for a empty
;    list could be set as follows by caller:
;       dd buffer     ;top of buffer
;       dd buffer_end ;end of buffer
;       dd x          ;each entry x bytes long
;       dd buffer     ;first entry ptr
;       dd buffer     ;last entry ptr
;
;    esi = ptr to data of length
;          liss_entry_size
;
; OUTPUT:
;    flag set (jns) if success
;      esi = will be advanced by size of entry
;      edx,ebp unchanged
;    flag set (js) if no room
;      esi,edx,ebp  unchanged 
;
;    if data wraps in buffer, the global
;    [last_buf_put_at_end_adr] will be set        
; NOTES
;   A full list will have a one entry gap
;   between the list_start_ptr and list_tail_ptr.
;   The list pointers cycle around the buffer
;   and entries can be removed from start or
;   end of list.
; * ----------------------------------------------
list_put_at_end:
  call	next_put_at_end	;eax=next stuff  edi=current stuff
  cmp	eax,[edx+list.list_start_ptr]	;room for another entry
  jne	have_room
  mov   eax, -1
  jmp	short list_put_at_end_exit
have_room:
  mov	[edx+list.list_tail_ptr],eax
  mov	ecx,[edx+list.list_entry_size]
  rep	movsb
list_put_at_end_exit:
  or	eax,eax
  ret

;---------------------
; compute next put ptr
;input: edx = control block
;       esi,ebp not available
;output: eax=next ptr ptr
;        edi=current stuff ptr
;
next_put_at_end:
  mov	eax,[edx+list.list_tail_ptr]	;get ptr to last entry
  mov	edi,eax				;save stuff ptr
  add	eax,[edx+list.list_entry_size]	;move ptr forward
  cmp	eax,[edx+list.list_buf_end_ptr]	;beyond end of buffer
  jb	np_exit				;jmp if ok
  mov	eax,[edx+list.list_buf_top_ptr] ;restart put at top of buffer
np_exit:
  ret
;---------------------
;---------------------
  [section .text]
;--------- x_wait_reply -------------


;struc XAnyEvent
;.type		resd	1 ;
;.serial		resd	1 ; # of last request processed by server
;.send_event	resd	1 ; true if this came from a SendEvent request
;.display	resd	1 ; Display the event was read from
;.window		resd	1 ; window on which event was requested in event mask
;endstruc

struc XKeyEvent
.type		resd	1; of event
.serial		resd	1; # of last request processed by server
.send_event	resd	1; true if this came from a SendEvent request
.display	resd	1; Display the event was read from
.window		resd	1;         "event" window it is reported relative to
.root		resd	1;         root window that the event occurred on
.subwindow	resd	1; child window
.time		resd	1; milliseconds
.x		resd	1
.y		resd	1; pointer x, y coordinates in event window
.x_root 	resd	1
.y_root		resd	1; coordinates relative to root
.state		resd	1; key or button mask
.keycode	resd	1; detail
.same_screen	resd	1; same screen flag
endstruc
struc XButtonEvent
.type		resd	1; of event
.serial		resd	1; # of last request processed by server
.send_event	resd	1; true if this came from a SendEvent request
.display	resd	1; Display the event was read from
.window		resd	1;         "event" window it is reported relative to
.root		resd	1;         root window that the event occurred on
.subwindow	resd	1; child window
.time		resd	1; milliseconds
.x		resd	1
.y		resd	1; pointer x, y coordinates in event window
.x_root		resd	1
.y_root		resd	1; coordinates relative to root
.state		resd	1; key or button mask
.button		resd	1; detail
.same_screen	resd	1; same screen flag
endstruc

;---------------------
;>1 server
;  x_wait_reply - wait for xx milliseconds for reply
; INPUTS
;    none 
; OUTPUT:
;    failure - eax=negative error code
;              flags set for js
;           -1=reply read error (buffer error)
;           -2=error packet in buffer
;           -3=reply out of sequence
;           -4=timeout expired or servers in tryagain loop
;           -5=unexpected event while waiting for reply.
;           -6=socket dead
;           -x=all other errors are from kernel
;    success - eax = number of bytes read from server
;              ecx = pointer to reply buffer info.            
;              (see file event_info.inc for buffer data)    
; NOTES
;   source file: x_wait_reply.asm
;   If replies are not pending this function will
;   return an error of -1
;   If reply does not occur within 2 seconds a timeout
;   error will be returned
; * ----------------------------------------------
x_wait_reply:
  mov	edx,list_block
  call	list_check_front
  js	wr_exit		;exit if no reply pending
  mov	eax,2000	;wait for 2 seconds max
  mov	ecx,lib_buf	;buffer
  mov	edx,700		;buffer length
  call	x_read_socket
wr_exit:
  ret


;---------------------
;  list_check_front - check list top, do not remove entry
; INPUTS
;    edx = list control block
;      struc list
;      .list_buf_top_ptr resd 1
;      .list_buf_end_ptr resd 1
;      .list_entry_size resd 1
;      .list_start_ptr resd 1
;      .list_tail_ptr resd 1
;      endstruc
;
; OUTPUT:
;    flag set (jns) if success
;      esi = ptr to data
;      eax = 0
;      edx,ebp unchanged
;    flag set (js) if no data on list
;      eax=-1
;      edx,ebp  unchanged 
;        
; NOTES
;   A full list will have a one entry gap
;   between the list_start_ptr and list_tail_ptr.
;   The list pointers cycle around the buffer
;   and entries can be removed from start or
;   end of list.
; * ----------------------------------------------
list_check_front:
  mov	esi,[edx+list.list_start_ptr]
  cmp	esi,[edx+list.list_tail_ptr]
  jne	have_data
  mov	eax,-1
  jmp	short list_check_front_exit
have_data:
  xor	eax,eax			;set success flag
list_check_front_exit:
  or	eax,eax
  ret
;---------------------
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
;   see file event_info.inc for reply codes
;   This is the low level function used by all other
;   x server packet read functions.  See also,
;   x_wait_event
;   x_wait_reply
;   x_wait_big_reply
;   window_event_decode
; * ----------------------------------------------
x_read_socket:
  mov	[poll_timeout],eax
  mov	[pkt_buf],ecx
  mov	[pkt_buf_length],edx
  mov	[timeout],byte 80
;
  call	x_flush
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

;---------------------
;  list_get_from_front - return entry from top of list
; INPUTS
;    edx = list control block
;      struc list
;      .list_buf_top_ptr resd 1
;      .list_buf_end_ptr resd 1
;      .list_entry_size resd 1
;      .list_start_ptr resd 1
;      .list_tail_ptr resd 1
;      endstruc
;
; OUTPUT:
;    flag set (jns) if success
;      esi = ptr to data
;      edx,ebp unchanged
;    flag set (js) if no data on list
;      edx,ebp  unchanged 
;        
; NOTES
;   source file: list_get_from_front.asm
;   A full list will have a one entry gap
;   between the list_start_ptr and list_tail_ptr.
;   The list pointers cycle around the buffer
;   and entries can be removed from start or
;   end of list.
; * ----------------------------------------------
list_get_from_front:
  mov	esi,[edx+list.list_start_ptr]
  cmp	esi,[edx+list.list_tail_ptr]
  jne	have_data2
  mov	eax,-1
  jmp	short list_get_from_front_exit

have_data2:
;move pointer forward to next entry
  mov	eax,esi
  add	eax,[edx+list.list_entry_size]
  cmp	eax,[edx+list.list_buf_end_ptr]
  jb	update_start_ptr		;jmp if not at end 
  mov	eax,[edx+list.list_buf_top_ptr]	;start at top
update_start_ptr:
  mov	[edx+list.list_start_ptr],eax
  xor	eax,eax			;set success flag
list_get_from_front_exit:
  or	eax,eax
  ret


;----------------------------------------------------  
;   crt_write - display block of data
; INPUTS
;    ecx = ptr to data
;    edx = length of block
; OUTPUT
;   uses current color, see crt_set_color, crt_clear
;  * ---------------------------------------------------
crt_write:
  mov eax, 0x4			; system call 0x4 (write)
  mov ebx,1		; stdout	; file desc. is stdout
  int byte 0x80
  ret

