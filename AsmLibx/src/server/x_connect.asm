
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
  extern wait_event
  extern bit_test
  extern enviro_ptrs
  extern env_home
  extern poll_socket
  extern find_env_variable
  extern x_buf
  extern x_buf_size2

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
;>1 server
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
;          x_buf has connection reply
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
;        
; NOTES
;   source file: x_connect.asm
;<
; * ----------------------------------------------

  global x_connect
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
  mov   esi, x_buf
  cmp	byte [esi],1
  je	x_conn_ok
  mov	eax,-1
  jmp	short err
x_conn_ok:
;save data from connnecton reply
  mov	edi,c_reply_code
  mov	esi,x_buf
  mov	ecx,(c_max_keycode+1) - c_reply_code
  rep	movsb

  mov	esi,x_buf+connect_reply_len
  mov	ecx,4
  rep	movsb

;compute index to first screen struc
  xor	eax,eax
  mov	ax,[x_buf+connect_reply.format_cnt]
  shl	eax,3		;multilpy by 8
  add	eax,connect_reply_len ;move to start of screen struc
  add	eax,x_buf	;add in buffer start
  mov	esi,eax
  mov	ecx,36
  rep	movsb
  mov	ecx,c_reply_code
err:
  ret
;--------------
  [section .data]
  global connection_reply_length
connection_reply_length: dd 0
  global socket_fd
socket_fd:
xfd_array: dd 0,-1
  global x_id_base


 global x_id_base,c_id_mask,c_max_req_size
 global c_min_keycode,c_max_keycode
 global root_win_id,root_win_pix_width,root_win_pix_height
 global root_win_color_map

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

  mov eax,3		;kernel read functin
  mov ecx, x_buf
  mov edx, 700		;x_buf_len
  int byte 80h		;read file
  or	eax,eax
  js	gx_exit			;exit if error
  push	eax			;save amount read
  mov eax,6			;close kernel function
  int byte 80h
  pop	eax			;restore amount read
  mov	edx,ecx			;compute end
  add	edx,eax			;  of .Xauthority
auth_scan:
  call	parse_auth
  jecxz	no_auth			;exit if error
  mov	al,[display_number]
  cmp	al,[auth_display]
  jne	auth_scan
; copy authorization proto name and data
; to connect request data packet
  movzx	ecx,byte [auth_mit_len]
  mov	[conn_request.proto_str_len], cx
  mov	esi,[auth_mit_ptr]
  mov edi, conn_request.proto_str
  rep movsb
  inc esi
  add edi,byte 3       ; round up for "pad"
  and edi,byte  -4

  movzx ecx,byte [auth_cookie_len]
  mov [conn_request.proto_data_len], cx
  mov	esi,[auth_cookie_ptr]
  rep movsb
  sub edi, conn_request
  add edi,byte 3
  and edi,byte -4
  mov [conn_request_length], edi
  xor	eax,eax		;set good return
  jmp	short gx_exit
no_auth:
  or	eax,byte -1	;set error flag
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

;------------------------------------------------
  [section .text]

;input ecx=ptr to contents of .Xauthority file
;      edx=ptr to end of .Xauthority file
;output: ecx=next Xauthority entry ptr
;        database set (auth_display,auth_mit_len, etc)
;
parse_auth:
  movzx	eax,byte [ecx+3]	;get host name length
  lea	ecx,[ecx+eax+5]		;get ptr to display name len
  movzx	ebx,byte [ecx+1]	;get display name
  mov	[auth_display],bl	;save display name
  movzx	eax,byte [ecx]		;get length of display name
  lea	ecx,[ecx+eax+2]		;move to MIT string length
  movzx eax,byte [ecx]		;get lenght of MIT string
  mov	[auth_mit_len],al	;save MIT length
  inc	ecx
  mov	[auth_mit_ptr],ecx	;save ptr to MIT string
  lea	ecx,[ecx+eax+1]		;get ptr to cookie length
  movzx	eax,byte [ecx]		;get cookie length
  mov	[auth_cookie_len],al	;save cookie len
  inc	ecx
  mov	[auth_cookie_ptr],ecx	;save ptr to cookie  
  lea	ecx,[ecx+eax]		;get ptr to next entry
  cmp	ecx,edx			;at end of .Xauthority
  jbe	pa_ok			;jmp if next ptr ok
  xor	ecx,ecx			;set error exit
pa_ok:
  ret
;-------------------  
  [section .data]

auth_display	db 0	;display from auth "0" usually
auth_mit_len	db 0	;length of MIT-MAGIC string
auth_mit_ptr	dd 0	;ptr to MIT string
auth_cookie_len db 0	;length of cookie
auth_cookie_ptr dd 0	;ptr to cookie


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
  mov ecx, x_buf
  mov edx, x_buf_size2	;x_buf_len
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

;------------------------------
;  extern sys_exit
;  extern env_stack

;  global main,_start
;main:
;_start:
;  call	env_stack
;  call	x_connect
;  js	exit1
;  nop
;exit1:
;  call	sys_exit




