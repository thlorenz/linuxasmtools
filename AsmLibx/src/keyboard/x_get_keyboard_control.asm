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


  [section .text align=1]

  extern x_send_request
  extern x_wait_reply

;---------------------
;>1 keyboard
;  x_get_keyboard_control - get keyboard state
; INPUTS
;    none
; OUTPUT:
;    failure - eax = negative error code
;              flags set for "js"
;    success - eax = size of replay
;              ecx = buffer ptr with
;  resb 1  ;Reply
;  resb 1  ;autorepeat status 0=off 1=on
;  resb 2  ;sequence number
;  resb 4  ;led mask
;  resb 1  ;key click percent
;  resb 1  ;bell percent
;  resb 2  ;bell pitch
;  resb 2  ;bell duration
;  resb 2  ;unused
;  resb 32 ;auto repeats
;              
; NOTES
;   source file: x_get_keyboard_control.asm
;<
; * ----------------------------------------------

  global x_get_keyboard_control
x_get_keyboard_control:
  mov	ecx,get_keyboard_request
  mov	edx,(gkr_end - get_keyboard_request)
  neg	edx		;indicate reply expected
  call	x_send_request
  js	gkr_exit
  call	x_wait_reply
gkr_exit:
  ret


  [section .data]

get_keyboard_request:
 db 103	;opcode
 db 0	;unused
 dw 1	;request lenght in dwords
gkr_end:

  [section .text]

  [section .text]
