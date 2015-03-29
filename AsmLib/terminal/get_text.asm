
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
;%define DEBUG
%undef DEBUG
%define LIBRARY

  [section .text]  
;-------------------------------------------

  extern  move_cursor
  extern  read_stdin
  extern  kbuf
  extern  key_decode1
  extern  crt_columns,crt_rows
  extern  read_window_size
  extern  crt_write
  extern  crt_set_color

struc strdef
._data_buffer_ptr    resd 1 ;+0    cleared or preload with text
._buffer_size        resd 1 ;+4    buffer size, must be >= window size
._color_ptr          resd 1 ;+8    (see file crt_data.asm)
._display_row        resb 1 ;+12   ;row (1-x)
._display_column     resb 1 ;+13   ;column (1-x)
._initial_cursor_col resb 1 ;+15   ;must be within data area
._window_size        resd 1 ;+16   bytes in window
._scroll             resd 1 ;      adjustment to start of data (window scroll)
endstruc

;****f* key_mouse/key_string1 *
; NAME
;>1 terminal
;  get_text - get string in scrolled window line
;    Read string into buffer using optional window size.
;    Unknown keys can be returned to caller for processing
;    or ignored by get_text.
; INPUTS
;    ebp= pointer to table with following structure:
;
;    struc strdef
;    ._data_buffer_ptr    resd 1 ;+0    blanked or preload with text
;    ._buffer_size        resd 1 ;+4    buffer size, > or = window_size
;    ._color ptr          resd 1 ;+8    (see file crt_data.asm)
;    ._display_row        resb 1 ;+12   ;row (1-x)
;    ._display_column     resb 1 ;+13   ;column (1-x)
;    ._initial_cursor_col resb 1 ;+15   ;must be within data area
;    ._window_size        resd 1 ;+16   bytes in window
;    ._scroll             resd 1 ;+20   window scroll right count
;    endstruc
;
;    note: the input block is updated by get_text and must
;          be writable.  This allows get_text entry to continue
;          from last entry when called over and over.
;
;    note: get_text is always in insert mode.
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
;    [kbuf] has key press that caused exit
;
;    note: get_text uses right/left arrow, rubout, del
;          home, end, and mouse click within window.  All
;          other non-text data will force exit.
;
; EXAMPLE
;    call  mouse_enable	;library call to enable mouse
;    mov  ebp,string_block
;  key_loop:
;    call get_text
;
;    [section .data]
;   string_block:
;   data_buffer_ptr    dd buf ;+0    cleared or preload with text
;   buffer_size        dd 100 ;+4    buffer size
;   color_ptr          dd color1 ;+8    (see file crt_data.asm)
;   display_row        db   1 ;+12   ;row (1-x)
;   display_column     db   1 ;+13   ;column (1-x)
;   initial_cursor_col db   1 ;+15   ;must be within data area
;   window_size        dd  80 ;+16   bytes in window
;   scroll             dd   0 ;+20   no scroll initially
;
;   color1 dd 30003730h
;   buf times buffer_size db ' '
;
; NOTES
;   source file: get_text.asm
;   see also, get_string
;<
; * ----------------------------------------------
;*******

  global get_text
get_text:
  call	initialize
gs_loop:
  call	display_string
  mov	al,[ebp+strdef._initial_cursor_col]
  mov	ah,[ebp+strdef._display_row]
  call	move_cursor			;position cursor
;read keyboard
  call	read_stdin
;decode keys or clicks
  cmp	byte [kbuf],-1
  jne	gs_30				;jmp if not mouse click
  mov	al,[ebp+strdef._display_row]
  cmp	byte [kbuf + 3],al		;check if mouse click on edit line
  jne	gs_exit				;jmp if mouse not on edit line
gs_20:
  call	process_mouse
  jmp	short gs_40			;go look at exit code
;process key press
gs_30:
  mov	esi,key_action_tbl
  call	key_decode1
  call	eax
;any non zero return tells us to exit
gs_40:
  or	al,al
  jns	gs_loop				;loop for another key
;exit and return registers
gs_exit:
  mov	ah,[ebp+strdef._initial_cursor_col]
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
  mov	bl,[kbuf]
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
  mov	al,[kbuf]			;get char
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
; set cursor from mouse click
; we know the click occured on edit line, but it may
; not be in our window.
process_mouse:
  mov	al,[kbuf+2]			;get mouse column
  mov	ah,[ebp+strdef._display_column]	;get starting column
  cmp	al,ah
  jb	unknown_input			;exit if left of string
  cmp	al,[win_end_col]		;check window end
  ja	unknown_input			;exit if right of string entery  
;compute new cursor posn
  xor	ecx,ecx
  mov	cl,al				;get click column
  xor	ebx,ebx
  mov	bl,[ebp+strdef._initial_cursor_col]		;get current column
  sub	ecx,ebx
  mov	[ebp+strdef._initial_cursor_col],al		;use mouse click column
  add	[str_ptr],ecx			;adjust pointer
  xor	eax,eax			;normal return
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
  mov	eax,[ebp+strdef._color_ptr] ;get color ptr
  mov	eax,[eax]		;get color
  call	crt_set_color

  mov	ah,[ebp+strdef._display_row];get row
  mov	al,[ebp+strdef._display_column]	;display column
  call	move_cursor

  mov	ecx,[ebp+strdef._data_buffer_ptr]
  add	ecx,[ebp+strdef._scroll]
  xor	edx,edx
  mov	dl,[ebp+strdef._window_size]
  call	crt_write
  ret
;------------------------------------------------
;check if crt_columns and crt_rows set
;process callers inputs
;check display window size
;clear line or line end

initialize:
  mov	eax,[ebp+strdef._data_buffer_ptr]
  add	eax,[ebp+strdef._buffer_size] ;compute end of buffer
  mov	[buf_end],eax

;check if physical screen size available
  cmp	[crt_columns],byte 0
  jne	init_10
  call	read_window_size
init_10:
  mov	al,[ebp+strdef._window_size]
  add	al,[ebp+strdef._display_column]  ;compute window end
  dec	al			;adjust for testing
;check if win_end_col is legal, (fits our screen)
  cmp	al,[crt_columns]
  jbe	init_18		;jmp if window ok
  mov	al,[crt_columns]
init_18:
  mov	[win_end_col],al

; set str_ptr
  mov	edi,[ebp+strdef._data_buffer_ptr]
  xor	eax,eax
  mov	al,[ebp+strdef._initial_cursor_col]
  sub	al,[ebp+strdef._display_column]
  add	edi,eax
  mov	[str_ptr],edi			;set edit point
  ret

;------------------------------------------------
; This  table is used by get_text to decode keys
;  format: 1. first dword = process for normal text
;          2. series of key-strings & process's
;          3. zero - end of key-strings
;          4. dword = process for no previous match
;
key_action_tbl:
  dd	gs_normal_char		;alpha key process
  db 1bh,5bh,48h,0		; pad_home
   dd gs_home
  db 1bh,5bh,31h,7eh,0		;138 home (non-keypad)
   dd gs_home
  db 1bh,4fh,77h,0		;150 pad_home
   dd gs_home
  db 1bh,5bh,44h,0		; pad_left
   dd gs_left
  db 1bh,4fh,74h,0		;143 pad_left
   dd gs_left
  db 1bh,5bh,34h,7eh,0		;139 end (non-keypad)
   dd gs_left
  db 1bh,5bh,43h,0		; pad_right
   dd gs_right
  db 1bh,4fh,76h,0		;144 pad_right
   dd gs_right
  db 1bh,5bh,46h,0		; pad_end
   dd gs_end
  db 1bh,4fh,71h,0		;145 pad_end
   dd gs_end
  db 1bh,5bh,33h,7eh,0		; pad_del
   dd gs_del
  db 1bh,4fh,6eh,0		;149 pad_del
   dd gs_del
  db 7fh,0			; backspace
   dd gs_backspace
  db 80h,0
   dd gs_backspace
  db 08,0			;140 backspace
   dd gs_backspace
  db 0		;end of table
  dd unknown_input		;no-match process


 [section .data align=4]

;-----------------------------------------------------------

buf_end		dd	0	;one location beyond data in buffer
str_ptr		dd	0	;current string edit point
win_end_col	db	0	;window end column (inside window) 

 [section .text]
;----------------------------------------------------------
%ifdef DEBUG
 extern mouse_enable
 extern env_stack
 global _start
 global main
_start:
main:    ;080487B4
  call	env_stack
  call	mouse_enable
  mov	ebp,string_block
  call	get_text

  mov	eax,1
  int	80h

  [section .data]
buf0 db "123"
     db -1
     db -1

string_block:
data_buffer_ptr    dd buf0 ;+0    cleared or preload with text
buffer_size        dd 1	 ;+4    buffer size 
color_ptr          dd color1 ;+8    (see file crt_data.asm)
display_row        db   1 ;+12   ;row (1-x)
display_column     db   1 ;+13   ;column (1-x)
initial_cursor_col db   1 ;+15   ;must be within data area
window_size        dd   1 ;+16   bytes in window
scroll             dd   0

color1	dd	30003537h

  [section .text]
%endif
