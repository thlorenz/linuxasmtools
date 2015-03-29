
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
;---------- window_rel_table ------------------

  extern str_move
  extern tm_pkt
  extern x_write_block_entry1
  extern x_write_block_entry2
  extern color_id_table

%ifndef DEBUG
%include "../../include/window.inc"
%endif
  extern x_send_request

;%ifndef DEBUG
struc tm
  		resb 1	;opcode
.tm_str_len	resb 1
.tm_len		resw 1	;pkt len / 4
.tmp_id		resd 1	;win id
.tm_gc		resd 1	;gc id
.tm_x		resw 1	;x column
.tm_y		resw 1	;y row
.tm_string	resb 1	;string
endstruc

;%endif

struc cgcr
		resb 1	;opcode
		resb 1	;unused
.pkt_len	resw 1
.cgc_id		resd 1
.mask		resd 1
.fore_color	resd 1
.back_color	resd 1
endstruc

;---------------------
;>1 win_text
;  window_rel_table - display list of items 
; INPUTS
;  window_rel_table_setup must be called once
;                 before using this function.
;  ebp = ptr to window control block
;  eax = character adjustment to window column
;  ebx = character adjustement to window row
;  esi = ptr to table (see below)
;        color entry = db 16;color opcode
;                      db x ;foreground color number
;                      db x ;background color number
;
;        fill line   = db 4 ;opcode
;                      dw x ;x column (char)
;                      dw y ;y row (char)
;                      db x ;length of fill
;                      db c ;fill char
;
;        write column  db 8 ;opcode
;                      dw x ;x column (text,char)
;                      dw y ;y starting row
;                      db x ;length of write
;                      db xx ;string
;
;        write llne    db 12;opcode
;                      dw x ;x column (text,char)
;                      dw y ;y row
;                      db x ;length of string
;                      db xx;string
;
;        end of table  db 0
;
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
;   "js" flag set if error
;              
; NOTES
;   source file: window_rel_table.asm
;<
; * ----------------------------------------------

  global window_rel_table
window_rel_table:
  mov	[column_adjust],eax
  mov	[row_adjust],ebx
  push	ebp
wwt_lp:
  movzx	eax,byte [esi]	;get opcode
  add	eax,wwt_decode
  inc	esi
  jmp	[eax]
;------------
wwt_color:
  mov	ebx,color_id_table	;get color table start adr
  mov	ecx,cgcr_pkt		;get output packet adr
  movzx	eax,byte [esi]	;get color number
  mov	eax,[eax+ebx]	;get color id
  mov	[ecx+12],eax	;store foregrond color cid in pkt
;
  inc	esi
  movzx	eax,byte [esi]	;get background color#
  mov	eax,[eax+ebx]	;get color id
  mov	[ecx+16],eax

  push	esi
  mov	edx,20
  call	x_send_request
  pop	esi

  inc	esi		;move to next entry
  jmp	short wwt_lp
;------------
wwt_string:
  call	adr_setup	;set cx=pix col  dx=pix row
  movzx edi,byte [esi]	;get length of string
  inc	esi		;point at start of string
  push	esi		;save string start
  push	edi		;save string size
  call	x_write_block_entry1 ;cx=x dx=y esi=msg edi=length
  pop	edi		;restore msg length
  pop	esi		;restore msg ptr
  add	esi,edi		;point to next table entry
  jmp	wwt_lp
;------------
wwt_fill:
  call	adr_setup	;set cx=col dx=row
  mov	[tm_pkt+tm.tm_x],cx
  mov	[tm_pkt+tm.tm_y],dx
  movzx	ecx,byte [esi]	;get length
  mov	[tm_pkt+tm.tm_str_len],cl
  mov	ebx,ecx		;save length
  inc	esi
  lodsb			;get stuff char
  lea	edi,[tm_pkt+tm.tm_string]	;address for string
  rep	stosb		;store char
  push	esi
  call	x_write_block_entry2 ;preserve esi,ebp
  pop	esi
  jmp	wwt_lp
;------------
wwt_write_down:
  call	adr_setup	;set cx=col dx=row
  mov	[tm_pkt+tm.tm_x],cx
  mov	[tm_pkt+tm.tm_y],dx
  mov	[tm_pkt+tm.tm_str_len],byte 1
  mov	[tm_pkt+tm.tm_len],byte 5	;packet length
  lodsb			;get length of vertical string
  movzx	edx,al		;loop counter to edx
wwd_lp:
  lodsb			;get next output char
  mov	[tm_pkt+tm.tm_string],al	;store char
  mov	ecx,tm_pkt
  push	esi
  push	edx
  mov	edx,20		;packet length
  call	x_send_request
  mov	edx,[ebp+win.s_char_height]
  add	word [tm_pkt+tm.tm_y],dx	;move down
  pop	edx
  pop	esi
  dec	dl
  jnz	wwd_lp  
  jmp	wwt_lp
;------------
wwt_done:  
  pop	ebp
  ret
;------------------------
; input: esi=input table ptr
;        ebp=window block ptr
; output: cx=x loc (pixel column)
;         dx=y loc (pixel row)
adr_setup:
  movzx	eax,word [esi]	;get x loc (column)
  add	eax,[column_adjust]
  mul	dword [ebp+win.s_char_width]
  mov	ecx,eax

  add	esi,byte 2
  movzx	eax,word [esi]	;get x loc (row)
  add	eax,[row_adjust]
  mul	dword [ebp+win.s_char_height]
  add	eax,[ebp+win.s_char_ascent]
  mov	edx,eax

  add	esi,byte 2
  ret
;---------------------
  [section .data]
wwt_decode:
  dd	wwt_done	;0
  dd	wwt_fill	;1
  dd	wwt_write_down	;2
  dd	wwt_string	;3
  dd	wwt_color	;4
  [section .text]
;---------------------
;>1 win_text
;  window_rel_table_setup - setup for window_rel_table
; INPUTS
;  ebp = win_block ptr
; OUTPUT:
;              
; NOTES
;   source file: window_rel_table.asm
;<
; * ----------------------------------------------
  extern cgcr_pkt
  global window_rel_table_setup
window_rel_table_setup:
  mov	eax,[ebp+win.s_win_id]
  mov	ebx,[ebp+win.s_cid_1]
  push	ebp
  mov	ebp,tm_pkt
  mov	[ebp+tm.tmp_id],eax
  mov	[ebp+tm.tm_gc],ebx
  mov	ebp,cgcr_pkt
  mov	[ebp+cgcr.cgc_id],ebx
  pop	ebp
  ret
;-----------------
  [section .data]

column_adjust: dd 0
row_adjust:	dd 0
  [section .text]

