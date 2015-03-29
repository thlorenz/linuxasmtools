
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
; AsmFind - search driectory tree for file or text
;
;    usage: asmfind "text string"
;           asmfind
;
;    operation:
;    ----------
;      AsmFind presents a menu if no parameters are given.  This is
;      the expected mode of operation and offers more options than a
;      simple search string.
;
;      After setting the file mask, starting directory, case flag,
;      and search sting the programs uses a fast Boyer-Moore search
;      technique to find text matches.  After each match a list of
;      options are given as follows:
;     
;         ignore this match
;         view file containing match
;         view file with smart file viewer
;         edit file with match
;         abort search
;
;     If a text_string is given to AsmFind it searches the current
;     directory and all sub-directories for a match.  The case is
;     ignored.
;
;     All seraches ignore symbolic links to directories.  This avoids
;     having a link point back to its parent and getting into a
;     infinite loop.
;
;<
;-------------------------------------------------------------------------             

 [section .text]

 extern env_stack
 extern string_form
;%include "string_form.inc"

 extern crt_clear
extern scan_buf_open
extern scan_buf
;%include "scan_buf.inc"
 extern dir_walk
 extern block_open_read
 extern block_read
 extern block_close
 extern get_current_path
 extern stdout_str
 extern read_stdin
 extern kbuf
 extern	str_move
 extern	sys_shell_cmd
 extern move_cursor
 extern key_poll
 extern mouse_enable
 extern view_file
  extern read_termios_0
  extern output_termios_0
  extern reset_clear_terminal
 
 global main,_start

main:
_start:
  cld
  mov	edx,termios
  call	read_termios_0
  mov	ecx,no_wrap
  call	stdout_str

  call	env_stack
  
  pop	ebx			;get parameter count
  dec	ebx			;dec parameter count
  jz	short preload_path	;jmp if no parameters entered
  pop	esi			;get ptr to our executable name
  pop	esi			;get ptr to search string
  mov	edi,fbuf3
  call	str_move
  mov	byte [no_menu_flag],1

preload_path:
;preload search path (fbuf1) with current location
  mov	ecx,fbuf1_len
  mov	ebx,fbuf1		;path buffer
  call	get_current_path
  or	eax,eax
  jns	cont1
  jmp	error_report6
cont1:
;put space at end of path
  mov	esi,fbuf1
  mov	ecx,fbuf1_len
zero_loop:
  lodsb
  or	al,al
  jz	found_zero
  loop	zero_loop 
found_zero:
  dec	esi
  mov	byte [esi],' '

  cmp	byte [no_menu_flag],0
  jne	no_menu_search
  call	mouse_enable
  jmp	short do_menu
no_menu_search:
  call	do_search
  jmp	short find_exit

find_key:
;  mov	eax,[edit_color]
;  call	crt_clear

do_menu:
  mov	eax,[edit_color]
  call	crt_clear
  mov	ebp,find_form_def
  call	string_form
  mov	al,[kbuf]	;get key
  cmp	al,-1		;mouse?
  jne	check_key
  mov	cl,[kbuf + 2]		;get mouse column
  mov	ch,[kbuf + 3]		;get mouse row
  cmp	ch,11			;button row
  jne	do_menu
  cmp	cl,10
  jb	help_key
  cmp	cl,25
  jb	search
  jmp	short find_exit	
check_key:
  cmp	al,0dh
  je	search		;jmp if search
  cmp	al,0ah
  je	search
  cmp	al,1bh
  jne	find_exit	;exit if unknown key
  cmp	[kbuf+1],byte 0 ;possible f1 (help)
  je	find_exit	;exit if escape
help_key:
  call	show_help
  jmp	find_key
search:
  call	do_search
  jmp	find_key
;---------------
find_exit:
  xor	ebx,ebx			;return code=0
find_exit2:
  push	ebx		;save return code
  mov	edx,termios
  call	output_termios_0

;  mov	eax,[edit_color]
;  call	crt_clear
;  mov	ax,0101h		;row 1 column1
;  call	move_cursor		;move cursor
  call	reset_clear_terminal
  pop	ebx		;restore return code
  mov	eax,1
  int	byte 80h

error_report1:
  mov	ebx,1
  jmp	short find_exit2
error_report2:
  mov	ebx,2
  jmp	short find_exit2  
error_report6:
  mov	ebx,6
  jmp	short find_exit2
;------------------------------------------------------------------
do_search:
  xor	eax,eax
  mov	[match_count],eax
  mov	eax,[edit_color]
  call	crt_clear
  mov	ax,0401h		;row 4 column1
  call	move_cursor		;move cursor
  mov	ecx,searching_txt
  call	stdout_str
;move path and put zero at end
  mov	esi,fbuf1
  mov	edi,our_path
  mov	ecx,fbuf1_len
path_loop:
  lodsb
  cmp	al,' '
  je	path_loop_end
  stosb
  loop	path_loop
path_loop_end:
  xor	eax,eax
  stosb				;put zero at end of path
;move file mask
  mov	esi,fbuf2
  mov	edi,our_file
  mov	ecx,fbuf2_len
file_loop:
  lodsb
  cmp	al,' '
  je	file_loop_end
  stosb
  loop	file_loop
file_loop_end:
  xor	eax,eax
  stosb				;put zero at end of file mask

;move search string to our_search_str
  mov	esi,fbuf3-1
  mov	ecx,fbuf3_len
  add	esi,ecx			;point at end of match
match_str_loop:
  cmp	byte [esi]," "
  jne	match_str_end		;jmp if end of string found
  dec	esi
  loop	match_str_loop		;loop till end found
match_str_end:
  mov	esi,fbuf3
  mov	edi,our_search_str
  jecxz	match_str_term		;need if no string entered
  rep	movsb
match_str_term:
  xor	eax,eax
  stosb				;put  zero at end

;setup scan_buf search string
  mov	esi,our_search_str
  mov	dl,0			;preload use case
  cmp	byte [fbuf4],'n'
  jne	got_case		;jmp if "yes" use case
  mov	dl,20h			;match any case
got_case:

  cmp	byte [esi],0		;do we have a match string
  jz	skip_scan		;jmp if no match string  
  call	scan_buf_open		;setup  search keys --
  or	eax,eax
  jnz	error_report1
;read files, starting at dir (fbuf1) with mask fbuf2
skip_scan:
  mov	esi,our_path		;starting path to search
  mov	ebx,our_file		;file mask
;check if match all files
  cmp	word [ebx],002ah	;is '*',0 in buffer?
  jne	walk_setup		;jmp if not "*",0
  xor	ebx,ebx
walk_setup:
  push	ebx
  mov	eax,45
  xor	ebx,ebx			;request memory allocation address
  int	byte 80h
  pop	ebx
;work buffer in eax now
  mov	ecx,0299h		;return files and recurse deep
  mov	edx,file_process
  call	dir_walk		;walk directories looking for match
  or	eax,eax
;  jnz	error_report2
  jnz	do_search_exit		;exit if abort request
  cmp	dword [match_count],0
  jne	do_search_exit
;no matches were found, display message
  mov	ecx,no_match_txt
  call	stdout_str
  call	read_stdin
do_search_exit:
  
  ret

no_match_txt:
  db 0ah
  db ' NO MATCHES FOUND',0ah
  db 0ah
  db ' press any key to continue',0ah
  db 0

searching_txt: db 0ah, ' Seachering....',0ah
               db 'ESC to stop',0
;-----------------------------------------------------------------------------
;called by dir_walk if file found.
; eax=ptr to file path
; ecx=ptr to filename at end of path string
; 
file_process:
  pusha
  mov	[searched_file],eax
  cmp	dword [fbuf3],'    '	;check if search string entered
  jne	fp_search		;jmp  if search string entered
;only searching for file names, show name
;  mov	ecx,nl_text
;  call	stdout_str
;  mov	ecx,[searched_file]
;  call	stdout_str
  jmp	found_match
;setup for text search
fp_search:
  mov	ebx,eax
  call	block_open_read		;file handle returned in ebx
  or	eax,eax
  js	error_report3
  mov	[file_handle],ebx
file_read_loop:
  mov	ebx,[file_handle]
  mov	ecx,file_buffer
  mov	edx,file_buffer_size
  call	block_read		;eax=amount of data read
  or	eax,eax
  js	error_report4
  jz	file_process_exitj		;jmp if done  
  mov	[last_read_size],eax
  mov	esi,file_buffer
  mov	ecx,eax			;buffer length
file_process_loop:
  call	scan_buf
  or	eax,eax
  jz	found_match
  xor	eax,eax			;set normal exit code
  cmp	[last_read_size],dword file_buffer_size
  jb	file_process_exitj
  jmp	short file_read_loop	;jmp if no match

error_report3:
  mov	eax,3
  jmp	short file_process_exitj
error_report4:
  mov	eax,4
; return to dir_walk with eax=0 to continue
file_process_exitj:
  mov	ebx,[file_handle]
  call	block_close
  xor	eax,eax
  jmp	file_process_exit

;match found - save esi,edi,ecx,eax
;  esi = points at remaining data to be scanned
;  edi = pointer to match in buffer
;  ecx = number of bytes remaining to be scanned
;  eax = 0 for match found (may be match split between two blocks)
;  
found_match:
  inc	dword [match_count]
  mov	ax,0401h		;row 4 column1
  call	move_cursor		;move cursor
  mov	ecx,found_match_msg
  call	stdout_str
  mov	ecx,[searched_file]
  call	stdout_str
;display menu of options
;  Ignore this file
;  View with AsmView
;  Smart viewer
;  Open with editor
;  Abort search
  mov	ecx,menu_txt
  call	stdout_str
read_key_lp:
  call	read_stdin
  mov	al,[kbuf]
  cmp	al,'i'
  je	sr_exit1		;jmp if ignore this file
  cmp	al,'v'
  je	sr_asmview		;jmp if view with asmview
  cmp	al,'s'
  je	sr_viewer		;jmp if smart viewer
  cmp	al,'e'
  je	sr_open			;jmp if open with editor
  cmp	al,'a'
  je	file_process_exit	;jmp if abort request
  cmp	word [kbuf],001bh
  je	file_process_exit
  jmp	short read_key_lp 

sr_asmview:
  mov	esi,asmview_txt
  jmp	short sr_launch
sr_viewer:
  mov	esi,viewer_txt
  jmp	short sr_launch
sr_open:
  mov	esi,open_txt
; esi = ptr to launch name
sr_launch:
  mov	edi,launch_line
  call	str_move		;move handler name
  mov	al,' '
  stosb
  mov	esi,[searched_file]
  call	str_move		;move searched file name
  mov	esi,launch_line
  call	sys_shell_cmd
sr_exit1:  
  mov	eax,[edit_color]
  call	crt_clear
  mov	ax,0401h		;row 4 column1
  call	move_cursor		;move cursor
  mov	ecx,searching_txt
  call	stdout_str

  xor	eax,eax			;signal continue
file_process_exit:		;eax =  return code  0=continue
  mov	[return_code],eax
;check for abort key
  rol	dword [count32],1
  jnc	fpe_end			;jmp if not time for key check
  call	key_poll		;check for key
  jz	fpe_end			;exit if no key available
  mov	byte [return_code],1	;force exit
fpe_end:
  popa
  mov	eax,[return_code]
  ret				;return to dir walk
;---------------
  [section .data]
searched_file	dd	0
nl_text:	db	0ah,0
return_code	dd	0
match_count	dd	0
count32		dd	1	;counter
  [section .text]  
;---------------
show_help:
  mov	ebx,help_file
  call	view_file
  ret
;------------------------------------------------
  [section .data]

no_wrap	db 1bh,'[?7l',0

help_file: db '/usr/share/doc/asmref/asmfind.txt',0

no_menu_flag	db	0	;0=menu 1=no menu

launch_line:
  times	100 db 0

asmview_txt:
  db 'asmview',0
viewer_txt:
  db 'viewer',0
open_txt:
  db 'a',0

found_match_msg:
  db 0ah,'Found match in:',0ah,'  ',0
menu_txt:
  db 0ah,0ah
  db '-------------------------',0ah
  db 'SELECT ACTION (i,v,s,e,a)',0ah
  db '-------------------------',0ah
  db 0ah
  db '(i)gnore this file',0ah
  db '(v)iew file with AsmView',0ah
  db '(s)mart file viewer',0ah
  db '(e)dit file (call "a" shell script',0ah
  db '(a)bort the search',0ah,0

;------------------
find_form_def:
 db 16	;ending row
 db 60  ;ending column
 db 1	;starting row
 db 1	;startng column
 dd string1_def ;string with cursor
edit_color:
 dd 30003634h	;text color
 dd 30003136h	;string color
 dd test_form	;form def ptr

test_form:
 db '  ** find file/directory/data **',0ah
 db 0ah
 db 'starting path '
string1_def:
 db -1  ;start of string def
 db 3	;row
 db 15	;column
 db 15	;current cursor posn
 db 0	;scroll
 db 40  ;window size
 dd buf1_end - fbuf1 ;buf size (max=127)
 db -2	;end of string def
fbuf1:
 times  300 db ' '
buf1_end:
 db ' ',0ah,0ah

 db 'files to search '
string2_def:
 db -1  ;start of string def
 db 5	;row
 db 17	;column
 db 17	;current cursor posn
 db 0	;scroll
 db 20  ;window size
 dd buf2_end - fbuf2 ;buf size (max=127)
 db -2	;end of string def
fbuf2:
 db '*'
 times  40 db ' '
buf2_end:
 db ' (*=wild)',0ah,0ah

 db 'match string  '
string3_def:
 db -1  ;start of string def
 db 7	;row
 db 15	;column
 db 15	;current cursor posn
 db 0	;scroll
 db 20  ;window size
 dd buf3_end - fbuf3 ;buf size (max=127)
 db -2	;end of string def
fbuf3:
 times  100 db ' '
buf3_end:
 db ' (no wildcards)',0ah,0ah

 db 'consider case '
string4_def:
 db -1  ;start of string def
 db 9	;row
 db 15	;column
 db 15	;current cursor posn
 db 0	;scroll
 db 3  ;window size
 dd buf4_end - fbuf4 ;buf size (max=127)
 db -2	;end of string def
fbuf4:
 db 'no '
buf4_end:
 db ' ',0ah,0ah

 db '  <F1>=help <Enter>=do search  <ESC>=exit',0


fbuf1_len equ buf1_end - fbuf1
fbuf2_len equ buf2_end - fbuf2
fbuf3_len equ buf3_end - fbuf3


  [section .text]
;-------------------------

;  %include "scan_buf.inc"
;  %include "setup_table.inc"
;  %include "dir_walk.inc"
;  %include "dir_read_grow.inc"
;  %include "form2.inc"
;--------------------------------------------
  [section .bss]
termios:	resb	36
file_handle	resd	1
last_read_size	resd	1			;size of last disk read
our_path	resb	300
our_file	resb	100
our_search_str	resb	100
file_buffer_size equ	100000			;used by scan_buf to read file
file_buffer	resb	file_buffer_size

