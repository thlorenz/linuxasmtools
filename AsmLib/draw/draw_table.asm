
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
  extern crt_char_at
  extern move_cursor
  extern crt_set_color
  extern crt_horizontal
  extern crt_vertical
  extern draw_on
  extern draw_off

;-----------------------------------------------------
;>1 draw
; draw_table - draw using table of actions   
; inputs:
;    esi = ptr to draw table
;          draw table codes db 0                  = end of table
;                           db 1 + dd cccc        = color change
;                           db 2,row,col,char     = single char display
;                           db 3,row,col,rep,char = repeat char. horiz
;                           db 4,row,col,rep,char = repeat char, down
;                           db 5                  = draw on
;                           db 6                  = draw off
;
; outputs:
;    none
; notes:
;   source file  draw_table.asm
;
;draw_on will change character map changes as follows:
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
;       This was noticed on Konsole, but xterm & rxvt were OK.
;<
;-----------------------------------------------------------
  global draw_table
draw_table:
  xor	eax,eax
  lodsb			;get next code
  or	eax,eax
  jz	dt_exit		;exit if done
  dec	eax
  jz	dt_color
  dec	eax
  jz	dt_single_char
  dec	eax
  jz	dt_repeat_hor
  dec	eax
  jz	dt_repeat_down
  dec	eax
  jz	draw_enable
  dec	eax
  jz	draw_disable
dt_exit:
  ret
;---------
dt_color:
  lodsd				;get color
  mov	[active_color],eax	;save color
  jmp	draw_table
;---------
dt_single_char:
  lodsw				;get cursor position
  xchg	al,ah			;;
  mov	bx,ax			;move cursor to bl=col bh=row
  lodsb				;get char
  mov	cl,al			;char -> al
  mov	eax,[active_color]
  call	crt_char_at
  jmp	draw_table
;---------
dt_repeat_hor:
  lodsw				;get cursor position
  xchg	al,ah			;;;
  call	move_cursor
  lodsb				;get repeat count
  xor	ecx,ecx
  mov	cl,al			;repeat count -> ecx
  lodsb				;get char
  mov	bl,al			;char -> bl
  mov	eax,[active_color]
  call	crt_horizontal
  jmp	draw_table
;---------
dt_repeat_down:
  mov	eax,[active_color]
  call	crt_set_color
  lodsw				;get cursor position al=col ah=row
  xchg	al,ah
  push	eax
  lodsb				;get repeat count
  mov	bh,al			;repeat count -> bh
  lodsb
  mov	bl,al			;character to repeat -> bl
  pop	eax			;restore cursor position
  call	crt_vertical
  jmp	draw_table
;---------
draw_enable:
  call	draw_on
  jmp	draw_table
;---------
draw_disable:
  call	draw_off
  jmp	draw_table

;---------------
  [section .data]
active_color	dd	0
  [section .text]
