
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
;
;>1 math
;  dword_divide - divide 32 bit values
; INPUTS
;   edx,eax divided by ebx;
; OUTPUT:
;   eax = result
;   edx = remainder
; NOTES
;   source file: dword_divide.asm
;   this routine avoids the div error signal
;<
; * ----------------------------------------------
  global dword_divide:
dword_divide:
	cmp	edx,ebx		;added
	jnb	qd_error	;added
	div	ebx
qd_error:
	ret
;--------------------------------

;sample code to test for overflow
;	cmp	dx,bytes_per_sectordivide;
;	jnb	divide_err5divide
;	div	bytes_per_sector		;convert to packet countdivide
