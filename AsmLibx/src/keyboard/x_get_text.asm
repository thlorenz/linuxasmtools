
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
;-------------------  x_get_text.asm ----------------
;%define DEBUG
%undef DEBUG
%define LIBRARY

  [section .text]  
;-------------------------------------------

  extern delay
  extern x_check_event
  extern x_read_socket
  extern window_color
  extern window_write_line
  extern lib_buf
  extern x_key_translate
  extern x_flush
  extern x_edit_key_decode

%include "../../include/window.inc"

struc strdef
._data_buffer_ptr    resd 1 ;cleared or preload with text
._buffer_size        resd 1 ;buffer size, must be >= window size
._display_row        resb 1 ;row (1-x)
._display_column     resb 1 ;column (1-x)
._initial_cursor_col resb 1 ;must be within data area
._window_size        resd 1 ;bytes in window
._scroll             resd 1 ;adjustment to start of data (window scroll)
._stringBColor       resd 1 ;string background color#
._stringFColor       resd 1 ;string foreground color#
._cursorBColor       resd 1 ;string cursor background color#
._cursorFColor       resd 1 ;string cursor foreground color#
endstruc
;--------------------------------------------------------
;>1 keyboard
;  x_get_text - get string in scrolled window line
;    Read string into buffer using optional window size.
;    Unknown keys can be returned to caller for processing
;    or ignored by x_get_text.
; INPUTS
;    ebp= win block ptr (see window_pre)
;    eax= pointer to table with following structure:
;    struc strdef
;    ._data_buffer_ptr    resd 1 ;+0    blanked or preload with text
;    ._buffer_size        resd 1 ;+4    buffer size, > or = window_size
;    ._display_row        resb 1 ;+12   ;row (1-x)
;    ._display_column     resb 1 ;+13   ;column (1-x)
;    ._initial_cursor_col resb 1 ;+15   ;must be within data area
;    ._window_size        resd 1 ;+16   bytes in window
;    ._scroll             resd 1 ;+20   window scroll right count
;    ._stringBColor       resd 1 ;string background color#
;    ._stringFColor       resd 1 ;string foreground color#
;    ._cursorBColor       resd 1 ;string cursor background color#
;    ._cursorFColor       resd 1 ;string cursor foreground color#
;    endstruc
;
;    note: the input block is updated by x_get_text and must
;          be writable.  This allows x_get_text entry to continue
;          from last entry when called over and over.
;
;    note: x_get_text is always in insert mode.
;    
;    note: The Initial cursor column must equal the display column
;      or within the range of "display_column" + window_size"
;      Thus, if "display_column=5" and "window_size"=2 then
;      "initial cursor" can be 5 or 6
;      If window_size extends beyond physical right edge of screen
;      it will be truncated.
;
;    note: the initial buffer is assumed to contain text or
;          blanks.  At exit the whole buffer is retruned with
;          edits.
;           
; OUTPUT
;    ebp=pointer to input table (unchanged)
;    [lib_buf] has packet that caused exit
;
;    note: x_get_text uses right/left arrow, rubout, del
;          home, end, .  All
;          other non-text data will force exit.
;
; NOTES
;   source file: x_get_text.asm
;<
; * ----------------------------------------------
;*******

  global x_get_text
x_get_text:
  call	initialize			;set ebp -> string block
gs_loop:
  call	display_string
  call	wait_with_cursor
  jc	gs_exit				;jmp if non-key event
;process key press
gs_30:
  mov	bh,[key_flag]
  mov	bl,[key_code]
  mov	esi,key_action_tbl
  call	x_edit_key_decode
  call	eax
;any non zero return tells us to exit
gs_40:
  or	al,al
  jns	gs_loop				;loop for another key
;exit and return registers
gs_exit:
  mov	ah,[ebp+strdef._initial_cursor_col]
;remove cursor
  push	eax
  call	display_string
  pop	eax
  ret

;------------------------------------------------
; keyboard processing
;------------------------------------------------
unknown_input:
  mov	al,-1
  ret
;-------------
gs_normal_char:
  mov	ebx,[buf_end]
  mov	eax,[str_ptr]
  dec	ebx
  cmp	eax,ebx      			;check if room for another char
  jb	gs_10				;jmp if room
;we are at end of buffer, stuff and exit
  mov	bl,[key_code]
  mov	[eax],bl
  jmp	short gs_right_exit		;
;
; make hole to stuff char
;
gs_10:
  std
  mov	edi,[buf_end]
  dec	edi
  mov	esi,edi
  dec	esi
gs_21:
  movsb
  cmp	edi,eax				;are we at hole
  jne	gs_21
  cld
  mov	al,[key_code]			;get char
  mov	byte [edi],al
;-----------------
gs_right:
  mov	esi,[str_ptr]
  inc	esi
  cmp	esi,[buf_end]			;check if buffer ok
  jae	gs_right_exit			;jmp if no more buffer

  mov	al,[ebp+strdef._initial_cursor_col]
  cmp	al,[win_end_col]
  je	gs_right_scroll			;jmp if at right edge
;display ok to > buffer space ok also
  inc	byte [ebp+strdef._initial_cursor_col]		;move cursor fwd
  inc	dword [str_ptr]			;move ptr fwd
  jmp	short gs_right_exit

gs_right_scroll:
  inc	dword [ebp+strdef._scroll]
  inc	dword [str_ptr]  
gs_right_exit:
  xor	eax,eax			;normal return
  ret

;-----------------
gs_home:
  mov	[ebp+strdef._scroll],dword 0
  mov	eax,[ebp+strdef._data_buffer_ptr]
  mov	[str_ptr],eax
  mov	[ebp+strdef._initial_cursor_col],byte 1
  xor	eax,eax
  ret
;-----------------
gs_end:
;scan to end of string
  mov	esi,[ebp+strdef._data_buffer_ptr]
  mov	bl,[ebp+strdef._display_column]
gs_end_lp:
  cmp	esi,[buf_end]			;check for specail cas at end
  je	gs_end_50
  cmp	bl,[win_end_col]
  jne	gs_end_10			;jmp if not at end of widow
  inc	dword [ebp+strdef._scroll]
  dec	bl
gs_end_10:
  inc	esi
  inc	bl
  jmp	short gs_end_lp
;esi points at end  bl=column  [ebp+strdef._scroll] is updated
gs_end_50:
  cmp	esi,[buf_end]
  jne	gs_end_60			;jmp if not special case
  dec	esi
  cmp	[ebp+strdef._scroll],dword 0
  je	gs_end_55
  dec	dword [ebp+strdef._scroll]
  jmp	short gs_end_60
gs_end_55:
  dec	bl
  jmp	short gs_end_70
gs_end_60:
  mov	[str_ptr],esi
  mov	[ebp+strdef._initial_cursor_col],bl
gs_end_70:
  xor	eax,eax		;normal return
  ret

;-----------------
gs_left:
  mov	eax,[str_ptr]
  cmp	eax,[ebp+strdef._data_buffer_ptr]
  je	gs_left_exit			;jmp if at beginning of buffer
  mov	al,[ebp+strdef._initial_cursor_col]		;get cursor posn
  cmp	al,[ebp+strdef._display_column]
  je	gs_left_scroll			;jmp if at left edge already

  dec	byte [ebp+strdef._initial_cursor_col]
  dec	dword [str_ptr]
  jmp	gs_left_exit

gs_left_scroll:
  cmp	dword [ebp+strdef._scroll],0
  je	gs_left_exit
  dec	dword [ebp+strdef._scroll]
  dec	dword [str_ptr]
gs_left_exit:
  xor	eax,eax		;normal return
  ret

;-----------------
gs_del:
  mov	esi,[str_ptr]
  mov	edi,esi
  inc	esi
  cmp	esi,[buf_end] 
  je	gs_del_stuf			;if at end, just do stuff
gs_del_lp:
  cmp	esi,[buf_end]
  jae	gs_del_stuf
  movsb
  cmp	edi,[buf_end]
  jne	gs_del_lp
gs_del_stuf:
  mov	byte [edi],' '
gs_del_exit:
  xor	eax,eax			;normal return
  ret

;-----------------
gs_backspace:
  mov	esi,[str_ptr]
  mov	edi,esi
  dec	edi
  cmp	esi,[ebp+strdef._data_buffer_ptr] 
  je	gs_bak_exit			;ignore operation if at beginning
gs_bak_lp:
  movsb
  mov	byte [edi],' '			;blank prev. position
  cmp	esi,[buf_end]
  jb	gs_bak_lp			;loop till everything moved
;update pointers and check for scroll
  mov	bl,[ebp+strdef._initial_cursor_col]
  cmp	bl,[ebp+strdef._display_column]	;are we at left edge
  je	gs_bak_20			;jmp if at edge
;normal backspace inside string
  dec	dword [str_ptr]
  dec	byte [ebp+strdef._initial_cursor_col]
  jmp	short gs_bak_exit
;backspace at left edge of window
;we can assume [ebp+strdef._scroll] is non zero because of previous buffer check
gs_bak_20:
  dec	dword [ebp+strdef._scroll]
  dec	dword [str_ptr]
gs_bak_exit:
  xor	eax,eax		;nomral return
  ret

;------------------------------------------------
;  input:  ebp -> data buffer ptr         +0    (dword)  has zero or preload
;                 buffer_size             +4    (dword)
;                 color ptr               +8    (dword)
;                 display row             +12   (db)	;str display loc
;                 display column          +13   (db)
;          [win_end_col] = end of display
;          [ebp+strdef._scroll] = amount of data to skip over
;          
display_string:
  mov	ebx,[ebp+strdef._stringFColor]
  mov	ecx,[ebp+strdef._stringBColor]
  push	ebp		;save string block
  mov	ebp,[wb_save]
  call	window_color
  pop	ebp		;restore string block

  movzx	ecx,byte [ebp+strdef._display_column]
  movzx edx,byte [ebp+strdef._display_row]	
  mov	esi,[ebp+strdef._data_buffer_ptr]
  add	esi,[ebp+strdef._scroll]
  movzx edi,byte [ebp+strdef._window_size]
  push	ebp		;save string block
  mov	ebp,[wb_save]
  call	window_write_line
  pop	ebp		;restore string block
  ret
;------------------------------------------------
;input: eax = string block ptr
;       ebp = win block ptr
;output: ebp=string block ptr

;process callers inputs
;check display window size
;clear line or line end

initialize:
  mov	[wb_save],ebp	;save epb

  mov	ebx,[eax+strdef._data_buffer_ptr]
  add	ebx,[eax+strdef._buffer_size] ;compute end of buffer
  mov	[buf_end],ebx

  mov	bl,[eax+strdef._window_size]
  add	bl,[eax+strdef._display_column]  ;compute window end
  dec	bl			;adjust for testing
;check if win_end_col is legal, (fits our screen)
  cmp	bl,[ebp+win.s_text_columns]
  jbe	init_18		;jmp if window ok
  mov	bl,[ebp+win.s_text_columns]
init_18:
  mov	[win_end_col],bl

; set str_ptr
  mov	edi,[eax+strdef._data_buffer_ptr]
  xor	ebx,ebx
  mov	bl,[ebp+strdef._initial_cursor_col]
  sub	bl,[ebp+strdef._display_column]
  add	edi,ebx
  mov	[str_ptr],edi			;set edit point

  mov	ebp,eax			;set ebp to string block
  ret
;------------------------------------------------

;------------------------------------------------
; This  table is used by x_get_text to decode keys
;
key_action_tbl:
   dd gs_normal_char
  dw 4050h        		; pad_home
   dd gs_home
  dw 4095h            		;138 home (non-keypad)
   dd gs_home
  dw 409ch          		; pad_end
   dd gs_end
  dw 4057h        		;145 pad_end
   dd gs_end

  dw 4051h        		; pad_left
   dd gs_left
  dw 4096h        		;143 pad_left
   dd gs_left
  dw 4053h        		; pad_right
   dd gs_right
  dw 4098h        		;144 pad_right
   dd gs_right


  dw 40ffh           		; pad_del
   dd gs_del
  dw 409fh        		;149 pad_del
   dd gs_del
  dw 4008h			; backspace
   dd gs_backspace
  dw 0		;end of table
   dd unknown_input
;----------------------------------------------------------
;input   movzx	eax,byte [ebp+strdef._initial_cursor_col]
;        movzx	ebx,byte [ebp+strdef._display_row]
;        ebp = string block
;output: carry set if non-key event
;        no-carry = success and key at
;           al [key_code]
;           ah [key_flag]
;
wait_with_cursor:
;  mov	[toggle_count],dword 20
;wwc_lp2:
  mov	ebx,[ebp+strdef._cursorFColor]
  mov	ecx,[ebp+strdef._cursorBColor]
;  test	[toggle_flag],byte 1
;  jz	wwc_10
;  mov	ebx,[ebp+strdef._stringFColor]
;  mov	ecx,[ebp+strdef._stringBColor]
wwc_10:
  push	ebp		;save string block
  mov	ebp,[wb_save]
  call	window_color
  pop	ebp		;restore string block
;write a character
  movzx	ecx,byte [ebp+strdef._initial_cursor_col]
  movzx edx,byte [ebp+strdef._display_row]	
  mov	esi,[str_ptr]
  mov	edi,1		;string1_len
  push	ebp		;save string block
  mov	ebp,[wb_save]
  call	window_write_line
  call	x_flush
  pop	ebp		;restore string block
wwc_lp2:
  call	x_check_event
  jnz	wwc_50		;jmp if something avail
  mov	eax,10
  call	delay
  jmp	short wwc_lp2
wwc_50:
;we have something on socket
;   eax = -1 "js" error
;          0 "jz" no socket pkts, no pending replies
;          1  socket pkt avail.
;          2  expecting reply
;          3  socket pkt avail. & expecting reply
  xor	eax,eax	;no wait
  mov	ecx,lib_buf	;buffer
  mov	edx,700		;buffer length
  call	x_read_socket
;     eax = number of bytes in buffer
;     ecx = reply buffer ptr
  cmp	[ecx],byte 2		;keypress event
  jne	wwc_abort
  call	x_key_translate
  test	ah,20h			;is this a meta (ignore) key
  jnz	wwc_lp2			;jmp if "ignored" key
  mov	[key_code],al
  mov	[key_flag],ah
  clc			;set (have key) flag
  jmp	short wwc_exit
wwc_abort:
  stc
wwc_exit: 
  ret
      


 [section .data align=4]

toggle_count	dd	0
toggle_flag	dd	0	;0=normal colors  1=cursor colors
key_code	db	0
key_flag	db	0

;-----------------------------------------------------------
wb_save		dd 	0
buf_end		dd	0	;one location beyond data in buffer
str_ptr		dd	0	;current string edit point
win_end_col	db	0	;window end column (inside window) 

 [section .text]
