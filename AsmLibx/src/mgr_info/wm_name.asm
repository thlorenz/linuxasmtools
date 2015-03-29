
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
;---------- wm_name ------------------

  extern x_get_property
  extern lib_buf
;---------------------
;>1 mgr_info
;  wm_name - get property wm_name
; INPUTS
;    eax = window id
; OUTPUT:
;    flag set (jns) if success
;    flag set (js) if err, eax=error code
;
;    if success ecx -> returned packet
;               edi = pointer to name
;               eax = length of name
;              
; NOTES
;   source file: wm_name.asm
;   lib_buf is used as work buffer
;<
; * ----------------------------------------------

  global wm_name
wm_name:
  mov	ecx,lib_buf		;buffer
  mov	edx,700			;buffer length
  mov	esi,39			;atom = WM_NAME (27h)
  mov	edi,0			;atom type
  call	x_get_property
  js	wn_error
  lea	edi,[ecx+32]		;search start address
  xor	eax,eax
  mov	ax,[ecx+16]		;get size of search buf
wn_error:
  ret
