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


;---------- xtest_fake_input ------------------

;%ifndef DEBUG
  extern x_send_request
;%endif
  extern query_xtest

;---------------------
;>1 xtest
;  xtest_fake_input - send input to window
; INPUTS
;    al = x code for key to send
;    ah= bit flag
;     80=printable ascii 40=non-printable
;     20=modifier key  10-numlock
;     08-alt 04-ctrl 02-caplock 01-shift
;     (only alt,ctrl,shift are checked here)
; OUTPUT:
;    failure - eax = negative error code
;              flags set for "js"
;    success - eax positive read length and flag set "jns"
;              
; NOTES
;   source file: xtest_fake_input.asm
;<
; * ----------------------------------------------

  global xtest_fake_input
xtest_fake_input:
  mov	[key],al
  mov	[flag],ah
  call	query_xtest
  mov	[fake_input_request],al	;save xtext opcode
  js	xfi_exit

  mov	[fake_input_type],byte 2 ;keypress
  call	do_modifier		;press modifier
  mov	al,[key]
  call	send_key
  js	xfi_exit
  mov	[fake_input_type],byte 3 ;keyrelease
  mov	al,[key]
  call	send_key
  call	do_modifier		;release modifier
xfi_exit:
  ret
;----------------
; inputs: pkt has press/release state set
;
do_modifier:
  test	[flag],byte 8		;alt key
  jz	dm_20			;jmp if no alt key
  mov	al,64			;left alt key = 40h
  call	send_key
dm_20:
  test	[flag],byte 4
  jz	dm_40			;jmp if no ctrl key
  mov	al,37			;left ctrl key = 25h
  call	send_key
dm_40:
  test	[flag],byte 1
  jz	dm_60			;jmp if no shift key
  mov	al,50			;left shift key = 32h
  call	send_key
dm_60:
  ret  


;---------------
; input: al = key to send
;        [fake_input_type] already set in pkt
send_key:
  mov	[fake_input_key],al
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
fake_input_type:
 db 0	;event type 2=keypress 3=keyrelease
fake_input_key:
 db 0
 db 0,0 ;unused
 dd 2	;delay in milliseconds
 dd 0   ;window 0=none
 times 8 db 0 ;unused
 dw 0	;x position for motion fake
 dw 0   ;y position for motion fake
 times 8 db 0
fi_end:

  [section .text]
  [section .text]
