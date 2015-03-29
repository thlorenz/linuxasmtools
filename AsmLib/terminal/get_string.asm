
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
  call	get_string

  mov	eax,1
  int	80h

  [section .data]
string_block:
data_buffer_ptr    dd buf0 ;+0    cleared or preload with text
buffer_size        dd 3	 ;+4    buffer size 
color_ptr          dd color1 ;+8    (see file crt_data.asm)
display_row        db   1 ;+12   ;row (1-x)
display_column     db   1 ;+13   ;column (1-x)
sflags             db   00000000b  ;+14   ;see notes
initial_cursor_col db   1 ;+15   ;must be within data area
window_size        dd   2 ;+16   bytes in window

color1	dd	30003730h
buf0 db 0,0,0
     db -1
     db -1
buf1 db 't',0,0,0,0,0
buf2 db 'te',0,0,0,0
buf3 db 'tes',0,0,0
buf4 db 'test',0,0
dbp_end:

  [section .text]
%endif
;-------------------------------------------

  extern  move_cursor
  extern  read_stdin
  extern  kbuf
  extern  key_decode1
  extern  lib_buf
  extern  crt_columns,crt_rows
  extern  read_window_size
  extern  crt_color_at

struc strdef
._data_buffer_ptr    resd 1 ;+0    cleared or preload with text
._buffer_size        resd 1 ;+4    buffer size, must be >= window size
._color_ptr          resd 1 ;+8    (see file crt_data.asm)
._display_row        resb 1 ;+12   ;row (1-x)
._display_column     resb 1 ;+13   ;column (1-x)
._sflags             resb 1 ;+14   ;see notes
._initial_cursor_col resb 1 ;+15   ;must be within data area
._window_size        resd 1 ;+16   bytes in window
endstruc
;sflags equates
allow_0dh      equ 00000001b ; allow 0d/0a in output string.
clr_buf        equ 00000010b ; clear buffer.
no_home_key    equ 00000100b ; disable the Home,End keys
no_scroll_keys equ 00001000b ; disable the right,left scroll keys
return_keys    equ 00010000b ; return unknown or unprocessed keys,
                             ; use keep_settings flag to continue
buf_eq_win     equ 00100000b ; use _buffer_size for _window_size and
no_extra_field equ 01000000b ; ignore both the _initial_cursor_col and
keep_settings  equ 10000000b ; continue, do not initialize any settings

;****f* key_mouse/key_string1 *
; NAME
;>1 terminal
;  get_string - get string in scrolled window line
;    Read string into buffer using optional window size.
;    Unknown keys can be returned to caller for processing
;    or ignored by get_string.
; INPUTS
;    ebp= pointer to table with following structure:
;
;    struc strdef
;    ._data_buffer_ptr    resd 1 ;+0    cleared or preload with text (see note)
;    ._buffer_size        resd 1 ;+4    buffer size, > or = window_size
;    ._color ptr          resd 1 ;+8    (see file crt_data.asm)
;    ._display_row        resb 1 ;+12   ;row (1-x)
;    ._display_column     resb 1 ;+13   ;column (1-x)
;    ._sflags             resb 1 ;+14   ;see notes
;    ._initial_cursor_col resb 1 ;+15   ;must be within data area
;    ._window_size        resd 1 ;+16   bytes in window
;    endstruc
;
;    note: get_string is always in insert mode and end of string
;      has a zero character.  The _sflags byte defines operations
;    note: The buffer must have 2 extra bytes at end for overflow.
;    
;    _sflags = 00000001b = allow 0d/0a in output string.  the ESC
;                          character terminates string entry.  Normally
;                          string entry is terminated by Enter key.
;              00000010b = clear buffer.
;              00000100b = disable the Home,End keys
;                          if bit 000100000b is set they are
;                          returned in global "key_buf" for processing
;              00001000b = disable the right,left scroll keys
;                          if bit 000100000b is set they are returned
;                          in the global "key_buf"  for processing
;              00010000b = return unknown or unprocessed keys, to
;                          continue entering data, set 10000000b
;                          and call get_string again.
;              00100000b = use _buffer_size for _window_size and
;                          ignore the _window_size field
;              01000000b = ignore both the _initial_cursor_col and
;                          _window_size fields.  The _window_size will
;                          be set to _buffer_size and _initial_cursor_col
;                          will be set to end of string
;              10000000b = continue, do not initialize any settings
;
;
;    notes: The Initial cursor column must equal the display column
;      or within the range of "display_column" + window_size"
;      Thus, if "display_column=5" and "window_size"=2 then
;      "initial cursor" can be 5 or 6
;      Setting the initial cursor column to zero will put it at
;      end of any string found at _data_buffer_ptr
;      If window_size extends beyond physical right edge of screen
;      it will be truncated.
;           
; OUTPUT
;    ebp=pointer to input table (unchanged)
;    al=0 data in buffer,  <Enter> char in kbuf
;         the enter char will always be 0ah if "Enter"
;         key was pressed and 1bh if ESC was enabled
;         by the allow_0a flag
;    al=1 mouse click, buffer may have data
;    al=2 unprocessed char in kbuf
;    ah=current cursor column
;    ecx=string size
;
; EXAMPLE
;    call  mouse_enable	;library call to enable mouse
;    mov  ebp,string_block
;    and  [ebp+strdef._sflags],byte ~keep_settings
;  key_loop:
;    call get_string
;    and  [ebp+strdef,_sflags],byte keep_settings
;    cmp  al,2		;check if ignored key or mouse
;    jae  key_loop	;go back and keep reading
;    jmp  process_string
;
;    [section .data]
;   string_block:
;   data_buffer_ptr    dd buf ;+0    cleared or preload with text
;   buffer_size        dd 100 ;+4    buffer size
;   color_ptr          dd color1 ;+8    (see file crt_data.asm)
;   display_row        db   1 ;+12   ;row (1-x)
;   display_column     db   1 ;+13   ;column (1-x)
;   sflags             db   00000000b  ;+14   ;see notes
;   initial_cursor_col db   1 ;+15   ;must be within data area
;   window_size        dd  80 ;+16   bytes in window
;
;   color1 dd 30003730h
;   buf times buffer_size+2 db 0
;
; NOTES
;   source file: get_string.asm
;   see also, get_text
;<
; * ----------------------------------------------
;*******

  global get_string
get_string:
  test	[ebp+strdef._sflags],byte keep_settings
  jnz	gs_10				;jmp if no init
  call	initialize
gs_10:
;
gs_loop:
;check cursor, the str_ptr is used to set cursor and scroll
;  call	set_cursor		;needed?
;display string
  call	display_string
  mov	al,[str_cursor_col]
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
  js	gs_loop				;loop for another key
;setup return registers for caller
;return codes returned are:
;  0=enter key or esc key pressed (see kbuf)
;  1=mouse event, outside edit line
;  2=unprocessed or unknown char. in kbuf
;exit and return registers
gs_exit:
  mov	ah,[str_cursor_col]
  ret

;------------------------------------------------
; keyboard processing
;------------------------------------------------
gs_ignore_char:
  mov	al,-1
  ret
;-------------
return_key_check:
  test	[ebp+strdef._sflags],byte return_keys
  jz	gs_ignore_char
  mov	al,2
  ret
;-------------
gs_normal_char:
  mov	ebx,[buf_end]
  mov	eax,[str_ptr]
  cmp	eax,ebx      			;check if room for another char
  je	gs_ignore_char			;jmp if no room
;
; make hole to stuff char
;
  std
  mov	edi,[buf_end]
  mov	esi,edi
  inc	edi
gs_21:
  movsb
  cmp	edi,eax				;are we at hole
  jne	gs_21
  cld
  mov	al,[kbuf]			;get char
  mov	byte [edi],al
  mov	edi,[buf_end]
  mov	byte [edi],0			;zero out any overflow char
  jmp	short gs_right_entry
;-----------------
gs_right:
  test	[ebp+strdef._sflags],byte no_scroll_keys
  jnz	return_key_check
gs_right_entry:
  mov	esi,[str_ptr]
  inc	esi
  cmp	esi,[buf_end]			;check if buffer ok
  jae	gs_right_exit			;jmp if no more buffer

  mov	al,[str_cursor_col]
  cmp	al,[win_end_col]
  je	gs_right_scroll			;jmp if at right edge
;display ok to > buffer space ok also
  cmp	byte [esi-1],0			;were we sitting on a zero
  je	gs_right_exit			;ignore if trying to move into zeros

  inc	byte [str_cursor_col]		;move cursor fwd
  inc	dword [str_ptr]			;move ptr fwd
  jmp	short gs_right_exit

gs_right_scroll:
  cmp	[esi -1],byte 0			;were we sitting on a zero
  je	gs_right_exit			;exit if no data ahead
  inc	dword [scroll]
  inc	dword [str_ptr]  
gs_right_exit:
  mov	al,-1				;normal return
  ret

;-----------------
gs_home:
  test	[ebp+strdef._sflags],byte no_home_key
  jnz	return_key_check		;check if caller wants this key	
  mov	[scroll],dword 0
  mov	eax,[ebp+strdef._data_buffer_ptr]
  mov	[str_ptr],eax
  mov	[str_cursor_col],byte 1
  mov	al,-1
  ret
;-----------------
gs_end:
  test	[ebp+strdef._sflags],byte no_home_key
  jnz	return_key_check		;check if caller wants this key	
;scan to end of string
  mov	esi,[ebp+strdef._data_buffer_ptr]
  mov	bl,[ebp+strdef._display_column]
gs_end_lp:
  cmp	[esi],byte 0			;check if at end of data
  je	gs_end_50			;jmp if at end of data
  cmp	esi,[buf_end]			;check for specail cas at end
  je	gs_end_50
  cmp	bl,[win_end_col]
  jne	gs_end_10			;jmp if not at end of widow
  inc	dword [scroll]
  dec	bl
gs_end_10:
  inc	esi
  inc	bl
  jmp	short gs_end_lp
;esi points at end  bl=column  [scroll] is updated
gs_end_50:
  cmp	esi,[buf_end]
  jne	gs_end_60			;jmp if not special case
  dec	esi
  cmp	[scroll],dword 0
  je	gs_end_55
  dec	dword [scroll]
  jmp	short gs_end_60
gs_end_55:
  dec	bl
  jmp	short gs_end_70
gs_end_60:
  mov	[str_ptr],esi
  mov	[str_cursor_col],bl
gs_end_70:
  mov	al,-1
  ret

;-----------------
gs_left:
  test	[ebp+strdef._sflags],byte no_scroll_keys
  jnz	return_key_check		;check if caller wants this key	
  mov	eax,[str_ptr]
  cmp	eax,[ebp+strdef._data_buffer_ptr]
  je	gs_ignore_char			;jmp if at beginning of buffer
  mov	al,[str_cursor_col]		;get cursor posn
  cmp	al,[ebp+strdef._display_column]
  je	gs_left_scroll			;jmp if at left edge already

  dec	byte [str_cursor_col]
  dec	dword [str_ptr]
  jmp	gs_left_exit

gs_left_scroll:
  cmp	dword [scroll],0
  je	gs_left_exit
  dec	dword [scroll]
  dec	dword [str_ptr]
gs_left_exit:
  mov	al,-1
  ret

;-----------------
gs_del:
  mov	ebx,[buf_end]
  inc	ebx           			;move to zero at end of buf
  mov	esi,[str_ptr]
  mov	edi,esi
  inc	esi
gs_27:
  movsb
  cmp	edi,ebx				;[str_end]
  jne	gs_27
  mov	al,-1
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
  mov	byte [edi],0			;blank prev. position
  cmp	esi,[buf_end]
  jbe	gs_bak_lp			;loop till everything moved
;update pointers and check for scroll
  mov	bl,[str_cursor_col]
  cmp	bl,[ebp+strdef._display_column]	;are we at left edge
  je	gs_bak_20			;jmp if at edge
;normal backspace inside string
  dec	dword [str_ptr]
  dec	byte [str_cursor_col]
  jmp	short gs_bak_exit
;backspace at left edge of window
;we can assume [scroll] is non zero because of previous buffer check
gs_bak_20:
  dec	dword [scroll]
  dec	dword [str_ptr]
gs_bak_exit:
  mov	al,-1
  ret

;-----------------
gs_enter_key:
  mov	[kbuf],byte 0ah		;force enter key to be 0ah
  test	[ebp+strdef._sflags],byte allow_0dh
  jz	gs_enter_10		;jmp if <Enter> is return char
  jmp	gs_normal_char		;jmp if "Enter" is normal char
gs_enter_10:
  xor	eax,eax
  ret
;-----------------
gs_escape_key:
  mov	al,0			;preload esc=return code
  test	[ebp+strdef._sflags],byte allow_0dh
  jnz	gs_escape_10		;jmp if escape is return char
  mov	al,3
gs_escape_10:
  ret  
;-----------------
gs_passkey_done:
  jmp	return_key_check
;------------------------------------------------
; set cursor from mouse click
; we know the click occured on edit line, but it may
; not be in our window.
process_mouse:
  mov	al,[kbuf+2]			;get mouse column
  mov	ah,[ebp+strdef._display_column]	;get starting column
  cmp	al,ah
  jb	gs_passkey_done			;exit if left of string
  cmp	al,[win_end_col]		;check window end
  ja	gs_passkey_done			;exit if right of string entery  
;compute new cursor posn
  xor	ecx,ecx
  mov	cl,al				;get click column
  xor	ebx,ebx
  mov	bl,[str_cursor_col]		;get current column
  sub	ecx,ebx
  mov	[str_cursor_col],al		;use mouse click column
  add	[str_ptr],ecx			;adjust pointer
  mov	al,-1
  ret
;------------------------------------------------
;  input:  ebp -> data buffer ptr         +0    (dword)  has zero or preload
;                 buffer_size             +4    (dword)
;                 color ptr               +8    (dword)
;                 display row             +12   (db)	;str display loc
;                 display column          +13   (db)
;          [win_end_col] = end of display
;          [scroll] = amount of data to skip over
;          
display_string:
  mov	edi,lib_buf
  mov	esi,[ebp]		;get buffer to display
  mov	ecx,[scroll]
  mov	bl,[ebp+strdef._display_column]
;
; build string in lib_buf buffer
;
dsg_10:
  cmp	byte [esi],0		;end of data found
  je	dgs_30			;jmp if at end of preloaded data
  lodsb
  jecxz	dsg_40
  dec	ecx
  jmp	short dsg_10		;ignore this data
dgs_30:
  mov	al,' '			;store blank
dsg_40:
  cmp	al,20h
  jb	dsg_42			;jmp if non ascii
  cmp	al,7fh
  jb	dsg_44			;jmp if char normal ascii
dsg_42:
  mov	al,'.'			;substitute "." for char
dsg_44:
  stosb
  inc	bl			;move to next column
  cmp	bl,[win_end_col]	;check if done
  jbe	dsg_10			;loop till done
  mov	byte [edi],0		;terminate string
;
; display string area
;  
  mov	eax,[ebp+strdef._color_ptr] ;get color ptr
  mov	eax,[eax]		;get color
  mov	bh,[ebp+strdef._display_row];get row
  mov	bl,[ebp+strdef._display_column]	;display column
  mov	ecx,lib_buf		;get msg address
  call	crt_color_at		;display message
  ret
;------------------------------------------------
;set str_cursor_col from str_ptr
;set left_edge_ptr from above
set_cursor:
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
;check if _window_size available, and set win_end_col
  test	[ebp+strdef._sflags],byte buf_eq_win + no_extra_field
  jz	init_14		;jmp if winsize available
  mov	al,[ebp+strdef._buffer_size]
  jmp	short init_16
init_14:
  mov	al,[ebp+strdef._window_size]
init_16:
  add	al,[ebp+strdef._display_column]  ;compute window end
  dec	al			;adjust for testing
;check if win_end_col is legal, (fits our screen)
  cmp	al,[crt_columns]
  jbe	init_18		;jmp if window ok
  mov	al,[crt_columns]
init_18:
  mov	[win_end_col],al

;check if clear buffer needed
  mov	edi,[ebp+strdef._data_buffer_ptr]
  cmp	[edi],byte 0
  jz	init_50			;jmp if first byte of buffer=0
  test	[ebp+strdef._sflags],byte clr_buf
  jz	init_19			;jmp if clear buffer flag not set
  jmp	short init_50
;the buffer has data,  win_end_col,buf_end have been set'
;loop through buffer to set str_ptr,scroll, etc
; edi=buffer ptr  al=win_end_col
init_19:
  mov	ah,[ebp+strdef._display_column]	;starting column for loop
  xor	esi,esi				;scroll
  mov	ebx,esi				;clear have_cursor and clear flags
; registers edi=buffer  esi=scroll  al=end column  ah=current column
;           bh=have cursor flag   bl=clear buffer here flag
init_20:
  or	bl,bl			;check if clearing buffer
  jz	init_25			;jmp if not clearing
  mov	[edi],byte 0
  jmp	short init_40
init_25:
  cmp	[edi],byte 0		;data in buffer
  jnz	init_30			;jmp if buffer has data
  or	bl,1			;set rest of buffer flag
  or	bh,bh			;do we have pointer yet?
  jz	init_35			;jmp if no pointer yet
init_30:
  cmp	ah,[ebp+strdef._initial_cursor_col]
  jb	init_40			;if not time to set cursor
  or	bh,bh			;check if cursor set yet
  jnz	init_40			;jmp if cursor set already
;check for special case of _initial_cursor_col =0 (set to end)
  cmp	[ebp+strdef._initial_cursor_col],byte 0
  je	init_40			;jmp if special case, set cursor to end
;set cursor position here
init_35:
  or	bh,1			;set cursor set flag
  mov	[scroll],esi		;set scroll
  mov	[str_ptr],edi		;set buffer pointer
  mov	[str_cursor_col],ah	;set cursor column
init_40:
  inc	edi			;bump buffer ptr
  inc	ah			;bump column
  cmp	ah,al 			;are we at right edge?
  jbe	init_45			;jmp if inside window
  cmp	bl,0			;are we clearing buffer
  jne	init_45			;jmp if clearing buffer (aviod scroll check)
;start to scroll
  inc	esi			;bump scroll
  dec	ah			;move back on column
init_45:
  cmp	edi,[buf_end]  
  jb	init_20			;jmp if more data in buffer

  or	bh,bh			;did we set pointers?
  jnz	init_60			;jmp if pointers set
;set pointers to default state at start of window
init_50:
  mov	ecx,[ebp+strdef._buffer_size]
  xor	eax,eax
  rep	stosb			;clear the buffer
  mov	eax,[ebp+strdef._data_buffer_ptr]
  mov	[str_ptr],eax		;set current edit point
  mov	al,[ebp+strdef._display_column]
  mov	[str_cursor_col],al	;set initial cursor
  xor	eax,eax
  mov	[scroll],eax		;set scroll for left edge
init_60:
  ret

;------------------------------------------------
; This  table is used by get_string to decode keys
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
  db 0dh,0			; enter key
   dd gs_enter_key
  db 0ah,0
   dd gs_enter_key		;
  db 1bh,0
   dd gs_escape_key
  db 0		;end of table
  dd gs_passkey_done		;no-match process


 [section .data align=4]

;-----------------------------------------------------------

buf_end		dd	0	;max string ptr
str_ptr		dd	0	;current string edit point
scroll		dd	0	;left window edge adjust, arrow key set this
str_cursor_col	db	0	;current cursor column
win_end_col	db	0	;window end column (inside window) 

 [section .text]
