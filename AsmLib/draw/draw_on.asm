
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
  extern crt_str
;-----------------------------------------------------
;>1 draw
; draw_on - enable line drawing characters
; inputs:
;    none
; outputs:
;    none
; notes:
;   source file  draw_on.asm
;
;If draw_on is called, the character map changes as follows:
;
;    ASCII      Special                  ASCII     Special
;   graphic     graphic                 graphic    graphic
;----------------------------------------------------------------------
;     _         Blank                      o       Horiz Line - scan 1
;     '         Diamond                    p       Horiz Line - scan 3
;     a         Checkerboard               q       Horiz Line - scan 5
;     b         Digraph: HT                r       Horiz Line - scan 7
;     c         Digraph: FF                s       Horiz Line - scan 9
;     d         Digraph: CR                t       Left "T" (|-)
;     e         Digraph: LF                u       Right "T" (-|)
;     f         Degree Symbol              v       Bottom "T" (|_)
;     g         +/- Symbol                 w       Top "T" (T)
;     h         Digraph: NL                x       Vertical Bar (|)
;     i         Digraph: VT                y       Less/Equal (<_)
;     j         Lower-right corner         z       Grtr/Egual (>_)
;     k         Upper-right corner         {       Pi symbol
;     l         Upper-left corner          |       Not equal (=/)
;     m         Lower-left corner          }       UK pound symbol
;     n         Crossing lines (+)         ~       Centered dot
;
; note: some terminals have not implemented all characters.
;       This was noticed on Konsole (2005-4-9), but xterm 
;       and rxvt were OK.
;<
;-----------------------------------------------------------
  global draw_on
draw_on:
  mov	ecx,base_msg
  call	crt_str
  ret
base_msg: db 1bh,')0',0eh,0	;line draw set
