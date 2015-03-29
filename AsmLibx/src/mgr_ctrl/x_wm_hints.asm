
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
;---------- x_wm_hints ------------------

  extern x_send_request


;---------------------
;>1 mgr_ctrl
;  x_wm_hints - send window size to manager
; INPUTS
;  eax = window id
;  esi = pointer to block
;     cw_x:		dw 0    ;pixel column adr
;     cw_y:		dw 0    ;pixel row adr
;     cw_width          dw 0    ;pixel width
;     cw_height: 	dw 0    ;lixel height
; OUTPUT:
;    flag set (jns) if success
;    flag set (js) if err, eax=error code
;    [sequence] - sequence number of packet sent
;              
; NOTES
;   source file: x_wm_hints.asm
;<
; * ----------------------------------------------

  global x_wm_hints
x_wm_hints:
;  mov	eax,[ebp+win.s_win_id]
  mov	[wm_wid],eax
  mov	edi,wm_x
  movsw
  add	edi,byte 2
  movsw
  add	edi,byte 2
  movsw
  add	edi,byte 2
  movsw
  mov	ecx,wm_pkt
  mov	edx,wm_pkt_end - wm_pkt
  call	x_send_request
  ret

;-------------------
  [section .data]
;
; note: this packet needs the 10 dword filler at
; end for some strange reason?  It also needs the entry
; count of 0fh?
;
wm_pkt:
		db 18		;opcode, change property
		db 0		;mode=replace
		dw wm_pkt_len / 4
wm_wid		dd 0		;window id to create, 2a00001h
wm_atom1 	dd 28h		;WM_NORMAL_HINTS
wm_atom2 	dd 29h		;type = WM_SIZE_HINTS
		dd 20h		;format
wm_entry_count  dd 0fh
wm_flag		dd 0ch		;		
wm_x:		dd 0
wm_y:		dd 0
wm_width 	dd 0
wm_height: 	dd 0
		times 10 dd 0	;filler
wm_pkt_end:
wm_pkt_len	equ $ - wm_pkt
;-----------------


  [section .text]
