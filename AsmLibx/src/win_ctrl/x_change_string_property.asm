
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
;---------- x_change_string_property ------------------

  extern x_send_request
  extern str_move

;---------------------
;>1 win_ctrl
;  x_replace_string_property - change a window property
; INPUTS
;    ebp = window block
;    eax = window id
;    ebx = property atom 39=WM_NAME (appears on title bar)
;                        37=WM_ICON_NAME
;                        24=WM_CLASS
;                        22=WM_COMMAND
;                      0x128=WM_LOCALE_NAME
;    esi = string ptr
;
; OUTPUT:
;    flags set for jns-success  js-error
;              
; NOTES
;   source file: x_change_string_property.asm
;<
; * ----------------------------------------------

  global x_change_string_property
x_change_string_property:
  mov	[csp_window],eax	;save window id
  mov	[csp_property],ebx	;save property

  mov	edi,csp_string
  call	str_move	;move sting
  sub	edi,change_string_property_request ;compute length of pkt
  mov	edx,edi				;length in edx
;compute string length
  sub	edi,byte 24			;remove pkt top
  mov	[csp_name_len],edi

csp_00:
  test	dl,3				;dword boundry?
  je	csp_10				;jmp if on boundry
  inc	edx
  jmp	short csp_00
csp_10:
  mov	eax,edx
  shr	eax,2
  mov	[csp_pkt_len],ax

  mov	ecx,change_string_property_request
;  mov	edx,change_string_property_request_len
  call	x_send_request
csp_exit:
  ret

  [section .data]
change_string_property_request:
 db 18	;opcode
 db 0	;mode 0=replace 1=prepend 2=append
csp_pkt_len:
 dw 2	;request lenght in dwords
csp_window:
 dd 0
csp_property:
 dd 0	;atom
 dd 1fh ;type atom 1fh=string
 db 8	;format
 db 0,0,0 ; unused
csp_name_len:
 dd 0	  ;n/4 may have padding at end
csp_string:
  times 30 db 0


  [section .text]

