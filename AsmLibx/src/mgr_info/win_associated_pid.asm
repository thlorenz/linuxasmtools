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
;---------- win_associated_pid ------------------

  extern x_get_property
  extern lib_buf
  extern x_wait_reply
  extern root_win_id
  extern x_interatom
  extern atom_NET_WM_PID
;---------------------
;>1 mgr_info
;  win_associated_pid - get pid (program) for window
; INPUTS
;    eax =  window id
; OUTPUT:
;    flag set (jns) if success
;    flag set (js) if err, eax=error code
;
;    if success eax = pid
;              
; NOTES
;   source file: win_associated_pid.asm
;   lib_buf is used as work buffer
;<
; * ----------------------------------------------

  global win_associated_pid
win_associated_pid:
  mov	[window_id],eax
  call	atom_NET_WM_PID
  or	eax,eax
  js	wn_error
  mov	esi,eax
;get property net_wm_active_win
nwaw_40:
  mov	eax,[window_id]	;
  mov	ecx,lib_buf		;buffer
  mov	edx,700			;buffer length
  mov	edi,6			;atom type
  call	x_get_property
  js	wn_error
  mov	eax,[ecx+32]		;get pid
wn_error:
  ret
;------------
  [section .data]
window_id: dd 0
  [section .text]


%ifdef DEBUG

extern x_send_request
extern env_stack
extern x_connect

global _start
_start:
  call	env_stack
  call	x_connect
  call	win_associated_pid

  mov	eax,01
  int	byte 80h

;-----------

%endif
