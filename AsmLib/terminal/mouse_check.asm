
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

  [section .text]

 extern kbuf
    
;>1 terminal
;   mouse_check - reformat keyboard data if mouse click info
; INPUTS
;   [kbuf]  has mouse escape sequenes
;          1b,5b,4d,xx,yy,zz
;            xx - 20=left but  21=middle 22=right 23=release
;            yy - column+20h
;            zz - row + 20h
; OUTPUT
;   [kbuf]  = ff,button,column,row
;             where: ff = db -1
;                    button = 0=left but  1=middle 2=right 3=release
;                    column = binary column (byte)
;                    row = binary row (byte)  
; NOTES
;    source file: mouse_check.asm
;
;    mouse_check assumes the keyboard is in raw mode.  It is
;    called from the keyboard handlers and probably isn't of
;    interest for other applications.
;<

;
  global mouse_check
mouse_check:
  cmp	word [kbuf],5b1bh		;check if possible mouse
  jne	mc_exit				;jmp if not mouse
  cmp	byte [kbuf+2],4dh
  jne	mc_exit			;jmp if not mouse
; read release key
  mov	eax,3				;sys_read
  mov	ebx,0				;stdin
  mov	ecx,kbuf+6
  mov	edx,20				;buffer size
  int	0x80				;read key
; format data
  mov	edi,kbuf
  mov	byte [edi],-1
  inc	edi			;signal mouse data follows
  mov	al,[kbuf+3]
  and	al,3
  stosb 			;store button 0=left 1=mid 2=right
  mov	al,[kbuf+4]
  sub	al,20h
  stosb				;store column 1+
  mov	al,[kbuf+5]
  sub	al,20h
  stosb				;store row
mc_exit:
  ret 
