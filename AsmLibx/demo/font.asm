
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
  extern env_stack
  extern str_move
  extern x_wait_event
  extern x_freegc
  extern window_pre
  extern strlen1
  extern window_create
  extern window_id_color
  extern window_write_line
  extern  window_kill
  extern str_len
  extern _white,_black
  extern _blue,_yellow

%include "../include/window.inc"
;---------------------
;>1 demo
;  font - display default font characters
; INPUTS
;  none
;
; OUTPUT:
;    name of font is followed by table
;    of font characters
;              
; NOTES
;   source file: /demo/font.asm
;<
; * ----------------------------------------------
  
  global main,_start
main:
_start:
  cld
  call	env_stack
  mov	ebp,win_block
  mov	eax,the_buffer
  mov	edx,the_buffer_size
  mov	ecx,00		;background color
  mov	ebx,10		;font
  call	window_pre	;get initial conditions
  jns	win_10
  jmp	done
win_10:
  mov	ax,[ebp+win.s_root_width]
  mov	[wc_block+4],ax	;set width
  mov	ax,[ebp+win.s_root_height]
  mov	[wc_block+6],ax	;set height
  mov	esi,wc_block
  call	window_create
  js	done		;jmp if error

;setup color for our table
  mov	ecx,[_white]	;background color
  mov	ebx,[_black]	;foreground color
  call	window_id_color
  js	done			;jmp if error


;write a text string to our new window
  mov	ecx,10		;x location,  column
  mov	edx,1		;y location,  row
  mov	esi,title1
  mov	edi,title1_end - title1
  call	window_write_line

  mov	ecx,10		;x location,  column
  mov	edx,2		;y location,  row
  mov	esi,title2
  mov	edi,title2_end - title2
  call	window_write_line

;display font size
  call	show_font_size

  mov	ecx,16		;x location,  column
  mov	edx,4		;y location,  row
  mov	esi,title3
  mov	edi,title3_end - title3
  call	window_write_line

;setup outer loop
  mov	[outter_hex_table_ptr],dword outter_hex_table
  mov	[line],dword 5

outter_loop:
;setup color for our table
  mov	ecx,[_white]	;background color
  mov	ebx,[_black]	;foreground color
  call	window_id_color
  js	done			;jmp if error

;display name of background color for this row
  mov	ecx,dword 8	;x location,  column
  mov	edx,[line]	;y location,  row
  mov	esi,[outter_hex_table_ptr] ;get color text
  mov	edi,8
  call	window_write_line

;setup color for our table
  mov	ecx,[_blue]	;background color
  mov	ebx,[_yellow]	;foreground color
  call	window_id_color
;setup for new inner loop
  mov	[column],dword 16

inner_loop:

  mov	ecx,[column]	;x location,  column
  mov	edx,[line]	;y location,  row
  mov	esi,inner_char
  mov	edi,1
  call	window_write_line
;inner loop tail
  inc	byte [inner_char]
  add	[column],dword 1
  test	[inner_char],byte 0fh
  jnz	inner_loop
;outter loop tail
  add	[line],byte 1		;bump line
  add	[outter_hex_table_ptr],dword 8 ;move to next color
  mov	eax,[outter_hex_table_ptr]
  cmp	[eax],dword 0
  jnz	outter_loop		;loop till all lines shown

  call	show_font_path
  js	done			;jmp if error
  call	x_wait_event

  call	window_kill

;000:>:0x0013:32: Reply to GetInputFocus: revert-to=PointerRoot(0x01) focus=0x02e00001
done:
  mov	eax,1
  int	byte 80h

;---------------------------------
  extern x_get_font_path

show_font_path:
  mov	ecx,[_white]	;background color
  mov	ebx,[_black]	;foreground color
  call	window_id_color

  call	x_get_font_path
  js	sfp_exit	;exit if error

  mov	bl,[ecx+8]	;get number of strings
  mov	bh,20		;starting row
  lea	esi,[ecx+32]	;first string
sfp_loop:
  cmp	bl,0		;check number of strings
  je	sfp_exit	;exit if done

  xor	eax,eax
  lodsb			;get length
  mov	edi,eax		;lenght -> edi
  xor	edx,ecx
  mov	dl,bh		;get row
  mov	ecx,1		;column
  push	ebx
  push	esi
  call	window_write_line
  pop	esi
  pop	ebx
;advance to next string
  dec	esi
  movzx ecx,byte [esi]
  add	esi,ecx
  inc	esi
  inc	bh		;bump row
  dec	bl		;dec string counter
  jmp	short sfp_loop

sfp_exit:
  ret
;---------------------------------
 extern dword_to_lpadded_ascii

show_font_size:
  movzx	eax,byte [ebp+win.s_char_width]
  mov	edi,fwidth
  mov	cl,2
  mov	ch,' '
  push	ebp
  call	dword_to_lpadded_ascii
  pop	ebp

  movzx eax,byte [ebp+win.s_char_height]
  mov	edi,fheight
  mov	cl,2
  mov	ch,' '
  push	ebp
  call	dword_to_lpadded_ascii
  pop	ebp

  mov	esi,font_msg
  mov	edi,font_msg_len
  mov	ecx,1		;column
  mov	edx,3		;row
  call	window_write_line
  ret
;----------------------------------
 [section .data]
;------
font_msg: db 'font width='
fwidth:	db 0,0
	db ' height='
fheight: db 0,0
font_msg_len equ $ - font_msg

;font_string: db '10x20',0
;font_string: db '12x24',0,'*-courier-bold-*-16-*',0,0
;font_string: db '9x15bold',0
;font_string: db '*-courier-bold-*-18-*',0
white:	     db 'white',0

outter_hex_table_ptr: dd 0
line			dd 0

inner_char:	db 0
column			dd 0


title1: db 'font display characters - Press any key to continue'
title1_end:
title2: db '---------------------------------------------------------'
title2_end:
title3: db '0123456789ABCDEF'
title3_end:

outter_hex_table:
 db 'hex 0x  '
 db 'hex 1x  '
 db 'hex 2x  '
 db 'hex 3x  '
 db 'hex 4x  '
 db 'hex 5x  '
 db 'hex 6x  '
 db 'hex 7x  '
 db 'hex 8x  '
 db 'hex 9x  '
 db 'hex Ax  '
 db 'hex Bx  '
 db 'hex Cx  '
 db 'hex Dx  '
 db 'hex Ex  '
 db 'hex Fx  '
 dd 0		;end of table

  [section .bss]
 align 4

win_block: resb win_struc_size

the_buffer: resb 24000
the_buffer_size equ $ - the_buffer

wc_block: resw 1	;x loc
	  resw 1	;y
	  resw 1	;width
	  resw 1	;height

 [section .text]



