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


;  [section .text align=1]
;---------- x_list_extension ------------------

;%ifndef DEBUG
  extern x_send_request
  extern x_wait_reply
;%endif
  extern str_move

;---------------------
;>1 server
;  x_list_extension - get list of extensions
; INPUTS
;    none
; OUTPUT:
;    failure - eax = negative error code
;              flags set for "js"
;    success - eax positive read length and flag set "jns"
;              ecx = buffer ptr with
;  resb 1  ;1 Reply
;  resb 1  ;number of names returned
;  resb 2  ;sequence number
;  resb 4  ;reply length
;  resb 24 ;unused
;  resb 1  ;lenght of extension n
;  resb x  ;extension n string

;  resb 1  ;length of extension n+1
;  resb x  ;extension n+1 string
;              
; NOTES
;   source file: x_list_extension.asm
;<
; * ----------------------------------------------

  global x_list_extension
x_list_extension:
  mov	ecx,list_extension_request
  mov	edx,(qer_end - list_extension_request)
  neg	edx		;indicate reply expected
  call	x_send_request
  js	ger_exit
  call	x_wait_reply
ger_exit:
  ret


  [section .data]
list_extension_request:
 db 99	;opcode
 db 0	;unused
 dw 1	;request lenght in dwords
qer_end:

  [section .text]
