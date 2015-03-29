
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
;  color_id_lookup - color number to color id
;  Colors id's are pre built by window_pre in
;  a table that can be indexed by color number.
; INPUTS
;   eax = color number
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

; OUTPUT:
;   eax = color id
;              
; NOTES
;   source file: color_id_lookup.asm
;<
; * ----------------------------------------------

  global color_id_lookup
color_id_lookup:
  mov	eax,[color_id_table + eax]
  ret

  [section .text]

