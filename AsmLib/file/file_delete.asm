
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

;****f* file/file_delete *
; NAME
;>1 file
;  file_delete - delete file
; INPUTS
;    ebx = path of file to delete
; OUTPUT
;    eax = negative error# if problem
; NOTES
;   source file: file_delete.asm
;   kernel: unlink(10)
;<
; * ----------------------------------------------
;*******
  global file_delete
file_delete:
  mov	eax,10
  int	80h
  or	eax,eax
  ret
