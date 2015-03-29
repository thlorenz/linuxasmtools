
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
; AsmView - view text file
;
;    usage: asmview file
;           asmview < file
;           cat file | asmview
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
  extern  read_termios_x
  extern  read_winsize_x
  extern  output_termios_x
  extern  key_decode1
  extern  kbuf
  extern  file_read
  extern  crt_set_color
  extern show_box
  extern cursor_hide
  extern cursor_unhide
  extern  blk_find
  extern browse_dir_left
  extern set_memory
  extern dword_to_lpadded_ascii
  extern str_move
  extern crt_rows,crt_columns
  extern env_stack
  extern read_window_size,term_type
  extern stdout_str
  extern read_termios_0,output_termios_0
  extern install_signals
  extern reset_clear_terminal

%include "crt_win_from_ptrs.inc"
%include "crt_line.inc"
%include "key_string.inc"

  [section .text]

fbuf_size  equ	8096 * 100
%include "includes.inc"

 bits 32
 global _start,main

;-------------------------------------------------------------------
begin:    
_start:    
  cld
  call	env_stack
  mov	edx,our_termios
  call	read_termios_0
;setup the display - open /dev/tty
  mov	eax,5			;open /dev/tty
  mov	ebx,tty_path
  xor	ecx,ecx			;read only
  int	80h			;open tty
  jns	got_tty			;jmp if no error
  mov	eax,0
got_tty:
  mov	[tty_fd],eax		;save fd
  call	console_setup
set_stderr:
  mov	ebx,[tty_fd]		;get fd
  mov	edx,oldtermios
  call	read_termios_x
  mov	ebx,[tty_fd]
  mov	edx,newtermios
  call	read_termios_x
  and	dword [newtermios+termios.c_lflag],~(ICANON|ECHO|ISIG)
  mov	ebx,[tty_fd]
  mov	edx,newtermios
  call	output_termios_x
  call	signal_install
; setup memory
  mov	eax,45			;brk function call
  xor	ebx,ebx			;request memory
  int	byte 80h
  mov	[filebuffer],eax	;save memory start
  add	eax,fbuf_size
  mov	ebx,eax
  mov	eax,45			;brk function call
  int	byte 80h		;allocate memory
  mov	[filebuffer_end],eax
;setup input fd - check if piped input
  xor	ebx,ebx			;get fd for stdin
  mov	edx,path_buf		;any buffer works here
  call	read_termios_x		;check for redirection, no termios?
  or	eax,eax
  js	get_input_file		;jmp if piped input
;no pipe, check for parameters
  pop	ebx
  dec	ebx			;dec parameter count
  pop	ebx			;get ptr to executable name
  jz	short do_browse		;jmp if (parameter count =1)
  pop	ebx			;get file name paramater
  mov	esi,ebx
  mov	edi,path_buf
  call	str_move
  call	file_open_rd		;returns eax=fd else error
  mov	[fd],eax
  test	eax,eax
  jns	short get_input_file	;jmp if file opened ok
do_browse:
  mov	ebx,path_buf
  mov	ecx,200			;length of buf
  mov	eax,183			;kernel call, get current dir
  int	80h
;  mov	[_starting_path_ptr],ebx
  mov	esi,[filebuffer]
  call	browse_dir_left
  or	eax,eax
  jnz	err_exit		;jmp if error
;restore memory released by browse
  push	ebx			;save file ptr
  mov	ebx,[filebuffer_end]
  call	set_memory
  pop	ebx			;restore path ptr
  call	file_open_rd		;returns eax=fd else error
  mov	[fd],eax
  test	eax,eax
  jns	short get_input_file	;jmp if file opened ok
err_exit:
;error exit
  mov	ebx,1
  jmp	do_exit2
;read file to memory
get_input_file:    
  call	near read_file		;read file
  call	near init_lines		;initialize lines structure
  call	crt_clear
display_page:    
  call	near write_lines	;display lines
;add status line to end of display
  call	display_status_line

  mov	ebp,string_table
  call	key_string1
  mov	[str_adj],ah		;save cursor col
  cmp	[window_resize_flag],byte 0
  je	process_key
  mov	[window_resize_flag],byte 0
  call	console_setup
  jmp	short display_page

process_key:
  mov	esi,key_decode_table
  call	key_decode1		;returns process to call in eax

;call key processng function

call_key_process:    
  mov	ecx,dword [page_top_line#]
  mov	edx,dword [last_line#]
  movzx	ebp,word [window]	;get total rows in window
  call	eax
  mov	dword [page_top_line#],ecx
  mov	dword [last_line#],edx
  jmp	near display_page

key_decode_table:
  dd	terminate		;assume q (alpha key)

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
  dd event_key_right

  db 1bh,4fh,43h,0		;18 pad_right
  dd event_key_right

  db 1bh,4fh,76h,0		;18 pad_right
  dd event_key_right

  db 1bh,5bh,44h,0		;17 pad_left
  dd event_key_left

  db 1bh,4fh,44h,0		;17 pad_left
  dd event_key_left

  db 1bh,4fh,74h,0		;17 pad_left
  dd event_key_left

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

  db 1bh,5bh,31h,33h,7eh,0	;4 f3
  dd terminate

  db 1bh,4fh,52h,0		;123 F3
  dd terminate

  db 1bh,5bh,5bh,43h,0		;129 f3
  dd terminate

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
  dd find_again

  db 0ah,0			;enter key
  dd find_again

  db 0		;enc of table
  dd unknown_key ;unknown key trap

unknown_key:	ret
;=====================================================
;                  begin key events
;=====================================================
; ecx = page_top_line#
; edx = last_line#
; ebp = total rows in window

event_key_up:    
  test	ecx,ecx
  je	short bell
  cmp	edx,ebp
  jl	short bell
  dec	ecx
  ret
;=============
; ecx = page_top_line#
; edx = last_line#
; ebp = total rows in window
event_key_down:    
  cmp	edx,ebp
  jl	short bell
  mov	eax,edx
  sub	eax,ebp
  cmp	ecx,eax
  je	short bell
  inc	ecx
  ret
;=============
; ecx = page_top_line#
; edx = last_line#
; ebp = total rows in window
event_key_pgdown:    
  cmp	edx,ebp			;are we at last page
  jl	short bell
  mov	eax,edx			;edx = last line#
  sub	eax,ebp
  mov	ebx,ecx
  add	ebx,ebp
  cmp	eax,ebx
  jg	short bell.lbl1
  mov	ecx,eax
bell:    
;  pusha
;  push	byte 01H
;  pop	edx
;  mov	ecx,bell_str
;  push	byte 01H
;  pop	ebx
;  push	byte 04H
;  pop	eax
;  int	byte 080H
;  popa
  ret
bell.lbl1:    
  mov	ecx,ebx
  ret
;===============
; ecx = page_top_line#
; edx = last_line#
; ebp = total rows in window
event_key_pgup:    
  cmp	edx,ebp			;edx=last_line# , ebp=rows in window
  jl	bell
  mov	eax,ecx				;page top line# POS
  sub	eax,ebp				;ebp=rows in window
  jns	.lbl1
  xor	ecx,ecx				;page top line#
  jmp	short bell
.lbl1:
  mov	ecx,eax				;set page to line#
  ret
;===============
; ecx = page_top_line#
; edx = last_line#
; ebp = total rows in window
event_key_end:    
  mov	eax,edx
  cmp	eax,ebp
  jl	short bell
  sub	eax,ebp
  mov	ecx,eax
;  mov	edx,eax
  jmp	short bell
;===============
; ecx = page_top_line#
; edx = last_line#
; ebp = total rows in window
event_key_home:    
  xor	ecx,ecx
;  xor	edx,edx
  jmp	short bell
;===============
event_key_right:
  inc	dword [scroll_right]
  ret
;===============
event_key_left:
  cmp	dword [scroll_right],0
  je	ekl_exit
  dec	dword [scroll_right]
ekl_exit:
  ret
;===============
find_again:
  push	ecx
  push	edx
  push	ebp
  mov	ebp,[filebuffer_end]
  mov	esi,string_buf

  xor	eax,eax			;adjust if on match=0
  mov	edi,[page_top_line#]	;line ptr index
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
;scan back to line start
fa_20:
  cmp	ebx,[filebuffer]	;at start of file?
  je	fa_30			;jmp if at start of file
  cmp	[ebx-1],byte 0ah	;at start of line?
  je	fa_30			;jmp if at start of line
  dec	ebx
  jmp	short fa_20
fa_30:
;find line number for this match ebx=match point
  mov	esi,[ptr_to_line_ptrs]
  mov	ecx,[last_line#]	;line number counter
line_search_loop:
  lodsd
  or	eax,eax
  jz	found_line
  cmp	eax,ebx
  jae	found_line
  loop	line_search_loop
found_line:
  mov	eax,[last_line#]
  sub	eax,ecx			;compute current line#
;  dec	eax
  mov	[page_top_line#],eax
  mov	[last_match_line#],eax
  mov	ecx,eax			;return ecx to caller    
  pop	ebp
  pop	edx
  pop	eax			;get origonal top_line
  mov	byte [match_found_flag],1
  jmp	short find_exit2
not_found:
  mov	eax,[color_table+8]
  mov	bl,1		;column for msg
  mov	bh,[window+winsize.ws_row]	;row for msg
  mov	ecx,not_fnd_msg
  call	crt_color_at
  call	read_stderr
find_exit:
  pop	ebp
  pop	edx
  pop	ecx
find_exit2:
  ret
;----------------------
  [section .data]
not_fnd_msg:
  db ' ** not found **  press any key to continue                      ',0
match_found_flag	db	0
last_match_line#	dd	-1
  [section .text]

;===============
;===============
help_key:
  pusha
;find end of path
  mov	esi,path_buf
path_end_lp:
  lodsb
  or	al,al
  jnz	path_end_lp
;get 40 characters from end of path
  mov	ecx,40
path_extract:
  dec   esi
  cmp	esi,path_buf
  je	help_10		;jmp if start of path set
  loop	path_extract
;move path data to message
help_10:
  mov	edi,stuff_path
  call	str_move
;get total lines in file
  mov	eax,[last_line#]
  mov	edi,total_stuff
  mov   cl,4             ;number of bytes
  mov   ch,'0'           ;pad char
  call	dword_to_lpadded_ascii
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
  db	10		;rows inside box
  db	3		;starting row
  db	3		;starting column
  dd	30003037h	;box outline color

help_msg:
 db ' scrolling - up,down,right,left',0ah
 db ' paging    - pgup,pgdn',0ah
 db ' top/bottom- home,end',0ah
 db ' exit      - ESC,F3,F10',0ah
 db ' help      - F1',0ah
 db ' search    - <string> Enter ',0ah
 db 0ah
 db 'current file:',0ah
stuff_path:
 times 40 db ' '
 db 0ah
 db 'total lines in file: '
total_stuff: db "xxxx"
 db 0ah
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
  mov	[filebuffer_end],ebp
  ret  
;-----------------------------------------------------
; function    : init_lines
; description : initializes lines structure
; input       : - [ptr_to_line_ptrs]=ebp  edi=end of allocated memory
; returns     : -
; destroys    : -
;-----------------------------------------------------
init_lines:    
  mov	esi,[filebuffer]			;character pointer
  mov	edx,esi				;start of current line
  mov	ecx,ebp				;end of file data
il_loop1:
  mov	eax,ebp				;get current line stuff
  add	eax,4
  cmp	eax,edi				;enough memory allocated
  jb	il_loop2			;jmp if enough memory
;allocate more memory
  add	edi,fbuf_size			;new buf end if success
  mov	ebx,edi
  mov	eax,45
  int	80h				;allocate memory

il_loop2:
  cmp	esi,ecx				;check if done
  je	il_done				;jmp if more data in buffer
  lodsb
  cmp	al,0ah				;end of line
  jne	il_filter
;end of line found
add_line_ptr:
  mov	[ebp],edx			;stuff line ptr
  add	ebp,4				;advance ebp
  mov	edx,esi				;set new line start
  inc	dword [last_line#]
  jmp	il_loop1

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
il_done:
  xor	eax,eax
  mov	[ebp],eax			;put zero at end of pointers
  ret
;-----------------------------------------------------
; function    : write_lines
; description : writes a max. of NumLines to STDOUT
; needs       : - ptr_to_line_ptrs,page_top_line#,last_line#
; returns     : -
; destroys    : -
;-----------------------------------------------------
write_lines:    
  mov	eax,[color_table]	;get normal window color
  call	crt_set_color
  mov	ebx,color_table
  mov	ch,1			;starting row
  mov	cl,1			;starting col
  mov	dl,[window+winsize.ws_col]	;number of cols
  mov	dh,[window+winsize.ws_row]	;number of rows
  mov	ebp,[page_top_line#]	;line ptr index
  shl	ebp,2
  add	ebp,[ptr_to_line_ptrs]  
  mov	edi,[scroll_right]	;adjustment to ptrs
  call	crt_win_from_ptrs
  cmp	byte [match_found_flag],0
  je	wl_exit
;highlight match on top line
  mov	eax,[color_table+8]
  call	crt_set_color	
  mov	esi,[page_top_line#]	;line ptr index
  shl	esi,2
  add	esi,[ptr_to_line_ptrs]  
  mov	ebx,color_table
  mov	ch,1			;row 1
  mov	cl,1			;col 1
  mov	dl,[window+winsize.ws_col]	;number of cols (max line length)
  mov	esi,[esi]		;get top line data
  mov	edi,[scroll_right]
  call	crt_line
  mov	byte [match_found_flag],0	;turn off highlight
wl_exit:
  ret
;----------------------------------------------------------
display_status_line:
  mov	ebx,color_table
  mov	ch,[window+winsize.ws_row]	;status line row
  inc	ch
  mov	cl,1			;starting col
  mov	dl,[window+winsize.ws_col]	;number of cols (max line length)
  mov	esi,status_msg
  xor	edi,edi			;do not scroll status line
  call	crt_line
  ret

status_msg:
  db 4,'F1',2,'=help ',4,'HOME',2,'=top ',4,'END',2,'=bottom ',4,'ESC',2,'=exit ',' search ->',3,'  ',0

;----------------------------------------
crt_clear:
  mov eax, 0x4			; system call 0x4 (write)
  mov ebx,2			;stderr
  mov ecx,clear_msg		; message
  mov edx,clear_msg_len		; length
  int byte 0x80			; write function
  ret
clear_msg: db 1bh,'[2J',0
clear_msg_len equ $ - clear_msg
;----------------------------------------

nl		db	0ah
bell_str	db	7
bell_str_len	equ	$-bell_str

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
terminate:    
  mov	edx,oldtermios
  mov	ecx,005402H
  push	byte 02H
  pop	ebx
  push	byte 036H
  pop	eax
  int	byte 080H		;restore origional termios
  call	near write_nl
do_exit:    
  xor	ebx,ebx
do_exit2:
  push	ebx
;  mov	eax,[color_table]
;  call	crt_clear
  mov	edx,our_termios
  call	output_termios_0
;  mov	ax,0101h
;  call	move_cursor
  call	reset_clear_terminal
  pop	ebx			;restore exit code
  push	byte 01H
  pop	eax
  int	byte 080H
;--------
  [section .data]
our_termios times 43 db 0
  [section .text]
;------------------------------------------------------
console_setup:
  call	read_window_size	;get term type
; changed 9-2008, using "xor ebx,ebx failed when
; using "viewer" to look at man page of form file.1.gz
; We need to use tty_fd, not zero
  mov	ebx,[tty_fd]		;tty fd
;  xor	ebx,ebx			;get stdout size
  mov	edx,window
  call	read_winsize_x
  or	eax,eax
  jz	short set_status_row    ;jmp if size found
  mov	[edx],dword 0500018h	;force std win size
set_status_row:
  mov	al,[edx]		;number of rows
  mov	[str_row],al		;set row for string input
  mov	[crt_rows],al
  mov	ax,[edx+2]
  mov	[crt_columns],ax  
  dec	word [edx]		;reduce row count

  cmp	[term_type],byte 2	;console?
  jne	cc_exit			;exit if not console
  mov	ecx,clr_str
  call	stdout_str
cc_exit:
  ret
;----
  [section .data]
clr_str: db 1bh,'c',0
  [section .text]
;---------------------------------------
signal_install:
  mov	ebp,signal_table
  call	install_signals
  ret

signal_uninstall:
  xor	eax,eax
  mov	[sig_mod1],eax
;  mov	[sig_mod2],eax
  call	install_signals               
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

;---------------------------------------------------------
message_box:
  call	show_box
  call	cursor_hide
  call	read_stderr
  call	cursor_unhide
  ret



  [section .data]
;----------------------------------------
key_table:    
  dd	KEY_q,		terminate
  dd	KEY_Q,		terminate
  dd	KEY_UP,		event_key_up
  dd	KEY_DOWN,	event_key_down
  dd	KEY_ENTER,	event_key_down
  dd	KEY_SPACE,	event_key_pgdown
  dd	KEY_PGDOWN,	event_key_pgdown
  dd	KEY_PGUP,	event_key_pgup
  dd	KEY_b,		event_key_pgup
  dd	KEY_END,	event_key_end
  dd	KEY_HOME,	event_key_home
key_table_end:    

;    eax = aaxxffbb aa-attr ff-foreground  bb-background
;    30-blk 31-red 32-grn 33-brn 34-blu 35-purple 36-cyan 37-gry
;    attributes 30-normal 31-bold 34-underscore 37-inverse

color_table:
  dd 31003334h		;normal color		;color 1  yellow on blue
  dd 30003730h		;status line color	;color 2
  dd 31003130h		;search entry/highlight ;color 3
  dd 31003130h		;menu key hightlight color

;------------------------------------------------------------

string_table:
  dd	string_buf	;ptr to string buffer
max_string_len:
  dd	30		;max string len
  dd	color_table + 8
str_row:
  db	0		;row
  db	48		;column
  db	0		;flag 1=allow 0a in string
str_adj:
  db	48		;initial cursor column

string_buf:  times 32 db 0

;-----------------------------

tty_path: db '/dev/tty',0
tty_fd    dd 0


;------------------------------------------------------------------
;-- section ---> .bss   
 [section .bss align=4]	   


fd			resd	1
msg			resb	80			;LineWidth
scroll_right		resd	1			;amount to scroll display

window		resw 4	;B_STRUC winsize, .ws_row, .ws_col
oldtermios	resb 36 ;B_STRUC termios,.c_iflag,.c_oflag
newtermios	resb 36 ;B_STRUC termios,.c_iflag,.c_oflag

ptr_to_line_ptrs:		resd	1			; pnt to lines struct
last_line#			resd	1			; nr. of lines
page_top_line#			resd	1			; current position

path_buf		resb	200
filebuffer:		resd	1		;buffer ptr
filebuffer_end:		resd	1
