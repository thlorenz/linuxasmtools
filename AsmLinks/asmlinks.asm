
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
;--------------------------------------------------------------
;>1
; AsmLinks - view file with links
;
;    usage: asmlinks <file>
;
;    operation:
;    ----------
;          up key - scroll up
;          down key - scroll down
;          pgup key - page up
;          pgdn key - page down
;          right,left - scroll
;          esc   - exit
;          f10   = exit
;          f3    = exit
;          enter key - begin/repeat  search
;          f1 - help
;          home - goto top of file
;          end = goto end of file
;
;<
;-------------------------------------------------------------------------             

; Compile with:  nasm -felf xxxx.asm -o xxxx.o
;                ld xxxx.o -o xxxx

  extern  file_open_rd
  extern  crt_clear
  extern  key_decode1
  extern  kbuf
  extern  file_read
  extern  crt_set_color
  extern  message_box
  extern  blk_find
  extern set_memory
  extern read_window_size
  extern crt_rows,crt_columns
  extern str_move
  extern crt_str
  extern read_stdin
  extern install_signals
;  extern  crt_win_from_ptrs
%include "crt_win_from_ptrs.inc"
%include "show_line.inc"
  extern crt_line
;%include "key_string.inc"
  extern get_text
  extern reset_clear_terminal

  [section .text]

fbuf_size  equ	60000
%include "includes.inc"

%include "history.inc"

 bits 32
 global _start,main

;-------------------------------------------------------------------
begin:    
_start:    
  cld
  mov	eax,45			;brk function call
  xor	ebx,ebx			;request memory
  int	byte 80h
  mov	[filebuffer],eax	;save memory start
  add	eax,fbuf_size
  mov	ebx,eax
  mov	eax,45			;brk function call
  int	byte 80h		;allocate memory
  mov	[filebuffer_end],eax
;get filename parameters from caller
  mov	esi,esp			;get stack ptr
  lodsd				;get parameter count
  cmp	al,2
  je	link_10			;jmp if possible file given
  mov	ecx,usage_msg
  call	crt_str
  jmp	do_exit3		;exit if wrong parms
link_10:
  lodsd				;get program name ptr
  lodsd				;get filename parameter
  mov	esi,eax
  mov	edi,path_buf
  call	str_move
  mov	ebx,path_buf
  call	file_open_rd		;returns eax=fd else error
  mov	[fd],eax
  test	eax,eax
  jns	short setup		;jmp if file opened ok
;error file not found?
err_exit:
;error exit
  mov	ebx,1
  jmp	do_exit2
  
setup:
  call	signal_install
  call	win_setup
get_file:
  call	read_file		;read file
  call	init_lines		;initialize lines structure
  call	history_setup
  call	find_first_link		;look for link in this page
  mov	eax,[screen_color]
  call	crt_clear
display_page:    
  call	near write_lines	;display lines
;add status line to end of display
  call	display_status_line

  call	read_stdin
  cmp	[window_resize_flag],byte 0
  je	process_input
  call	win_setup
  jmp	short display_page

process_input:
  cmp	byte [kbuf],-1
  jne	keypress
  call	mouse
  jmp	call_key_process
keypress:
  mov	esi,key_decode_table
  call	key_decode1		;returns process to call in eax

;call key processng function

call_key_process:    
  mov	ecx,dword [page_top_line#]
  mov	edx,dword [last_line#]
  movzx	ebp,word [crt_rows]	;get total rows in window
  call	eax ;<------------------------------
  jmp	near display_page

;----------------------------
  [section .data]
key_decode_table:
  dd	unknown_key		;ignore (alpha key)

  db 1bh,5bh,5bh,41h,0		;127 F1
  dd help_key

  db 1bh,4fh,50h,0		;123 F1
  dd help_key

  db 1bh,4fh,50h,0		;123 F1
  dd help_key

  db 1bh,5bh,41h,0		;15 pad_up
  dd event_key_up

  db 1bh,4fh,41h,0		;15 pad_up
  dd event_key_up

  db 1bh,4fh,78h,0		;15 pad_up
  dd event_key_up

  db 1bh,5bh,42h,0		;20 pad_down
  dd event_key_down

  db 1bh,4fh,42h,0		;20 pad_down
  dd event_key_down

  db 1bh,4fh,72h,0		;20 pad_down
  dd event_key_down

  db 1bh,5bh,43h,0		;18 pad_right
  dd select_link

  db 1bh,4fh,43h,0		;18 pad_right
  dd select_link

  db 1bh,4fh,76h,0		;18 pad_right
  dd select_link    

  db 1bh,5bh,44h,0		;17 pad_left
  dd terminate

  db 1bh,4fh,44h,0		;17 pad_left
  dd terminate

  db 1bh,4fh,74h,0		;17 pad_left
  dd terminate

  db 1bh,5bh,35h,7eh,0		;16 pad_pgup
  dd event_key_pgup

  db 1bh,4fh,79h,0		;16 pad_pgup
  dd event_key_pgup

  db 1bh,5bh,36h,7eh,0		;21 pad_pgdn
  dd event_key_pgdown

  db 1bh,4fh,73h,0		;21 pad_pgdn
  dd event_key_pgdown

  db 1bh,5bh,32h,31h,7eh,0	;11 f10
  dd terminate

  db 1bh,0			;ESC
  dd terminate

  db 1bh,5bh,5bh,42h,0		;128 f2
  dd find      

  db 1bh,4fh,51h,0		;123 F2
  dd find

  db 1bh,5bh,31h,32h,7eh,0	;3 f2
  dd find

  db 1bh,5bh,31h,33h,7eh,0	;4 f3
  dd find_again

  db 1bh,4fh,52h,0		;123 F3
  dd find_again

  db 1bh,5bh,5bh,43h,0		;129 f3
  dd find_again

  db 1bh,5bh,46h,0		;19 pad_end
  dd event_key_end

  db 1bh,4fh,71h,0		;145 pad_end
  dd event_key_end

  db 1bh,4fh,46h,0		;pad end
  dd event_key_end

  db 1bh,5bh,48h,0		;14 pad_home
  dd event_key_home

  db 1bh,4fh,77h,0		;150 pad_home
  dd event_key_home

  db 1bh,4fh,48h,0		;pad home
  dd event_key_home

  db 0dh,0			;enter key
  dd select_link

  db 0ah,0			;enter key
  dd select_link

  db 0		;enc of table
  dd unknown_key ;unknown key trap
;---------------------------------------
  [section .text]
;
; alpha keys and unknown keys are returned here
;
unknown_key:
	cmp	word [kbuf],0020h	;space bar
	jne	uk_exit
	call	event_key_down
uk_exit:
	ret
;=====================================================
;                  begin key events
;=====================================================
; ecx = page_top_line#
; edx = last_line#
; ebp = total rows in window
select_link:
  mov	esi,path_buf
  call	put_string		;save current path
  mov	eax,[page_top_line#]
  call	put_dword
  mov	eax,[selector_ptr]
  call	put_dword
;find new selection path
  mov	esi,[selector_ptr]
  call	search_select_list
  jnc	sl_err			;exit if not found
  mov	esi,ebx			;esi = ptr to <xxxx>=path  
;scan to start of path
sl_loop:
  lodsb
  cmp	al,'='
  je	sl_20
  cmp	al,0ah
  je	sl_err
  jmp	short sl_loop
sl_20:
  mov	edi,path_buf
sl_loop2:
  lodsb
  cmp	al,0ah
  je	sl_40		;jmp if end of path
  stosb
  jmp	short sl_loop2
sl_40:
  xor	eax,eax
  stosb			;put zero at end
;entry point - terminate jmps here
sl_new_file:
;open file
  mov	ebx,path_buf
  call	file_open_rd		;returns eax=fd else error
  or	eax,eax
  js	sl_err
  mov	[fd],eax
  mov	[page_top_line#],dword 0

  call	read_file		;read file
  call	init_lines		;initialize lines structure
  call	find_first_link		;look for link in this page
  jmp	short sl_exit
sl_err:
  mov	edi,path_buf
  call	pop_string
  call	pop_dword
  mov	[selector_ptr],eax
  call	pop_dword
  mov	[page_top_line#],eax
sl_exit:
  ret
;===============
;terminate goes back one level each entry.  When pop_string
;gets to top of its stack we exit.
terminate:
  mov	edi,path_buf
  call	pop_string
  jc	do_exit			;exit if at top
;open file
  mov	ebx,path_buf
  call	file_open_rd		;returns eax=fd else error
  or	eax,eax
  js	term_err
  mov	[fd],eax

  call	read_file		;read file
  call	init_lines		;initialize lines structure

term_err:
  call	pop_dword
  mov	[selector_ptr],eax
  call	pop_dword
  mov	[page_top_line#],eax
  ret

;+++=======
do_exit:    
  xor	ebx,ebx
do_exit2:
  push	ebx
;  mov	eax,[screen_color]
;  call	crt_clear
;  mov	ax,0101h
;  call	move_cursor
  call	reset_clear_terminal
  pop	ebx			;restore exit code
do_exit3:
  push	byte 01H
  pop	eax
  int	byte 080H
;==============
; ecx = page_top_line#
; edx = last_line#
; ebp = total rows in window
;
; start from [selector_ptr] and go up looking for
; another selector.  Top of buffer is [filebuffer]
; When done adjust page_top_line# if necessary.
; Use page_top_line# to index into ptr_to_line_ptrs
event_key_up:
  call	find_prev_link
  jc	eku_10		;jmp if prev selector found
;no  selector was found, move up
  mov	ecx,[page_top_line#]
  jecxz	eku_exit	;exit if at top
  dec	ecx
  jmp	short eku_20	;set new top

eku_10:
  mov	[selector_ptr],esi
;check if this selector is in current page
; esi=ptr ecx=line# ebx=ptr to ptr
  cmp	ecx,[page_top_line#]
  jae	eku_exit		;jmp if on page
eku_20:
  mov	[page_top_line#],ecx	;set new page top
eku_exit:
  ret
;=============
; ecx = page_top_line#
; edx = last_line#
; ebp = total rows in window
event_key_down:
  call	find_next_link
  jnc	ekd_05		;jmp if no selector found
;check if within page
  mov	[selector_ptr],esi
  mov	edx,[page_top_line#]
  add	edx,[crt_rows]	;compute end of screen line#
  cmp	ecx,edx
  jb 	ekd_exit	;jmp if within this page
;check if another page avail
  cmp	edx,[last_line#]
  jbe	ekd_04
;we are at end of data buffer, less than page remaining
  mov	ecx,[last_line#]
  sub	ecx,[crt_rows] ;compute amount remaining
  jmp	short ekd_10
ekd_04:
  mov	ecx,edx
  jmp	short ekd_10
;no selector was found, can we scroll down
ekd_05:
  mov	ecx,[last_line#]
  sub	ecx,[crt_rows]
  js	ekd_exit	;exit if less than page
  cmp	ecx,[page_top_line#]
  jb	ekd_exit	;exit if last page on screen  
  mov	ecx,[page_top_line#]
  inc	ecx
ekd_10:
  mov	[page_top_line#],ecx
ekd_exit:
  ret
;=============
; ecx = page_top_line#
; edx = last_line#
; ebp = total rows in window
event_key_pgdown:    
  add	ecx,[crt_rows]
  cmp	ecx,edx			;beyond end?
  jae	ekpd_exit
;check if full page remains
  add	ecx,[crt_rows]
  cmp	ecx,edx
  jb	ekp_20
;less than page remains
  mov	ecx,[last_line#]
  sub	ecx,[crt_rows] ;compute amount remaining
  jmp	short ekpd_30  
ekp_20:
  sub	ecx,[crt_rows]
ekpd_30:
  mov	[page_top_line#],ecx
  call	find_first_link
ekpd_exit:
  ret
;===============
; ecx = page_top_line#
; edx = last_line#
; ebp = total rows in window
event_key_pgup:    
  sub	ecx,[crt_rows]
  jns	ekpu_20		;jmp if pgup ok
  xor	ecx,ecx
ekpu_20:
  mov	[page_top_line#],ecx		;set page to line#
  call	find_first_link
ekp_exit:
  ret
;===============
; ecx = page_top_line#
; edx = last_line#
; ebp = total rows in window
event_key_end:
  sub	edx,ebp
  js	eke_exit	;exit if less than one page
  mov	[page_top_line#],edx
eke_exit:
  ret
;===============
; ecx = page_top_line#
; edx = last_line#
; ebp = total rows in window
event_key_home:    
  xor	ecx,ecx
  mov	[page_top_line#],ecx				;set page to line#
  ret
;===============
; ecx = page_top_line#
; edx = last_line#
; ebp = total rows in window
find:
  mov	ebp,string_table
  call	get_text
  mov	edi,[page_top_line#]	;line ptr index
  jmp	short find_again_entry
;===============
find_again:
  mov	edi,[page_top_line#]	;line ptr index
  cmp	edi,[last_line#]
  jae	find_again_entry
  inc	edi
find_again_entry:
  mov	ebp,[ptr_to_line_ptrs]	;get end of buffer
;put zero at end of match string
  mov	esi,string_buf_end
fa_lp:
  dec	esi
  cmp	[esi],byte ' '
  je	fa_lp			;move back to non space
  inc	esi
  mov	byte [esi],0		;put zero at string end
  push	esi			;save mod poinnt

  mov	esi,string_buf		;match string ptr
  xor	eax,eax			;adjust if on match=0
  cmp	edi,[last_match_line#]
  jne	fa_10			;jmp if not at match
  add	eax,byte 4		;set match adjustment
fa_10:
  shl	edi,2
  add	edi,[ptr_to_line_ptrs]
  mov	edi,[edi+eax]		;start search on next line  
;check if at end of file
  or	edi,edi
  jnz	fa_15		;jmp if inside file
  jmp	not_found
fa_15:
  mov	edx,1		;forward search
  mov	ch,0dfh		;ignore case
  call	blk_find
  jc	not_found
;ebx=match point, find line#
  mov	esi,ebx
  call	adr2line
  mov	[page_top_line#],ecx
  jmp	find_exit

not_found:
  mov	[status_color_num],byte 5
  mov	esi,not_fnd_msg
  mov	edi,status_msg_insert
  mov	ecx,not_fnd_msg_end - not_fnd_msg
  rep	movsb
find_exit:
  call	find_first_link
find_exit2:
  pop	esi			;restore mod point
  mov	byte [esi],' '		;fix string_buf
  ret
;----------------------
  [section .data]

string_table:
  dd	string_buf	;ptr to string buffer
max_string_len:
  dd	30		;max string len
  dd	string_color
str_row:
  db	0		;row
  db	12		;column
str_adj:
  db	12		;initial cursor column
  dd	30		;window size
  dd	0		;scroll

;string_buf:  times 32 db ' '



not_fnd_msg:
  db ' * not found * '
not_fnd_msg_end:

match_found_flag	db	0
last_match_line#	dd	-1

  [section .text]

;===============
;===============
help_key:
  pusha
  mov	esi,help_table
  call	message_box
  popa
  ret

 [section .data]
help_table:
  dd	30003730h	;window color
  dd	help_msg
  dd	help_msg_end
  dd	0		;scroll
  db	40		;columns inside box
  db	14		;rows inside box
  db	3		;starting row
  db	3		;starting column
  dd	30003037h	;box outline color

help_msg:
 db 0ah
 db '             [home] - top of file',0ah
 db '             [pgup] - page up',0ah
 db '             [up] - prev link/line ',0ah
 db '               ^',0ah
 db '               |',0ah
 db ' back [esc] <--|--> [enter] select',0ah
 db '     [left]    |    [right]',0ah
 db '               v',0ah
 db '             [down] - next link/line ',0ah
 db '             [space] - next link/line',0ah
 db '             [pgdn] - next page',0ah
 db '              [end] - end of file',0ah
 db 0
help_msg_end:
  [section .text]
;-----------------------------------------------------
; function    : read_file
; description : initializes the buffer
; needs       : [fd]
; returns     : [lines] - next available buffer location
;             ; ebp=next avail buffer loc.  edi=end of allocated memory
; destroys    : -
;-----------------------------------------------------
read_file:    
  mov	ebp,[filebuffer]		;next read location
  mov	edi,[filebuffer_end]	;end of allocated memory
file_read_loop:
  mov	ebx,[fd]		;get file handle
  mov	ecx,ebp			;get buffer
  mov	edx,edi			;compute
  sub	edx,ebp			;  buffer size
  call	file_read		;returns read count in eax or error code
  or	eax,eax			;done?
  jz	file_read_done		;jmp if done
  add	ebp,eax			;advance read location
;allocate another 8096 bytes
  mov	eax,45			;brk memory allocation
  add	edi,fbuf_size		;new buf end if success
  mov	ebx,edi			;get current end
  int	80h
  jmp	short file_read_loop

file_read_done:
  cmp	byte [ebp-1],0ah
  je	frd_exit
  mov	byte [ebp],0ah		;force 0ah at end of file
  inc	ebp
frd_exit:
  mov	[ptr_to_line_ptrs],ebp
  ret  
;-----------------------------------------------------
; function    : init_lines
; description : initializes lines ptr list
; input       : - [ptr_to_line_ptrs]=ebp  edi=end of allocated memory
; returns     : -
; destroys    : -
;-----------------------------------------------------
init_lines:
  xor	eax,eax
  mov	[link_list_ptr],eax
  mov	[link_text_ptr],eax
  mov	[last_line#],eax
  mov	esi,[filebuffer]		;character pointer
  mov	edx,esi				;start of current line
  mov	ecx,ebp				;end of file data
il_loop1:
  mov	eax,ebp				;get current line stuff
  add	eax,400
  cmp	eax,edi				;enough memory allocated
  jb	il_loop2			;jmp if enough memory
;allocate more memory
  add	edi,fbuf_size			;new buf end if success
  mov	ebx,edi
  mov	eax,45
  int	80h				;allocate memory
;esi=text processing ptr  edi=end of memory  ecx=end of file data ebp=stuff ptr
il_loop2:
  cmp	esi,ecx				;check if done
  jae	il_donej			;jmp if more data in buffer
  lodsb
  cmp	al,0ah				;end of line
  jne	il_filter
;end of line found
add_line_ptr:
  mov	[ebp],edx			;stuff line ptr
  add	ebp,4				;advance ebp
  mov	edx,esi				;set new line start
  inc	dword [last_line#]		;update line count
;check if next line is link table
  cmp	byte [esi],'<'
  jne	il_loop1			;jmp if not link table
  push	esi
il_look:
  cmp	esi,ecx
  jae	il_done1
  lodsb
  cmp	al,0ah
  je	not_links
  cmp	al,'>'
  jne	il_look
  lodsb
  cmp	al,'='
  jne	il_look		;jmp if not link list entry
  pop	esi
  jmp	il_link
not_links:
  pop	esi
  jmp	il_loop1
il_done1:
  pop	esi
il_donej:
  jmp	il_done
il_filter:
  cmp	al,09
  je	il_loop2			;jmp = allow tabs
  cmp	al,20h
  jb	bad_char			;zap all 0-19h char codes
  cmp	al,7fh
  jb	il_loop2			;jmp if 20-7e char codes

bad_char:
  mov	byte [esi-1],'.'
  jmp	short il_loop2
;now process link table
il_link:
  xor	eax,eax
  mov	[ebp],eax			;terminate ptr list
  add	ebp,4				;move to start of link list
  mov	[link_list_ptr],ebp
  mov	[link_text_ptr],esi
il_loop3:
  mov	eax,ebp				;get current line stuff
  add	eax,400
  cmp	eax,edi				;enough memory allocated
  jb	il_loop4			;jmp if enough memory
;allocate more memory
  add	edi,fbuf_size			;new buf end if success
  mov	ebx,edi
  mov	eax,45
  int	80h				;allocate memory
;esi=text processing ptr  edi=end of memory  ecx=end of file data ebp=stuff ptr
il_loop4:
  cmp	esi,ecx				;check if done
  jae	il_done				;jmp if more data in buffer
  lodsb
  cmp	al,0ah				;end of line
  jne	il_loop4
;end of line found
  mov	[ebp],edx			;stuff line ptr
  add	ebp,4				;advance ebp
  mov	edx,esi				;set new line start
;check if next line is link table
  cmp	byte [esi],'<'
  je	il_loop3			;jmp if more link table

il_done:
  xor	eax,eax
  mov	[ebp],eax			;put zero at end of pointers
;  add	ebp,4
;  mov	[history_ptr],ebp
;  mov	[memory_end],ecx
  ret
;-----------------------------------------------------
; function    : write_lines
; description : writes a max. of NumLines to STDOUT
; needs       : - ptr_to_line_ptrs,page_top_line#,last_line#
; returns     : -
; destroys    : -
;-----------------------------------------------------
write_lines:    
  mov	eax,[screen_color]
  call	crt_clear
  mov	ebx,colors
  mov	ch,1			;starting row
  mov	cl,1			;starting col
  mov	dl,[crt_columns]	;number of cols
  mov	dh,[crt_rows]	;number of rows
  mov	ebp,[page_top_line#]	;line ptr index
  shl	ebp,2
  add	ebp,[ptr_to_line_ptrs]  
  mov	edi,[scroll_right]	;adjustment to ptrs
  call	crt_win_from_ptrs
  cmp	byte [match_found_flag],0
  je	wl_exit
;highlight match on top line
  mov	eax,[selector_color]
  call	crt_set_color	
  mov	esi,[page_top_line#]	;line ptr index
  shl	esi,2
  add	esi,[ptr_to_line_ptrs]  
  mov	ebx,colors
  mov	ch,1			;row 1
  mov	cl,1			;col 1
  mov	dl,[crt_columns]	;number of cols (max line length)
  mov	esi,[esi]		;get top line data
  mov	edi,[scroll_right]
  call	crt_line
  mov	byte [match_found_flag],0	;turn off highlight
wl_exit:
  ret
;----------------------------------------------------------
display_status_line:
  mov	ebx,colors
  mov	ch,[crt_rows]	;status line row
  inc	ch
  mov	cl,1			;starting col
  mov	dl,[crt_columns]	;number of cols (max line length)
  mov	esi,status_msg1
  xor	edi,edi			;do not scroll status line
  call	crt_line

  mov	ebx,colors
  mov	ch,[crt_rows]	;status line row
  add	ch,2
  mov	cl,1			;starting col
  mov	dl,[crt_columns]	;number of cols (max line length)
  mov	esi,status_msg2
  xor	edi,edi			;do not scroll status line
  call	crt_line

  mov	[status_color_num],byte 1	;restore color
  mov	al,' '
  mov	edi,status_msg_insert
  mov	ecx,status_msg_insert_end - status_msg_insert
  rep	stosb				;clear status message
  ret

  [section .data]
status_msg1:
  db 1,' ',4,'HELP',1,' ',4,'FIND',1,' '
status_color_num: db 1
status_msg_insert: db '                              '
status_msg_insert_end: db 1,' ',4,'FindAgain',1,' ',4,'QUIT',1,'  ',0
status_msg2:
  db 1,' ',4,' F1 ',1,' ',4,' F2 ',1,' ',4,
string_buf: db  '                              '
string_buf_end:
 db 1,' ',4,'   F3    ',1,' ',4,' F10',1,'  ',0

;----------------------------------------

nl		db	0ah
bell_str	db	7
bell_str_len	equ	$-bell_str

  [section .text]

; write a newline character to display
write_nl:    
  push	byte 01H
  pop	edx			;length of write
  mov	ecx,nl			;character to write
  push	byte 01H		;use STDOUT
  pop	ebx
  push	byte 04H
  pop	eax
  int	byte 080H		;do write
  ret
;-------------------------------------------------------------
; input: [kbuf] = db -1,button,column,row
;        [crt_rows] - start of menu line
;output: eax = process address
;
mouse:
  mov	al,[kbuf+3]	;get click row
  dec	al
  cmp	al,[crt_rows]	;get row
  jb	body_click
;mouse click on menu line
  mov	al,[kbuf+2]	;get click column
  cmp	al,5
  ja	mouse_10	;jmp if not help
  mov	eax,help_key
  jmp	mouse_exit
mouse_10:
  cmp	al,10
  ja	mouse_20
  mov	eax,find
  jmp	mouse_exit
mouse_20:
  cmp	al,52
  ja	mouse_30
  mov	eax,find_again
  jmp	mouse_exit
mouse_30:
  mov	eax,terminate
  jmp	mouse_exit
;lookup click location in text
body_click:
  mov	ecx,[page_top_line#]
  movzx ebx,byte [kbuf+3] ;get click row
  dec	ebx
  add	ecx,ebx		;get click line#
  call	line2adr	;returns esi=start of line ptr
  movzx ebx,byte [kbuf+2] ;get column
  add	esi,ebx		;index into line to click point
;esi now points a char we clicked
mouse_lp1:
  dec	esi
  cmp	byte [esi],0ah
  je	mouse_fail	;jmp if no link found
  cmp	byte [esi],'<'
  jne	mouse_lp1	;loop if not start of link
;we have found first "<"
  inc	esi
  push	esi
  call	search_select_list
  pop	esi
  jnc	mouse_fail	;jmp if not valid link
;we have found link, ebx=ptr to link info
  mov	[selector_ptr],esi
  mov	eax,select_link
  jmp	short mouse_exit
mouse_fail:
  mov	eax,unknown_key
mouse_exit:
  ret

;-------------------------------------------------------------
;input: esi=[selector_ptr]
;output: if carry esi=address, ptr to link "<"
;                 ecx=line#
;                 ebx=ptr to list of ptr entry
;        if no carry, not found
find_prev_link:
  mov	esi,[selector_ptr]
  or	esi,esi
  jz	fpl_fail		;jmp if no links in file
  dec	esi			;move to "<"
  mov	ecx,esi
  sub	ecx,[filebuffer]	;compute bytes infront
  jecxz	fpl_20			;jmp if link at top of file
fpl_lp:
  dec	esi
  mov	al,[esi]		;get data
  cmp	al,'<'
  je	fpl_20
  loop	fpl_lp			;keep looking
  jmp	short fpl_fail		;jmp if no links found
;check if this is valid link
fpl_20:
  push	esi
  inc	esi			;move past "<"
  call	search_select_list
  pop	esi
  jnc	fpl_lp		;jmp if no match
;we have found previous link
  inc	esi		;move past "<"
  call	adr2line
  stc
  jmp	short fpl_exit
fpl_fail:
  clc
fpl_exit:
  ret
;-------------------------------------------------------------
;input: [selector_ptr]
;output: if carry esi = ptr to link "<"
;                 ecx = line#
;                 ebx = ptr table ptr
;        if no carry, not found
find_next_link:
  mov	esi,[selector_ptr]
  or	esi,esi
  jz	fnl_fail
  mov	ecx,[link_text_ptr]
  jecxz	fnl_fail
  sub	ecx,esi			;compute remainng bytes
fnl_lp:
  lodsb
  cmp	al,'<'
  je	fnl_20		;jmp if possible selection
;  cmp	al,0ah
;  jne	fnl_lp		;jmp if not eol
  loop	fnl_lp		;eol found, bump counter
  jmp	short fnl_fail
;check if this is valid section
fnl_20:
  push	esi
  call	search_select_list
  pop	esi
  jnc	fnl_lp		;jmp if no match
  call	adr2line	;set ecx=line# ebx=ptr to line ptrs
  stc
  jmp	short fnl_exit
fnl_fail:
  clc
fnl_exit:
  ret
;-------------------------------------------------------------
;input: page_top_line#
;output: if carry selector_ptr - ptr to "<" of selection
;        if no carry - not found
find_first_link:
  mov	esi,[page_top_line#]
  shl	esi,2
  add	esi,[ptr_to_line_ptrs]
  mov	esi,[esi]	;get ptr to text  
  mov	ecx,[crt_rows]	;max loop count
ffl_lp:
  cmp	esi,[ptr_to_line_ptrs]
  jae	ffl_fail	;jmp if no links found
  lodsb
  cmp	al,'<'
  je	ffl_20		;jmp if possible selection
  cmp	al,0ah
  jne	ffl_lp		;jmp if not eol
  loop	ffl_lp		;eol found, bump counter
  jmp	short ffl_fail
;check if this is valid section
ffl_20:
  push	esi
  call	search_select_list
  pop	esi
  jnc	ffl_lp		;jmp if no match
  mov	[selector_ptr],esi
  stc
  jmp	ffl_exit
ffl_fail:
  clc
ffl_exit:
  ret
;-----------------------------------------------------------
; inputs: esi=ptr to match value, after the "<"
;         preserve ecx
; output: flags set for jc=found
;                       jnc=not found
;         ebx=link info if jc
search_select_list:
  mov	ebx,[link_list_ptr]
  or	ebx,ebx
  jz	ssl_fail
ssl_lp:
  mov	edi,[ebx]	;get ptr to text
  or	edi,edi
  jz	ssl_fail
  inc	edi		;move past "<" at front
  push	esi
ssl_lp1:
  lodsb
  cmp	al,'>'
  jne	ssl_10		;jmp if char doesn't match
  cmp	byte  [edi],'>'
  je	ssl_match
ssl_10:
  cmp	al,[edi]
  jne	ssl_next	;jmp if no match
  inc	edi
  jmp	ssl_lp1
ssl_next:
  add	ebx,4
  pop	esi
  jmp	short ssl_lp
ssl_fail:
  clc
  jmp	short ssl_exit
ssl_match:
  pop	esi
  stc
  mov	ebx,[ebx]	;get ptr to link info
ssl_exit:
  ret
;----------------------------------------------------------

;input: esi = adr somewhere in line
;output: ecx = line#
;        ebx = ptr to correct line ptr in table of line ptrs
adr2line:
  mov	ebx,[ptr_to_line_ptrs]
a2l_lp:
  mov	eax,[ebx]	;get line ptr
  or	eax,eax
  jz	a2l_fnd		;jmp if end of table
  cmp	esi,eax
  jb	a2l_fnd
  add	ebx,4		;move to next ptr
  jmp	short a2l_lp
a2l_fnd:
  sub	ebx,4
  mov	ecx,ebx		;compute
  sub	ecx,[ptr_to_line_ptrs]
  shr	ecx,2		;line# for match
  ret

;-----------------------------------------
win_setup:
  call	read_window_size
  mov	al,[crt_rows]		;number of rows
  mov	[str_row],al		;set row for string input  
  sub	word [crt_rows],2	;reduce row count
  mov	[window_resize_flag],byte 0
  ret
;---------------------------------------
signal_install:
  mov	ebp,signal_table
  call	install_signals
  ret

signal_uninstall:
  xor	eax,eax
  mov	[sig_mod1],eax
;  mov	[sig_mod2],eax
  call	signal_install
  mov	dword [sig_mod1],winch_signal
  ret

winch_signal:
;  call	read_window_size
  mov	byte [window_resize_flag],1
  ret
;
;sighup_signal:
;  ret
;----------
  [section .data]
signal_table:
  db	28
sig_mod1:
  dd	winch_signal
  dd	0
  dd	0
  dd	0

;  db	1		;sighup
;sig_mod2:
;  dd	sighup_signal
;  dd	0
;  dd	0
;  dd	0

  db	0		;end of install table

window_resize_flag	db 0
  [section .text]
  
;----------------------------------------------------------
;input: ecx = line#
;output: ebx = ptr to correct line ptr in table of line ptrs
;        esi = ptr to start of line
line2adr:
  mov	ebx,ecx
  shl	ebx,2
  add	ebx,[ptr_to_line_ptrs]
  mov	esi,[ebx]
  ret
;---------------------------------------------------------
  
;---------------
  [section .data]
;----------------------------------------

;    eax = aaxxffbb aa-attr ff-foreground  bb-background
;    30-blk 31-red 32-grn 33-brn 34-blu 35-purple 36-cyan 37-gry
;    attributes 30-normal 31-bold 34-underscore 37-inverse

colors:
screen_color:		dd 30003734h	;white on blue  1
selector_color:		dd 30003036h	;black on cyan  2
menu_bar_color:		dd 30003634h	;cyan on blue   3
menu_button_color:	dd 30003036h	;black on cyan  4
string_color:		dd 30003731h	;white on red    5

;------------------------------------------------------------

fd			dd 0	
scroll_right		dd 0			;amount to scroll display

filebuffer:		dd 0			;buffer ptr
link_text_ptr		dd 0
filebuffer_end:		dd 0			;end of buffer, not end of data
ptr_to_line_ptrs:	dd 0			;ptr to lines struct,zero terminated
link_list_ptr:		dd 0			; zero terminated list of ptrs
;history_ptr:		dd 0
;memory_end:		dd 0

last_line#		dd 0			;total nr. of lines
page_top_line#		dd 0			; current position

selector_ptr:		dd 0			;points past first "<" of selection

usage_msg:	db 0ah,'usage: asmlinks <filename>',0ah,0
;------------------------------------------------------------------
;-- section ---> .bss   
 [section .bss align=4]	   

history_buf		resb	2000
dword_history_buf	resb	100
path_buf		resb	300
