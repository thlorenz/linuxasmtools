
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
  extern dir_close
  extern dir_open

  extern read_stdin,kbuf
  extern move_cursor
  extern crt_color_at
  extern crt_char_at
  extern stdout_str
  extern mouse_enable
  extern lib_buf
  extern cursor_hide
  extern cursor_unhide
  extern draw_box
  extern str_move
  extern dir_status
  extern dir_index
  extern sort_merge
  extern term_type
  
; extern dir_sort_by_type
%include "dir_sort_by_type.inc"

  extern str_move

  [section .text]  

 [section .text]

%ifndef DEBUG
; structure describing a directory entry
struc dtype
.d_size	resd 1	;byte size for fstat .st_size
.d_mode	resw 1	;type information from fstat .st_mode 
.d_uid  resw 1  ;owner code
.d_len   resb 1  ;length byte from dent structure
.d_type  resb 1  ;type code 1=dir 2=symlink 3=file
.d_nam resb 1	;directory name (variable length)
endstruc
%endif

;*********************************************************************

;-----------------------------------------------------------------
  [section .text]
;
; NAME
;>1 widget
;  browse_dir - display and traverse directories
;
;  The functions browse_dir_right and browse_dir_left call
;  this function and provided a simplier calling sequence.
;
; INPUTS
;    esi = pointer to the following structure
;
;     struc  input
;     .work_buf_ptr:       resd 1 ;memory allocation area, provided by
;                                 brk kernel call
;     .dircolor            resd 1 ;color of directories in list
;     .linkcolor           resd 1 ;color of symlinks in list
;     .selectcolor         resd 1 ;color of select bar
;     .filecolor           resd 1 ;normal window color, and list color
;     .win_location_row    resb 1 ;top row number for window
;     .win_location_column resb 1 ;top left column number
;     .win_rows:           resb 1 ;rows in window, includes outline if enabled
;     .win_columns:        resb 1 ;number of columns, includes outline if enabled
;     .box_flag            resb 1 ;0=no box 1=box
;     .starting_path_ptr   resd 1 ;path to start browsing
;      execolor            resd 1
;      devcolor            resd 1
;      misccolor           resd 1
;     endstruc
;
;     the following keys are recognized:
;      right arrow - move into directory
;      left arrow  - go back one directory
;      up arrow    - move file select bar up
;      down arrow  - move file select bar down
;      pgup/pgdn   - move page up or down
;      ESC         - exit without selecting
;      enter       - exit and select file
;
;    mouse clicks also select files
;    colors = aaxxffbb  (aa-attribute ff-foreground  bb-background)
;     30-black 31-red 32-green 33-brown 34-blue 35-purple 36-cyan 37-grey
;    attributes 30-normal 31-bold 34-underscore 37-inverse
;
; OUTPUT
;    eax = negative if error.  -1=escape typed.
;          zero indicates success.
;    ebx = ptr to full path if eax=0
;
; NOTES
;   source file: browse_dir.asm
;
;<
; * ----------------------------------------------

;------------
; colors = aaxxffbb  (aa-attribute ff-foreground  bb-background)
;   30-black 31-red 32-green 33-brown 34-blue 35-purple 36-cyan 37-grey
;   attributes 30-normal 31-bold 34-underscore 37-inverse

max equ 54000			;size of dbuf

%ifndef DEBUG
  struc	stat_struc
.st_dev: resd 1
.st_ino: resd 1
.st_mode: resw 1
.st_nlink: resw 1
.st_uid: resw 1
.st_gid: resw 1
.st_rdev: resd 1
.st_size: resd 1
.st_blksize: resd 1
.st_blocks: resd 1
.st_atime: resd 1
.__unused1: resd 1
.st_mtime: resd 1
.__unused2: resd 1
.st_ctime: resd 1
.__unused3: resd 1
.__unused4: resd 1
.__unused5: resd 1
;  ---  stat_struc_size
  endstruc
%endif

;----------------------------------------------------------------
;----------------------------------------------------------------
  global browse_dir
browse_dir:
  mov	edi,work_buf_ptr
  mov	ecx,block_size
  rep	movsb			;save copy of inputs
; setup to read keyboard and mouse
  call	mouse_enable
; check if box needed
  cmp	byte [box_flag],0
  je	db_10			;jmp if no box needed
  call	console_setup		;reset console if necessary
  mov	esi,filecolor
  call	draw_box
  sub	byte [win_rows],2
  sub	byte [win_columns],2
  inc	byte [win_location_column]
  inc	byte [win_location_row]
db_10:
  call	cursor_hide
; extract starting path & copy to default path
  mov	esi,[starting_path_ptr]
  mov	edi,default_path
  call	str_move
  cmp	byte [edi-1],'/'
  je	blp1			;jmp if path ends with '/'
  mov	al,'/'
  stosb
  mov	al,0
  stosb

blp1:
  mov	eax,[dir_block_pointer]
  or	eax,eax
  jz	open_it
  call	dir_close		;close previous directory and release memory
open_it:
  mov	eax,[work_buf_ptr]	;bss_start
  mov	ebx,default_path
  call	dir_open
  mov	[dir_block_pointer],eax
  call	dir_index
;get pointers from dir_block
  mov	ebp,[dir_block_pointer]
  mov	eax,[ebp + dir_block.record_count]
  mov	[sort_ptr_count],eax
  mov	eax,[ebp + dir_block.index_ptr]
  mov	[sort_ptrs_ptr],eax

  mov	al,[win_location_row]
  mov	[select_ptr_row],al
  call	sort_files
  mov	ebp,[dir_block_pointer]
  sub	[ebp+dir_block.record_count],dword 2
  
  mov	eax,[ebp+dir_block.index_ptr]
  add	eax,8		;remove '.' and '..' at top of dir
  mov	[sort_ptrs_ptr],eax
  mov	[page_top_ptr],eax	;setup top of page for display
  mov	[select_ptr],eax	;initialize selection pointer
blp2:
  call	find_highlighted_entry
  call	display_dir
  call	highlight_selector

  call	read_stdin

  cmp	byte [kbuf],-1
  jne	key_event			;jmp if key pressed
  jmp	mouse_event
key_event:
  cmp	byte [kbuf+1],0
  jne	arrow_check
  jmp	single_key
;
; check for arrow keys
;
arrow_check:
  mov	al,[kbuf+2]
  cmp	al,41h
  je	up_key
  cmp	al,78h
  je	up_key
  cmp	al,42h
  je	down_key
  cmp	al,72h
  je	down_key
  cmp	al,43h
  je	right_key
  cmp	al,76h
  je	right_key
  cmp	al,44h
  je	left_key
  cmp	al,74h
  je	left_key
  cmp	al,36h
  je	pgdn
  cmp	al,73h
  je	pgdn
  cmp	al,35h
  je	pgup
  cmp	al,79h
  je	pgup  
  jmp	blp2				;ignore all others
up_key:
  call	up
  jmp	blp2
down_key:
  call	down
  jmp	blp2
;
; right arrow pressed
;
right_key:
  mov	edi,[select_ptr]	;get pointer to array of pointers
  mov	edi,[edi]		;get current pointer
  or	edi,edi			;check if inside empty dir
  jz	blp2			;ignore right key if in empty dir
  cmp	byte [edi + 9],'/'
  jne	blp2      		;exit if not directory
  add	edi,10			;move past code
  mov	esi,default_path
  call	build_path
  mov	byte [edi-1],'/'	;append "/" to end of filepath
  mov	byte [edi],0  
  jmp	blp1  
left_key:
  call	left
  jmp	blp1
single_key:
  mov	al,[kbuf]			;get keypress
  cmp	al,1bh
  je	escape_pressed
  cmp	al,0dh
  je	return_pressed
  cmp	al,0ah
  je	return_pressed
blp2j:
  jmp	blp2				;ignore other keys

pgdn:
  call	page_down
  jmp	blp2
pgup:
  call	page_up
  jmp	blp2

;
; return null filename, (buffer read)
;
escape_pressed:
  mov	eax,-1
  jmp	browser_exit

;
; return selected file, highlighted file or mouse click
;
return_pressed:
  mov	edi,[select_ptr]
  mov	edi,[edi]
;  cmp	byte [edi],1		;is this a directory?
;  jne	blp2			;right_key		;jmp if directory
;  inc	edi
  add	edi,10			;move to file name
  mov	esi,default_path
  call	build_path
  mov	edi,default_path
  xor	eax,eax
browser_exit:
  pusha
  call	cursor_unhide
  popa
  mov	ebx,default_path
  ret
;------------------------------------------------------------------
; up key pressed
;
up:
  mov	eax,[select_ptr]
  cmp	eax,[sort_ptrs_ptr]	;sort_pointers
  je	up_exit			;jmp if at top
  mov	bl,[select_ptr_row]
  cmp	bl,[win_location_row]	;cursor at top
  je	scroll_up
;
; cursor inside window, and select_ptr not at top of list
;
  dec	bl
  mov	[select_ptr_row],bl
  sub	eax,4
  mov	[select_ptr],eax
  jmp	up_exit
;
; cursor at top of screen and select_ptr not at top of list
;
scroll_up:
  sub	eax,4			;move cursor up 1
  mov	[select_ptr],eax
  mov	[page_top_ptr],eax	;move widow up 1
up_exit:
  ret

;------------------------------------------------------------------
; down key pressed
;
down:
  mov	eax,[select_ptr]
  cmp	dword [eax+4],0		;check if at end of ptr list
  je	down_exit		;exit if at end of list
  mov	bl,[select_ptr_row]
  mov	bh,[win_rows]
;  sub	bh,3			;compute last display line
  cmp	bl,bh			;is cursor on last line
  je	down_10			;jmp if cursor on last line
;
; we are not at end of pointers and not on last line
;
  inc	bl			;move cursor down
  mov	[select_ptr_row],bl
  add	eax,4
  mov	[select_ptr],eax
  jmp	down_exit
;
; cursor on last line, and more pointers are available
;
down_10:
  add	eax,4
  mov	[select_ptr],eax
  mov	eax,[page_top_ptr]
  add	eax,4
  mov	[page_top_ptr],eax
down_exit:
  ret
;------------------------------------------------------------------
; left arrow key pressed, truncate the  end of default_path
;  path is of form: (xxx/yyyy/zzz)
left:
  mov	esi,default_path
left_10:
  lodsb
  or	al,al
  jnz	left_10			;scan to end of path
left_12:
  dec	esi			;move back to zero
  cmp	byte [esi],"/"
  jne	left_12			;find ending '/'
  dec	esi			;move back to '/'
left_20:
  cmp	esi,default_path
  je	left_40			;jmp if at beginning of path
  ja	left_30			;jmp if not at beginning of path
  inc	esi			;move to start of default_path
  jmp	left_40			;go create "/",0
left_30:
  dec	esi
  cmp	byte [esi],'/'
  jne	left_20			;scan back one entry
  call	save_old_path
left_40:
  mov	byte [esi+1],0		;truncate path
  ret
;----------------------------------------
;
find_highlighted_entry:
  cmp	byte [old_path],0	;check if old path needs highlighting
  je	highlight_selected	;jmp if no old_path to highlight
;
; search for old path and set as "selected"
;
  mov	ebp,[sort_ptrs_ptr]	;sort_pointers
;  mov	[page_top_ptr],ebp
  xor	ecx,ecx			;row counter
try_again:
  mov	esi,[ebp]		;get next pointer
  add	esi,10			;move to filename
  mov	edi,old_path
cmp_loop:
  mov	al,[esi]
  or	al,[edi]
  jz	ds_match		;jmp if match found
  cmpsb
  jne	ds_next			;jmp if this entry does not match
  jmp	cmp_loop
ds_next:
  add	ebp,4
  inc	ecx
  cmp	dword [ebp],0
  jne	try_again
  jmp	no_match
;match found, ecx=count from top of dir, set select_ptr
; select_ptr_row, page_top_ptr
ds_match:
  xor	ebx,ebx
  mov	bl,[win_rows]
  mov	edx,ebx
  shl	edx,2			;dword page adjust for ptr
  mov	eax,[sort_ptrs_ptr]
;remove pages from ecx, until we are in our page
page_lp:
  sub	ecx,ebx
  js	paging_done
  add	eax,edx			;page ptr down
  jmp	short page_lp
paging_done:
  add	ecx,ebx			;restore ecx for our page
  add	cl,[win_location_row]
;  inc	ecx
  mov	[select_ptr],ebp
  mov	[select_ptr_row],cl
  mov	[page_top_ptr],eax
no_match:
  mov	byte [old_path],0	;disable old path till next left arrow
highlight_selected:
  ret
;----------------------------
save_old_path:
  push	esi
  mov	edi,old_path
  inc	esi		;move past '/'
sop_10:
  lodsb
  stosb
  cmp	al,'/'
  je	sop_20		;jmp if end of name
  or	al,al
  jnz	sop_10
sop_20:
  mov	byte [edi-1],0	;force zero at end
  pop	esi
  ret
;----------------------------
page_up:
  xor	ecx,ecx
  mov	cl,[win_rows]
;  dec	cl
;  sub	cl,3
  mov	esi,[page_top_ptr]
pu_loop:
  cmp	esi,[sort_ptrs_ptr]	;sort_pointers
  je	pu_set			;jmp if at top
  sub	esi,4			;move up
  dec	cl
  jnz	pu_loop			;loop if page incomplete
pu_set:
  mov	[page_top_ptr],esi
  mov	[select_ptr],esi
  mov	al,[win_location_row]
  mov	[select_ptr_row],al
;  mov	byte [select_ptr_row],1
  ret
  
;----------------------------
page_down:
  mov	cl,[win_rows]
;  dec	cl
;  sub	cl,3
  mov	esi,[page_top_ptr]
pd_loop:
  cmp	dword [esi+4],0
  je	pd_set			;jmp if end of data found
  add	esi,4
  dec	cl
  jnz	pd_loop			;loop till end of page found
pd_set:
  mov	[page_top_ptr],esi
  mov	[select_ptr],esi
  mov	al,[win_location_row]
  mov	[select_ptr_row],al
;  mov	byte [select_ptr_row],1
  ret

;
;--------------------------------------------------------------
; process mouse click
; if good click goto return_pressed, else goto blp2
;
mouse_event:
  mov	cl,[kbuf + 2]		;get cursor column
  mov	ch,[kbuf + 3]		;get cursor row
;
  mov	al,[win_location_row]	;get top of widow
  mov	ah,[win_rows]
  cmp	ch,al
  jb	me_ignore		;jmp if illegal mouse click
  add	al,ah			;compute end of window row
  cmp	ch,al			;are we beyond the window?
  jb	me_ok
me_ignore:
  jmp	blp1			;ignore this click

me_ok:
  mov	al,[win_location_column]
  mov	ah,[win_columns]
  cmp	cl,al
  jb	me_ignore		;jmp if click infront of window
  add	al,ah
  cmp	cl,al
  ja	me_ignore		;jmp if beyond right edge of window
;
  xor	eax,eax
  mov	al,ch			;get row
  sub	al,[win_location_row]	;compute index
  shl	eax,2
  add	eax,[page_top_ptr]	;index into sort pointers
  mov	[select_ptr],eax
  jmp	return_pressed	

;--------------------------------------------------------------
;
sort_files:
  mov	esi,default_path
  mov	eax,[dir_block_pointer]
  call	dir_sort_by_type	;;
  ret

;--------------------------------------------------------------
; display directory
;   inputs:  [win_rows] [win_columns]
;            sort_pointers
;
display_dir:
  xor	ecx,ecx
  mov	cl,[win_rows]	;get lines to display

  mov	ebp,[page_top_ptr]	;get pointer to first line
;
; move line to lib_buf
;
  mov	bh,[win_location_row]	;starting display row
dd_lp:
  mov	ch,[win_columns]
  mov	edi,lib_buf		;get pointer to line build area
  mov	esi,[ebp]		;get pointer to line data
  cmp	esi,0
  jne	dd_10			;jmp if more data
  jmp	dd_50			;jmp if out of data
dd_10:
  add	esi,9			;move to filename
dd_lp2:
  lodsb
  stosb
  cmp	al,0
  je	dd_14			;jmp if end of line found
  dec	ch
  jnz	dd_lp2			;loop till line moved
  jmp	dd_20
dd_14:
  dec	edi				;fill rest of line with blanks
  mov	al,' '
dd_16:
  stosb
  dec	ch
  jnz	dd_16
;
dd_20:
  mov	byte [edi],0		;put zero at end of line
  mov	esi,lib_buf		;move back start of line

  mov	dl,[esi]		;get code
  mov	eax,[execolor]
  cmp	dl,'*'
  je	dd_30
  mov	eax,[dircolor]
  cmp	dl,'/'			;check if 
  je	dd_30			;jmp if dir
  mov	eax,[linkcolor]
  cmp	dl,"@"
  je	dd_30
  cmp	dl,'~'
  je	dd_30			;jmp if link to dir
  cmp	dl,' '
  mov	eax,[filecolor]
  je	dd_30			;jmp if file
  mov	eax,[devcolor]
  cmp	dl,'-'
  je	dd_30
  cmp	dl,'+'
  je	dd_30  
  mov	eax,[misccolor]          
dd_30:
  push	ebx
  push	ecx
  mov	bl,[win_location_column]
  mov	ecx,lib_buf		;get display text
  call	crt_color_at	;display message
  pop	ecx
  pop	ebx

  add	ebp,4
  inc	bh
  dec	cl
  jz	dd_60			;exit if end of window
  jmp	dd_lp
;
; end of data was reached before end of window, fill rest of screen
;
dd_50:
  mov	edi,lib_buf
  mov	al,' '
  mov	ch,[win_columns]
dd_52:
  stosb
  dec	ch
  jnz	dd_52
dd_54:
  mov	eax,[filecolor]
  push	ecx
  push	ebx
  mov	bl,[win_location_column]
  mov	ecx,lib_buf		;get display text
  call	crt_color_at	;display message
  pop	ebx
  pop	ecx
  inc	bh
  dec	cl
  jnz	dd_54			;exit if end of window

dd_60:
  ret

;----------------------------------------------------------------------
;  inputs: select_ptr - pointer to file pointers for current selection
;          select_ptr_row - current row of select ptr
;
highlight_selector:
  mov	esi,[select_ptr]
  mov	esi,[esi]		;point at text line
  or	esi,esi
  jnz	hs_10			;jmp if directory has entries
  mov	esi,empty_msg
  jmp	short hs_11
hs_10:
  add	esi,9			;move to filename data ;;;;
hs_11:
  mov	edi,lib_buf
  call	str_move		;move text to lib_buf
;
; truncate line if outside window
;
  xor	ebx,ebx
  mov	bl,[win_columns]
  add	ebx,lib_buf
  mov	byte [ebx],0		;truncate window
;
  mov	ecx,lib_buf+1
  mov	eax,[selectcolor]
  mov	bh,[select_ptr_row]	;row
  mov	bl,[win_location_column]
  add	bl,1			;column + 1
  call	crt_color_at	;display message/ highlight selection
hs_exit:
  ret
empty_msg: db " - empty dir -",0

;------------------------------------------------------
console_setup:
  call	read_window_size
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

;------------------------------------------------------
; fill lib_buf msg for width of display
;  inputs :esi=msg
;         ; win_columns
;  output: ecx = lib_buf ptr
;
fill_lib_buf:
  mov	edi,lib_buf
  mov	cl,0
fs_10:
 lodsb
  stosb				;move message to lib_buf
  or	al,al
  jz	fs_15			;jmp if end of msg found
  inc	cl
  cmp	cl,[win_columns]
  jne	fs_10			;loop if not at window edge
fs_15:
  dec	edi
  mov	al,' '
fs_20:
  cmp	cl,[win_columns]
  je	fs_30			;jmp if line filled
  stosb
  inc	cl
  jmp	fs_20			;fill remainder of line with blanks
fs_30:
  mov	ecx,lib_buf
  ret

;-----------------------------------------------------------------
; build path for execution or open
;  input: edi = filename
;         esi = path base
;
build_path:
  lodsb
  cmp	al,0
  jne	build_path	;loop till end of path
  dec	esi
bp_lp1:
  cmp	byte [esi],'/'
  je	bp_append
  dec	esi
  jmp	short bp_lp1	;scan back till '/' found
bp_append:
  xchg	esi,edi
  inc	edi		;move past '/'
bp_lp2:
  lodsb
  stosb
  cmp	al,0
  jne	bp_lp2		;loop till name appended
  ret
;--------------------------------

  [section .data]
dir_block_pointer:	dd	0	;see structure dir_block
sort_ptrs_ptr		dd	0	;extracted from dir_block
sort_ptr_count		dd	0	;number of records
;
; input data block from caller
;
work_buf_ptr         dd 0
;                               buffer size depends upon size of directories read.
dircolor             dd 0	;color of directories in list
linkcolor            dd 0       ;color of symlinks in list
selectcolor          dd 0       ;color of select bar
filecolor            dd 0	;normal window color, and list color
win_location_row     db 0       ;top row number for window
win_location_column  db 0	;top left column number
win_rows:            db 0	;number of rows in our window
win_columns:         db 0	;number of columns
box_flag	     db 0	;0=no box 1=box
starting_path_ptr    dd 0	;path to start browsing
execolor           dd 30003234h ;green
devcolor           dd 30003334h ;red
misccolor          dd 30003034h ;black
block_size	equ $ - work_buf_ptr
;
; local data
;
page_top_ptr	dd	0;sort_pointers
select_ptr	dd	0;sort_pointers 	;- highlighted file name
select_ptr_row	db	1		;  display row for highlighted file
old_path	times 40 db (0)

default_path	times 200 db (0)	;default directory path


