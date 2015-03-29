
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
;>1 utility
;  AsmColor - A color table is displayed with codes
;  used by AsmLib to generate colors.
; INPUTS
;    usage: asmcolor <Enter>
;    No inputs are needed for AsmColor
;    ESC - exits  (also "q" exits)
; OUTPUT
;    none
; NOTES
;   source file:  asmcolor.asm
;    
;<
; * ----------------------------------------------
;**********  file  view_info *******************
;
;
  extern read_stdin
  extern crt_clear
  extern crt_color_at
  extern move_cursor
  extern reset_clear_terminal

  global main,_start
main:
_start:
  cld
  mov	eax,[background_color]
  call	crt_clear

  mov	bh,1			;row
  mov	bl,1
  mov	eax,[background_color]
  mov	ecx,intro_msg
  call	crt_color_at

  mov	bh,2			;row
  mov	bl,1
  mov	eax,[background_color]
  mov	ecx,intro_msg2
  call	crt_color_at


  mov	bh,4			;row
  mov	bl,1
  mov	eax,[background_color]
  mov	ecx,header_msg
  call	crt_color_at


  mov	bh,5			;row
  mov	bl,1
  mov	eax,[background_color]
  mov	ecx,header_msg2
  call	crt_color_at

  mov	esi,color_list		;get table ptr
color_loop:
  lodsd				;get color template
  or	eax,eax
  jz	color_done		;jmp if end of table
  push	esi
  mov	bh,[table_row]		;starting row
  call	show_color_line
  pop	esi
  add	esi,11
  inc	byte [table_row]
  jmp	short color_loop
 
color_done:
  mov	bh,[table_row]
  add	bh,2
  mov	bl,3
  mov	eax,[background_color]
  mov	ecx,quit_msg
  call	crt_color_at
  call	read_stdin

;  mov	eax,30003730h
;  call	crt_clear
;  mov	eax,0101h
;  call	move_cursor
  call	reset_clear_terminal

  xor	ebx,ebx			;set success return code
  mov	eax,1
  int	80h
;--------------------------------------------------------
; INPUTS:
;     eax = color code for start of line
;     esi = ptr to display string
;      bh & [table_row] have display row
show_color_line:
  mov	[color_code],eax	;save starting color

  mov	eax,[background_color]
  mov	bl,2			;text column
  mov	bh,[table_row]
  mov	ecx,esi			;get display string
  call	crt_color_at
  mov	dword [line_loop_count],8
  mov	byte [table_col],14
  mov	word [color_byte],'00'
line_loop:
  mov	bl,[table_col]
  mov	bh,[table_row]
  mov	ecx,color_byte
  mov	eax,[color_code]
  call	crt_color_at
  inc	dword [color_code]
  inc	byte [color_byte +1]
  add	byte [table_col],3
  dec	dword [line_loop_count]
  jnz	line_loop
  ret

;-----------------------
  [section .data]

table_col	db	0
table_row:	db	6	;display row
background_color:
	dd  30003437h

color_code:
  dd	0
line_loop_count:
  dd	8
color_byte:
  db	'00',0

color_list:
 dd 30003030h
    db ' 3000303x ',0
 dd 31003030h
    db ' 3100303x ',0
 dd 30003130h
    db ' 3000313x ',0
 dd 31003130h
    db ' 3100313x ',0
 dd 30003230h
    db ' 3000323x ',0
 dd 31003230h
    db ' 3100323x ',0
 dd 30003330h
    db ' 3000333x ',0
 dd 31003330h
    db ' 3100333x ',0
 dd 30003430h
    db ' 3000343x ',0
 dd 31003430h
    db ' 3100343x ',0
 dd 30003530h
    db ' 3000353x ',0
 dd 31003530h
    db ' 3100353x ',0
 dd 30003630h
    db ' 3000363x ',0
 dd 31003630h
    db ' 3100363x ',0
 dd 30003730h
    db ' 3000373x ',0
 dd 31003730h
    db ' 3100373x ',0
 dd 30003830h
    db ' 3000383x ',0
 dd 31003830h
    db ' 3100383x ',0
 dd 31003930h
    db ' 3000393x ',0
 dd 31003930h
    db ' 3100393x ',0
 dd 0

quit_msg:
  db 'press any key to continue',0
intro_msg:
  db 'To create AsmLib color code, replace (x) in value with number from',0
intro_msg2:
  db 'displayed color.  Example: black on white = 30003037h',0
header_msg:
  db '   Value         ( x in value)',0
header_msg2:
  db '  --------   --------------------------------- ',0

;------------------------
 [section .bss]
 [section .text]




















