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

  extern query_xtest
  extern x_send_request


;---------------------
;>1 xtest
;  xtest_grab_control - set server "grab" status
; INPUTS
;    al = flag 0=susceptable 1=impervious to grabs
; OUTPUT:
;    failure - eax = negative error code
;              flags set for "js"
;    success - eax positive read length and flag set "jns"
;              
; NOTES
;   source file: xtest_grab_control.asm
;<
; * ----------------------------------------------

  global xtest_grab_control
xtest_grab_control:
  mov	[grab_input_flag],al
  call	query_xtest
  mov	[grab_input_request],al ;save xtest opcode
  js	xgc_exit		;exit if error
  mov	ecx,grab_input_request
  mov	edx,(gi_end - grab_input_request)
  call	x_send_request
xgc_exit:
  ret


  [section .data]
grab_input_request:
 db 0	;opcode - xtest
 db 3	;sub opcode - grab input
 dw 2	;request lenght in dwords
grab_input_flag:
 db 0	;event type 0=susceptable 1=impervious
 db 0,0,0 ;filler
gi_end:

  [section .text]

  [section .text]
