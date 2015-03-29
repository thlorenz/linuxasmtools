
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
;---------- wm_class ------------------

  extern x_get_property
  extern lib_buf
;---------------------
;>1 mgr_info
;  wm_class - get property wm_class
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
;   source file: wm_class.asm
;   lib_buf is used as work buffer
;<
; * ----------------------------------------------

  global wm_class
wm_class:
  mov	ecx,lib_buf		;buffer
  mov	edx,700			;buffer length
  mov	esi,67			;atom = WM_CLASS (43h)    
  mov	edi,31			;atom type (1fh)
  call	x_get_property
  js	wc_error
  lea	edi,[ecx+32]		;search start address
  xor	eax,eax
  mov	ax,[ecx+16]		;get size of search buf
wc_error:
  ret
