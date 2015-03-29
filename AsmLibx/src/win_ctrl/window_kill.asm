
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
;---------- window_kill ------------------

%include "../../include/window.inc"
  extern x_freegc
  extern x_get_input_focus
  extern x_destroy_window
;---------------------
;>1 win_ctrl
;  window_kill - destroy window
; INPUTS
;  ebp = window block ptr
;
; OUTPUT:
;    error = sign flag set for js
;    success = sign flag set of jns
;              
; NOTES
;   source file: window_kill.asm
;<
; * ----------------------------------------------

  global window_kill
window_kill:

 mov	eax,[ebp+win.s_win_id]
 call	x_destroy_window

;000:<:0012:  8: Request(60): FreeGC gc=0x02e00000
 mov	eax,[ebp+win.s_cid_0]		;xx00000
 call	x_freegc

;000:<:0013:  4: Request(43): GetInputFocus 
  call	x_get_input_focus

  ret

