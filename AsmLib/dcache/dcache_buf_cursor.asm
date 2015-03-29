;-------------------------------------------------

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
;   along with this program.  If not, see <http://www.gnu.org/licenses/.


  [section .text align=1]

  extern rowcol_to_index
  extern current_index
;---------------------------------------------------
;>1 dcache
;dcache_buf_cursor - set cursor for next write to buffer
; INPUT
;   ah=row  al=col
; OUTPUT
;   eax = index set
; NOTE
;
;<
;-----------------------------------------------
  global dcache_buf_cursor
dcache_buf_cursor:
  call	rowcol_to_index
  mov	[current_index],eax
  ret

