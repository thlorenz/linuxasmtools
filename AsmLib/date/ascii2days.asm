
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
;****f* date/ascii2days *
; NAME
;>1 date
;  ascii2days - convert ascii year,month,day to days since 1970
; INPUTS
;    esi = ptr to ascii string "YYYYMMDD"
; OUTPUT
;    eax = binary days since 1970
; NOTES
;   source file: ascii2days.asm
;<
; * ----------------------------------------------
;*******
  extern ascii2regs
  extern regs2days

  [section .text]
  global ascii2days
ascii2days:
  call	ascii2regs
  call	regs2days
  ret
