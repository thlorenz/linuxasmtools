
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

  extern color_id_table

;---------------------
;>1 win_color
;  color_num_lookup - convert color id to color number
; INPUTS
;   eax = color id
;
; OUTPUT:
;   al = color number
;   color numbers 00=white
;                 04=grey
;                 08=skyblue
;                 12=blue
;                 16=navy
;                 20=cyan
;                 24=green
;                 28=yellow
;                 32=gold
;                 36=tan
;                 40=brown
;                 44=orange
;                 48=red
;                 52=maroon
;                 56=pink
;                 60=violet
;                 64=purple
;                 68=black
;              
; NOTES
;   source file: color_num_lookup.asm
;<
; * ----------------------------------------------
  global color_num_lookup
color_num_lookup:
  mov	edi,color_id_table	;ptr to color table
  mov	ecx,18
  repne	scasd			;search for color
  sub	edi,color_id_table
  mov	eax,edi
  sub	al,4
  ret
