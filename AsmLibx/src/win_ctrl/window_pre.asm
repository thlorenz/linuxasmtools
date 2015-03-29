
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
;---------- window_pre ------------------

  extern root_win_pix_width
  extern root_win_pix_height
  extern root_win_color_map
  extern x_id_base
  extern root_win_id
  extern x_connect
  extern x_create_gc
  extern x_wait_big_reply
  extern x_create_window
  extern x_map_win
  extern x_create_gc
  extern x_change_gc_font
  extern x_get_input_focus
%ifndef DEBUG
%include "../../include/window.inc"
%endif
  extern window_font
  extern x_send_request
  extern root_win_color_map
  extern x_change_attributes
  extern x_allocate_named_color
  extern x_get_window_attributes
  extern x_query_font
  extern str_move
  extern x_wait_reply
  extern key_translate_table
  extern x_get_keyboard_mapping
  extern delay
  extern c_min_keycode
  extern c_max_keycode
  extern x_wait_event



;---------------------
;>1 win_ctrl
;  window_pre - setup for window_create
;   Clears the input buffer, connects to the
;   x server if necessary, then fills in
;   parts of the input_block (ebp).
; INPUTS
;  env_stack -  needs to be called at top of
;               program using window_pre function.
;  ebp = buffer to hold win block (input block)
;  eax = work buffer of size 24000+
;  edx = work buffer size
;  ecx = color number (see window_pre)
;  ebx = font width in pixels, 8,9,etc.
;   
; OUTPUT:
;    error = sign flag set for "js" instruction
;    success, win block built (see file window.inc)
;
;    The following win block fields are useful for
;    window_create setup.
;
;     .s_root_width    resd 1 ;root width in pixels
;     .s_root_height   resd 1 ;root height in pixels
;     .s_char_width resd 1
;     .s_char_height resd 1
;
; NOTES
;   This function provides the initial id to use
;   as a base for assigning future id's.
;
;   Also, it provides the root window size which can
;   be used to size window requests.  We can't exceed
;   the root widow size, but we can make smaller
;   windows
;
;   If sucessful, the window is created with keyboard,
;   mouse, and exposure events enabled.  The background
;   color, size, and window position will be set.
;   
;   source file: window_pre.asm
;<
; * ----------------------------------------------

  global window_pre
window_pre:
  mov	[wp_buf],eax
  mov	[wp_buf_size],edx
  mov	[the_color],ecx
;clear the win block
  mov	edi,ebp			;get control block adr
  xor	eax,eax
  mov	ecx,win_struc_size
  rep	stosb			;clear control block
;save font width
  mov	[ebp+win.s_font],ebx

  mov	eax,[x_id_base]		;check if already connected
  or	eax,eax
  jz	wp_05			;jmp if not connected yet
  add	eax,100000h
  mov	[x_id_base],eax
  jmp	short wp_10

wp_05:
  call	x_connect
  jns	wp_10
  jmp	wc_exit
wp_10:
;    flag set (jns) if success
;      and [socket_fd] global set to socket fd (dword)
;          [x_id_base] base for id assign
;          [root_win_id] set (dword)
;          [root_win_pix_width] set (dword)
;          [root_win_pix_height] set (dword)
;    flag set (js) if err, eax=error code
;        
  mov	ax,[root_win_pix_width]
  mov	[ebp+win.s_root_width],ax

  mov	ax,[root_win_pix_height]
  mov	[ebp+win.s_root_height],ax

  mov	eax,[root_win_color_map]
  mov	[ebp+win.s_map_id],eax
;
; get a initial gc --------------------------------
;
;000:<:0001: 20: Request(55): CreateGC cid=0x02a00000 drawable=0x00000063  values={background=0x0000ffff}
  mov	eax,[x_id_base]	;cid (id to create)
  mov	[ebp+win.s_cid_0],eax
  push	eax

  mov	ebx,[root_win_id] ;root window id
  mov	[ebp+win.s_root],ebx

  mov	esi,cid0_values
  call	x_create_gc	;no return is expected
;
;fill in other gc's
;
  pop	eax
  inc	eax
  mov	[ebp+win.s_win_id],eax	;window id
  inc	eax
  mov	[ebp+win.s_cid_1],eax	;color id
  inc	eax
  mov	[ebp+win.s_font_id],eax	;font id

;setup colors
  call	color_setup
  js	wc_exit
  call	build_key_table
;setup background color
  mov	ecx,[the_color]
  add	ecx,color_id_table	;get color id
  mov	ebx,[ecx]
  mov	[cw__background_color],ebx

;
;000:<:0007: 40: Request(1): CreateWindow depth=0x00 window=0x02e00001 parent=0x00000063 x=0 y=0 width=480
; height=300 border-width=2 class=CopyFromParent(0x0000) visual=CopyFromParent(0x00000000)
;  value-list={background-pixel=0x0000ffff border-pixel=0x00000000}
  
  mov	eax,[ebp+win.s_root]
  mov	[cw_root_win_id],eax

  mov	eax,[ebp+win.s_win_id]
  mov	[cw_our_win],eax

;  mov	eax,[root_win_pix_width]
;  mov	[cw__width],eax

  mov	esi,cw_block
  call	x_create_window	;no reply is expected
  js	wc_exit

;000:<:0009: 16: Request(55): CreateGC cid=0x02e00002 drawable=0x02e00001  values={}

  mov	ebx,[ebp+win.s_win_id]	;our window id
  mov	eax,[ebp+win.s_cid_1]	;color id xx00002
  mov	esi,cid1_values
  call	x_create_gc	;no return is expected
  js	wc_exit

;000:<:000d: 32: Request(45): OpenFont fid=0x02e00003  name='*-helvetica-*-12-*'
  mov	eax,[wp_buf]		;get work buffer
  mov	edx,[wp_buf_size]	;buffer size
  call	window_font
  js	wc_exit

;  mov	eax,800h		;event mask bit
;  mov	ebx,1+4+8000h		;keypress + button press + exposure
;  mov	ecx,[ebp+win.s_win_id]	;get window 
;;  call	x_change_attributes
;  js	wc_exit
wc_exit:
  ret

;--------------
  [section .data]
cid0_values:
  dd	8		;background
  dd	0000ffffh	;background color

wp_buf		dd 0
wp_buf_size	dd 0

  [section .text]
;---------------------------------------------------
  [section .data]
;---------------------------------------------------

struc anc_reply
  resb 1 ;reply code
  resb 1 ;unused
  resw 1 ;sequence#
  resd 1 ;reply length
.pixel:
  resd 1 ;color code
  resw 1 ;red
  resw 1 ;green
  resw 1 ;blue
  resw 1 ;visual red
  resw 1 ;visual green
  resw 1 ;visual blue
endstruc

  [section .text]
;-------------------------------------------------------------------

color_setup:
;find color map id for our window
;  mov	eax,[ebp+win.s_win_id]
;  call	x_get_window_attributes
;  mov	eax,[ecx+28]		;get color map
  mov	eax,[root_win_color_map]
  mov	[ebp+win.s_map_id],eax
  mov	[anc_color_map],eax	;setup packet
 
;request all color codes
  mov	esi,color_table
  mov	edi,[wp_buf]		;storage for color requests
color_loop1:
  push	esi
  push	edi
  call	send_pkt	;in,esi=colorptr out, ecx=pkt length
  pop	edi
  pop	esi		;restore color_table ptr
  js	color_setup_exit ;exit if error
;scan to next color in table
next_color:
  lodsb
  or	al,al
  jnz	next_color
  cmp	byte [esi],0	;end of table
  jne	color_loop1

;read replies and set colors

  mov	edi,color_id_table	;stuff location
  mov	ecx,18			;number of expected replies
color_loop2:
  push	ecx
  push	edi
  call	x_wait_reply
  mov	eax,[ecx+anc_reply.pixel]
  pop	edi
  pop	ecx
  stosd
  js	color_setup_exit
  loop	color_loop2

color_setup_exit:
  ret
;------------------------------------------------------------
;input: esi = color ptr
;output: if "jns" then
;        packet at allocate_named_color_request
;        ecx = packet lenght
;        else, error
send_pkt:
  mov	edi,anc_string
  call	str_move	;move sting
  sub	edi,allocate_named_color_request ;compute length of pkt
  mov	edx,edi				;length in ecx
;compute string length
  sub	edi,12				;remove pkt top
  mov	eax,edi
  mov	[anc_name_len],ax
anc_00:
  test	dl,3				;dword boundry?
  je	anc_10				;jmp if on boundry
  inc	edx
  jmp	short anc_00
anc_10:
  mov	eax,edx
  shr	eax,2
  mov	[anc_pkt_len],ax
;send packet
  mov	ecx,allocate_named_color_request
  neg	edx			;indicate reply is expected
  call	x_send_request
  ret
;-----------------------------------------------------------

build_key_table:
  mov	eax,[wp_buf]
  call	x_get_keyboard_mapping
;determine start of map
  mov	edi,key_translate_table	;starts with entry 8
  mov	esi,[wp_buf]
  mov   cl,byte [c_min_keycode];first map key# to process
  mov	ch,8			;first table entry
  movzx ebx,byte [esi+1]	;get num. dwords per map entry
  shl	ebx,2			;make byte count per map entry
  add	esi,32			;move to first map entry
bkt_lp1:
  cmp	cl,ch			;table and map in sync?
  je	bkt_10			;jmp if at start point
  ja	move_tp
;move map ptr
  add	esi,ebx
  inc	cl
  jmp	short bkt_lp1
;move table ptr
move_tp:
  add	edi,3
  inc	ch
  jmp	short bkt_lp1

;cl,ch = current key, esi=map ptr  edi=table ptr ebx=map entry size
;map format = dd norm-char  dd shifted-char
;table format = db flag, db norm-char  db shift-char
bkt_10:
bkt_lp2:
  movzx	edx,word [esi]		;get map entry
  or	edx,edx
  jz	bkt_null		;jmp if zero entry
  test	edx,0ffffff00h		;check if special char
  jnz	bkt_non_ascii
  mov	al,40h			;set non printable ascii flag bit
  mov	dh,[esi+4]		;get shifted ascii
;check if ascii in dl,dh is printable
  cmp	dl,' '
  jb	bkt_tail		;jmp if non printable ascii
  cmp	dl,7eh
  ja	bkt_tail           	;jmp if non printable ascii
  mov	al,80h
  jmp	short bkt_tail		;jmp if printable ascii

bkt_non_ascii:
  mov	al,40h			;flag
  or	dl,dl
  jnz	bkt_ctrl		;jmp if code provided
  mov	dl,cl			;use x-code for char
  mov	dh,cl			;use x-code for char
  jmp	short bkt_ctrl2
;non ascii control char
bkt_ctrl:
  mov	dh,dl
bkt_ctrl2:
  cmp	dl,0e0h
  jb	bkt_tail
  cmp	dl,0f0h
  ja	bkt_tail
  or	al,20h			;set ignore flag (meta key)
  jmp	short bkt_tail
;make null entry, set al=flag dl=norm char dh=shifted char
bkt_null:
  xor	eax,eax
  xor	edx,edx
bkt_tail:
  stosb				;store flag
  mov	al,dl
  stosb				;store norm char
  mov	al,dh
  stosb				;store shifted char
  add	esi,ebx			;move map ptr

  inc	cl			;bump char#
  cmp	cl,byte [c_max_keycode]	;cmp to last map key#
  jb	bkt_lp2			;loop till done
  xor	eax,eax
  jmp	short bkt_exit 
bkt_err:
  mov	eax,-1
bkt_exit:
  or	eax,eax
  ret
;-----------------------------------------------------------
  [section .data]
allocate_named_color_request:
 db 85	;opcode
 db 0	;unused
anc_pkt_len:
 dw 2	;request lenght in dwords
anc_color_map:
 dd 0
anc_name_len:
 dw 0
 dw 0		;unused
anc_string:
  times 16 db 0


the_color dd 0	;pointer to background color

; input block for create_window
;
cw_block:
cw_our_win:		dd 0       ; wid (has to be calculated)
cw_root_win_id:		dd 0       ; parent (has to be calculated)
cw__x	  		dw 0       ; x
cw__y	  		dw 0       ; y
cw__width  		dw 8     ; width
cw__height 		dw 8     ; height
cw__background_color	dd 0
cw__bordor_color	dd 0

cid1_values:
  dd	0		;no values

color_table:
  db	'white',0
  db	'grey',0
  db	'skyblue',0
  db	'blue',0
  db	'navy',0
  db	'cyan',0
  db	'green',0
  db	'yellow',0
  db	'gold',0
  db	'tan',0
  db	'brown',0
  db	'orange',0
  db	'red',0
  db	'maroon',0
  db	'pink',0
  db	'violet',0
  db	'purple',0
  db	'black',0
  db	0		;end of table


  global color_id_table
  global _white,_grey,_skyblue,_blue
  global _navy,_cyan,_green,_yellow
  global _gold,_tan,_brown,_orange
  global _red,_maroon,_pink,_violet
  global _purple,_black

color_id_table:
_white		dd 0	;00
_grey		dd 0	;04
_skyblue	dd 0	;08
_blue		dd 0	;12
_navy		dd 0	;16
_cyan		dd 0	;20
_green		dd 0	;24
_yellow		dd 0	;28
_gold		dd 0	;32
_tan		dd 0	;36
_brown		dd 0	;40
_orange		dd 0	;44
_red		dd 0	;48
_maroon		dd 0	;52
_pink		dd 0	;56
_violet		dd 0	;60
_purple		dd 0	;64
_black		dd 0	;68

  [section .text]

