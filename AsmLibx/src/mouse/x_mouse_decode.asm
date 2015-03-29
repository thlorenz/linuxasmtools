
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

%ifndef DEBUG
%include "../../include/window.inc"
%endif

;------------------ x_mouse_decode.inc -----------------------

struc mouse_pkt
.code	resb 1		;code = 4(press) 5(release) 6(MotionNotify)
.but	resb 1		;evemt window code
.seq	resw 1		;pkt sequence#
.time	resd 1		;time of event
.root	resd 1		;root win id
.ewinn	resd 1		;event win id
.cwin	resd 1		;child win (0=none)
.rootx	resw 1		;root pix column
.rooty	resw 1		;root pix row
.eventx resw 1		;event pix column
.eventy resw 1		;event pix row
.mask	resw 1		;event bits
.same	resb 1		;same screen bool
	resb 1		;unused
;mask bits are:
; 10-numlock 08-alt 04-ctrl 02-caplock 01-shift
endstruc

;---------------------
;>1 mouse
;  x_mouse_decode - associate process with screen area
; INPUTS
;  ebp = window block
;  ecx = event packet pointer
;  esi = decode table ptr
;        decode table entries:
;                              db (starting col) character
;                              db (ending col) character
;                              db (starting row) character
;                              db (ending row) character
;                              dd process adr
;                                     .
;                              dd 0 ;end of table
; OUTPUT:
;    eax = 0 if no process found for click area
;          process address if click in table
;    flags set for jz (no process) or jnz (process found)
;              
; NOTES
;   source file: x_mouse_decode
;<
; * ----------------------------------------------

  global x_mouse_decode
x_mouse_decode:
  movzx	eax,word [ecx+mouse_pkt.eventx]	;get pixel column
  or	eax,eax
  jz	no_match
  xor	edx,edx
  div	word [ebp+win.s_char_width]
  mov	bl,al		;save column

  movzx eax,word [ecx+mouse_pkt.eventy]	;get pixel row
  or	eax,eax
  jz	no_match
  xor	edx,edx
  div	word [ebp+win.s_char_height]
  mov	bh,al		;save row
;  dec	bh

;bl=click column  bh=click row
xmd_loop:
  lodsd        		;get next entry
  or	eax,eax
  jz	no_match	;exit if no button at click
;al=starting column
  cmp	bl,al
  jb	xmd_next
  cmp	bl,ah
  ja	xmd_next
;column matches, check row
  shr	eax,16
  cmp	bh,al
  jb	xmd_next	;jmp if row wrong
  cmp	bh,ah
  ja	xmd_next
  lodsd			;get process
  jmp	short xmd_exit
xmd_next:
  lodsd			;move past process
  jmp	short xmd_loop
no_match:
xmd_exit:
  or	eax,eax
  ret

 [section .text]

