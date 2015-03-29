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

;---------------------
;>1 keyboard
;  x_change_keyboard_control - change keyboard state
; INPUTS
;    al = auto repeat mode 0=off 1=on
; OUTPUT:
;    failure - eax = negative error code
;              flags set for "js"
;    success - eax =
;              
; NOTES
;   source file: x_change_keyboard_control.asm
;<
; * ----------------------------------------------

  global x_change_keyboard_control
x_change_keyboard_control:
  mov	[ckr_parameter],al
  mov	ecx,change_keyboard_request
  mov	edx,(ckr_end - change_keyboard_request)
  call	x_send_request
  ret


  [section .data]

change_keyboard_request:
 db 102	;opcode -
 db 0	;unused
 dw 3	;request lenght in dwords
 dd 80h	;bit mask 01=click percent
        ;         02=bell percent
        ;         04=bell pitch
        ;         08=bell duration
        ;         10=led
        ;         20=led mode
        ;         40=key
        ;         80=auto repeat mode
ckr_parameter:
 dd 0 ;parameters
ckr_end:

  [section .text]
