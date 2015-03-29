
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
;---------- activate_window ------------------

  extern x_send_request
  extern root_win_id
  extern atom_NET_ACTIVE_WINDOW
  extern get_windows_desktop
  extern select_desktop
  extern x_get_input_focus
  extern x_flush
  extern delay
;---------------------
;>1 mgr_ctrl
;  activate_window - focus and show window
;     This function switches to desktop containing
;     target window and requests the window manager
;     to focus it and bring it to top.
; INPUTS
;  eax = window id to activate
; OUTPUT:
;    flag set (jns) if success
;    flag set (js) if err, eax=error code
;              
; NOTES
;   source file: activate_window.asm
;<
; * ----------------------------------------------

  global activate_window
activate_window:
  mov	[config_id],eax
  mov	[map_idd],eax
  call	get_windows_desktop
  js	aw_done		;exit if error
  call	select_desktop
  js	aw_done		;exit if error
  mov	ecx,config_pkt
  mov	edx,config_pkt_end - config_pkt
  call	x_send_request
  js	aw_done		;exit if error
  mov	ecx,map_pkt
  mov	edx,map_pkt_end - map_pkt
  call	x_send_request
  js	aw_done		;exit if error

  mov	eax,[config_id]
  call	alternate
  call	x_get_input_focus
aw_done:
  ret
;----------
  [section .data]
config_pkt:
  db 0ch
  db 0
  dw 4 ;length
config_id:
  dd 0
  dw 40h ;stack mode
  dw 0	;unused
  dd 0	;above
config_pkt_end:

map_pkt:
  db 08h
  db 56h
  dw 2	;length
map_idd:
  dd 0
map_pkt_end:

  [section .text]
alternate:
  mov	[activate_id],eax		;save window id
  call	atom_NET_ACTIVE_WINDOW
  mov	[atom],eax
  mov	eax,[root_win_id]
  mov	[wm_root],eax
  mov	ecx,wm_pkt
  mov	edx,wm_pkt_end - wm_pkt
  call	x_send_request
  ret

;-------------------
  [section .data]
;
wm_pkt:
		db 25		;opcode, send event
		db 0		;propagate bool
		dw 11		;request length
wm_root		dd 0		;window id
wm_mask		dd 00180000h	;mask
;event starts here
		db 21h		;ReparentNotify
		db 20h		;window manager kludge
		db 0efh
		db 0b7h
activate_id    	dd 0
atom:		dd 0		;NET_CURRENT_DESKTOP
	       	dd 2		;
                times 16 db 0
wm_pkt_end:
wm_pkt_len	equ $ - wm_pkt
;-----------------


  [section .text]

