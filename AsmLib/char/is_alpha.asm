
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

  [section .text align=1]
; NAME
;>1 char
;  is_alpha - check if alpha 20h -> 7eh 
; INPUTS
;    al = ascii char
; OUTPUT
;    eq flag set for je if alpha
; NOTES
;    source file: /char/is_alpha.asm
;<
; * ----------------------------------------------
;*******
  global is_alpha
is_alpha:
  cmp	al,' '
  jb	not_alph
  cmp	al,7eh
  ja	not_alph
  cmp	al,al
not_alph:
  ret
