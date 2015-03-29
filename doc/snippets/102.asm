; socket example:
;

  global _start
_start:

 call	x_connect
 call	x_disconnect

  mov	eax,1
  int	byte 80h

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


  extern wait_event
  extern bit_test
  extern enviro_ptrs
  extern env_home
  extern lib_buf
  extern find_env_variable

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
;    none
; OUTPUT:
;    flag set (jns) if success
;      and [socket_fd] global set to socket fd (dword)
;          [x_id_base] base for id assign (dword)
;          [root_win_id] set (dword)
;          [root_win_pix_width] set (word)
;          [root_win_pix_height] set (word)
;          [root_win_color_map] set (dword)
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
  js	c_exitj
  mov [socket_fd2],eax
  mov [socket_fd],eax
; connect to it
  mov	eax,102		;socket kernel function
  mov	ebx,3		;connect
  mov	ecx,socket_connect_blk
  int	byte 80h
  or	eax,eax
  js	c_exitj
; make the socket non-blocking
  mov ebx, [socket_fd]
  mov ecx, 3		;F_GETFL (get flags)
  mov eax,55		;fcntl
  int byte 0x80
  or	eax,eax
c_exitj:
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



;---------------------
;  x_disconnect - disconnect from x server
; INPUTS
;  [socket_fd] - global set by x_connect

; OUTPUT:
;   "js" flag set if error
;              
; NOTES
;   source file: x_disconnect
; * ----------------------------------------------

  global x_disconnect
x_disconnect:
  mov	ebx,[socket_fd]
  mov	eax,6
  int	byte 80h
  or	eax,eax
  ret


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
; NOTES
;    source file: poll_socket.asm
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


;-----------------
  [section .data]



