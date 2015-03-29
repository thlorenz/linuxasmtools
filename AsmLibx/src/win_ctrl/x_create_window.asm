
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
;---------- x_create_window ------------------

%ifndef DEBUG
  extern x_send_request
%endif

;---------------------
;>1 win_ctrl
;  x_create_window - create window within server
;    (window can be displayed with x_map_windoe)
; INPUTS
;  esi = pointer to block
;     cw_wid		dd 0    ;window id to create, 2a00001h
;     cw_parent 	dd 0    ;parent window id, 63
;     cw_x:		dw 0    ;pixel column adr
;     cw_y:		dw 0    ;pixel row adr
;     cw_width          dw 0    ;pixel width
;     cw_height: 	dw 0    ;lixel height
;     cw_background_color dd 0
; OUTPUT:
;    flag set (jns) if success
;    flag set (js) if err, eax=error code
;    [sequence] - sequence number of packet sent
;              
; NOTES
;   source file: x_create_window.asm
;<
; * ----------------------------------------------

  global x_create_window
x_create_window:
  mov	edi,cw_wid
  mov	ecx,4
  rep	movsd
  mov	edi,cw_value
  movsd			;store background color
%ifdef DEBUG
  mov	ecx,cw_msg
  call	crt_str
%endif
  mov	ecx,cw_pkt
  mov	edx,cw_pkt_end - cw_pkt
  call	x_send_request
  ret

;-------------------
  [section .data]
%define KeyPressMask			1
%define ButtonPressMask			4
%define ExposureMask			0x8000
cw_pkt:
		db 1		;opcode, create_window
		db 0		;depth
		dw cw_pkt_len / 4
cw_wid		dd 0		;window id to create, 2a00001h
cw_parent 	dd 0		;parent window id, 63
cw_x:		dw 0
cw_y:		dw 0
cw_width 	dw 0
cw_height: 	dw 0
cw_border_width: dw 0
cw_class 	dw 0		;0=CopyFromParent 1=InputOutput 2=InputONly
cw_visual 	dd 0		;0=CopyFromParent
cw_mask  	dd 2 | 8 | 800h	;background pixel + border-pixel
cw_value 	dd 0000ffffh	;background pixel
		dd 0		;border pixel
		dd 1 + 4 + 8000h
cw_pkt_end:
cw_pkt_len	equ $ - cw_pkt
;-----------------


%ifdef DEBUG
cw_msg: db 0ah,'create_window (0fh)',0ah,0
%endif
  [section .text]
