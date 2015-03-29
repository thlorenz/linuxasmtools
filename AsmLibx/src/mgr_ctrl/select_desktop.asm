
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
;---------- select_desktop ------------------

%ifndef DEBUG
  extern x_send_request
%endif
  extern root_win_id
  extern atom_NET_CURRENT_DESKTOP
;---------------------
;>1 mgr_ctrl
;  select_desktop - send desktop select to window manager
; INPUTS
;  eax = desktop number
; OUTPUT:
;    flag set (jns) if success
;    flag set (js) if err, eax=error code
;              
; NOTES
;   source file: select_desktop.asm
;<
; * ----------------------------------------------

  global select_desktop
select_desktop:
  mov	[desktop],eax		;save number of desktp
  call	atom_NET_CURRENT_DESKTOP
  mov	[_atom],eax
  mov	eax,[root_win_id]
  mov	[sd_root],eax
  mov	[target_root_win],eax
  mov	ecx,sd_pkt
  mov	edx,sd_pkt_end - sd_pkt
  call	x_send_request
  ret

;-------------------
  [section .data]
;
sd_pkt:
		db 25		;opcode, send event
		db 0		;propagate bool
		dw 11		;request length
sd_root		dd 0		;window id
sd_mask		dd 00180000h	;mask
;event starts here
		db 21h		;ReparentNotify
		db 20h		;window manager kludge
		db 04h
		db 08h
target_root_win	dd 0
_atom:		dd 0		;NET_CURRENT_DESKTOP
desktop:	dd 0		;desktop
                times 16 db 0
sd_pkt_end:
sd_pkt_len	equ $ - sd_pkt
;-----------------


  [section .text]

