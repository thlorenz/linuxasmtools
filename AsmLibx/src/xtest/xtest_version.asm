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
  extern x_wait_reply

;---------------------
;>1 xtest
;  xtest_version - get xtest extension version
; INPUTS
;    none
; OUTPUT:
;    failure - eax = negative error code
;              flags set for "js"
;    success - eax version
;              
; NOTES
;   source file: xtest_version.asm
;<
; * ----------------------------------------------

  global xtest_version
xtest_version:
  call	query_xtest
  mov	[version_request],al ;save xtest opcode
  js	xgc_exit		;exit if error
  mov	ecx,version_request
  mov	edx,(gi_end - version_request)
  neg	edx		;indicate reply expected
  call	x_send_request
  js	xgc_exit
  call	x_wait_reply
  js	xgc_exit
  mov	eax,[ecx+8]	;get version
xgc_exit:
  ret


  [section .data]
version_request:
 db 0	;opcode - xtest
 db 0
 db 2	;sub opcode - get version
 db 0
 db 2
 db 0
 db 2
 db 0
gi_end:

  [section .text]


%ifdef DEBUG

extern x_send_request
extern env_stack
extern x_connect

global _start
_start:
  call	env_stack
  call	x_connect
  call	xtest_version

  mov	eax,01
  int	byte 80h

;-----------

%endif
