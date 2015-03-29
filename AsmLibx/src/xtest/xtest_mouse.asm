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


;---------- xtest_move_mouse ------------------

;%ifndef DEBUG
  extern x_send_request
;%endif
  extern query_xtest
  extern xtest_version

;---------------------
;>1 xtest
;  xtest_move_mouse - move mouse pointer
; INPUTS
;    ax = x position (pixel column)
;    bx = y position (pixel row)
; OUTPUT:
;    failure - eax = negative error code
;              flags set for "js"
;    success - eax positive read length and flag set "jns"
;              
; NOTES
;   source file: xtest_mouse.asm
;<
; * ----------------------------------------------

  global xtest_move_mouse
xtest_move_mouse:
  mov	[x_col],ax
  mov	[y_row],bx
  mov	[fake_event_type],byte 6 ;move mouse
  call	query_xtest
  jc	xtm_exit
  mov	[fake_input_request],al
  call	xtest_version
  call	send_request
xtm_exit:
  ret

;---------------------
;>1 xtest
;  xtest_click - send input to window
; INPUTS
;    al = button type 1=left 2=center 3=right
; OUTPUT:
;    failure - eax = negative error code
;              flags set for "js"
;    success - eax positive read length and flag set "jns"
;              
; NOTES
;   source file: xtest_mouse.asm
;<
; * ----------------------------------------------

  global xtest_click
xtest_click:
  mov	[fake_event],al
  call	query_xtest
  jc	xc_exit
  mov	[fake_input_request],al	;set extension op code
  mov	[fake_event_type],byte 4 ;button down
  call	send_request
  jc	xc_exit
  mov	[fake_event_type],byte 5 ;button up
  call	xtest_version
  call	send_request
xc_exit:
  ret


;---------------
; input: al = key to send
;        [fake_input_type] already set in pkt
send_request:
  mov	ecx,fake_input_request
  mov	edx,(fi_end - fake_input_request)
  call	x_send_request
  ret  

;------------------------------------------------
  [section .data]
key	db 0
flag	db 0

fake_input_request:
 db 0	;opcode - xtest
 db 2	;sub opcode - fake input
 dw 9	;request lenght in dwords
fake_event_type:
 db 0	;event type 2=keypress 3=keyrelease
        ;           4=click dn 5=click up 6=move
fake_event:
 db 0	;0 if move else 1=left 2=mid 3=right
 db 0,0 ;unused
 dd 2	;delay in milliseconds
 dd 0   ;window 0=none
 times 8 db 0 ;unused
x_col:
 dw 0	;x position for motion fake
y_row:
 dw 0   ;y position for motion fake
 times 8 db 0
fi_end:

  [section .text]

%ifdef DEBUG

extern x_send_request
extern env_stack
extern x_connect
extern x_flush

global _start
_start:
  call	env_stack
  call	x_connect
  mov	ax,1428
  mov	bx,215
  call	xtest_move_mouse
  call	x_flush
  mov	al,1		;left click
  call	xtest_click
  call	x_flush

  mov	eax,01
  int	byte 80h
%endif

  [section .text]
