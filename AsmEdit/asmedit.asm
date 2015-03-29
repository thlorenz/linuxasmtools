
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
  extern read_window_size
  extern crt_columns,crt_rows
  extern reset_clear_terminal

;****f* -/asmedit *
; NAME
;  asmedit (a) - assembler IDE and editor
; INPUTS
;  * usage:  a <file1> <file2>
;  * -
;  * "a" has a list of plugins (see below)
;  * -
;  * plugins can be in any executable format.  Some
;  * can be scripts and others can be ELF files.
; OUTPUT
;  * "a" requests the following plugins:
;  * asmedit_setup - configuration and setup
;  * file_browse - file browser for loading files
;  * show_sys_err - display error text
;  * a_help - help files and reference info
;  * a_plan - reminder and planner
;  * a.f3 - "make" file kickoff script
;  * a.f4 - "debug" kickoff script
;  * a.f5 - "spell" script
;  * a.f6 - file compare script
;  * a.f7 - file print script
;  * a.f8 - user defined, attached to f8 key
;  * a.f9 - user defined, attached to f9 key
;  * (all plugins can be replaced by user)
; NOTES
; * source file: asmedit.asm
; * asmedit can no longer run without an install.
; * -
; * The base for AsmEdit is an editor which is described
; * in file /doc/asmedit.
; * ----------------------------------------------
;*******
; ----------- the "a" editor Version beta .2.0 ------------
;
;INDEX: (search for key.. #0, #1 etc.)
; #0 structures includes
; #1 main 
; #2 keyboard and mouse commands
;   #A -> #Z menu keys
;   #a -> #z normal non-menu commands
;   #^a -> #^z control keys
;   #f1 -> #f10 function keys
;   #cursor cursor keys (up,down,home,Ins, etc.)
; #3 keyboard processing
; #4 mouse processing
; #5 file processing
; #6 edit buffer and cursor processing + find
; #7 conversion and calc
; #8 error,  kernel inerface, shell out
; #9 display handlers
; #10 database - error messages & others
; #11 database - menu tables
; #12 database - key tables
; #13 database - active window and file data
; #14 database - misc data
; #15 database - buffers

;----------------------------------------------------------------------
;
;  This program is free software; you can redistribute it and/or modify
;  it under the terms of the GNU General Public License as published by
;  the Free Software Foundation; either version 2 of the License, or
;  (at your option) any later version.
;
;  This program is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;  GNU General Public License for more details.
;
;  You should have received a copy of the GNU General Public License
;  along with this program; if not, write to the Free Software
;  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
;
;----------------------------------------------------------------------
;  This program contains code borrowed from the "e3" editor and
;  "libASM".  Thanks to the authors.
;----------------------------------------------------------------------

; Cursor placement rules
;  1. EOF is special case where cursor can point at 0ah beyond end of file
;  2. If cursor rests on OAh char it is displayed as blank and still part of
;     of current line.  Any edit entry will push 0ah and not overwrite it.
;  3. cursor will always match the row/column variable.
;

ERRNOMEM equ 12
ERRNOIO equ 5
maxfilenamelen equ 300


O_WRONLY_CREAT_TRUNC equ 1101q

xstdin equ 0
stdout equ 1
optslen equ 124
TAB equ 8
TABCHAR equ 09h
SPACECHAR equ ' '
CHANGED equ '*'
UNCHANGED equ SPACECHAR
LINEFEED equ 0ah
NEWLINE equ LINEFEED
RETURN equ 0dh
SEDBLOCK equ 4096


[section .text]
[absolute 0]
termios_struc:
.c_iflag: resd 1
.c_oflag: resd 1
.c_cflag: resd 1
.c_lflag: resd 1
.c_line: resb 1
.c_cc: resb 19
termios_struc_size:


[section .text]
[absolute 0]
winsize_struc:
.ws_row:resw 1
.ws_col:resw 1
.ws_xpixel:resw 1
.ws_ypixel:resw 1
winsize_struc_size:


; (#1#) main **********************************************

[section .text]
[bits 32]
  global _start
  global main

; ----------- test code --------------
;  jmp	.t
;.msg  db	0ah,'we arrived at ----',0ah,0
;.t: pusha
;   mov	ecx,.msg
;      call	display_asciiz
;      popa
;----------- test code ---------------

; The program begins execution here...... 
;
main:
_start:
  cld
  mov	ebp,esp			;save stack
env_lp:
  pop	eax
  or	eax,eax
  jnz	env_lp			;loop till start of env ptrs
  mov	[enviro_ptrs],esp
  mov	esp,ebp			;restore origional stack ptr

  call	memory_setup
  call	terminal_setup		;setup  terminal
  call install_signals		;signal handler,
  call	get_history		;read history data to editbuf
  cmp	al,0			;are we installed?
  jne	abort_exit2		;abort if error,user abort, or not installed
  call	process_scan
  call	set_window_sizes	;pre compute window sizes
  call	active_window_setup	;initialize database for mode 0 window size

  mov	esi,esp
  call	parse_command_line	;get file names & set ebp flag in=ecx,esi
;
; This is the top level loop that responds to keys and clicks
;
MainCharLoop:
  mov	edx,01000000h		;select bold text for active screen
  call	display_screen
  call display_status_line
  call HandleChar		;process user key press or click
  cmp	byte [exit_program_flg],0 ;does user want to exit?
  je	MainCharLoop		;loop back for another key or mouse event
;
; exit
;
E3exit:
  call	write_history_file
e4_exit:
;
; remove file tmp.blk from /tmp
;
  mov	ebx,block_file_name
  mov	eax,10			;ulink kernel call
  int	byte 80h
abort_exit2:
  mov	eax,24
  int	byte byte 80h
  or	eax,eax
  jnz	abort_exit3		;jmp if not root
;we are root, remove tmp file that may be owned by root
;and not writable by non-root users
  mov	ebx,file1_tmp_name
  mov	eax,10
  int	byte 80h
  mov	ebx,file2_tmp_name
  mov	eax,10
  int	byte 80h

abort_exit3:
  call	clear_screen
  mov	ah,[status_line_row]
  mov	al,1
  call	move_cursor
abort_exit:
  call	terminal_restore	;restore terminal state
  call	reset_clear_terminal
  mov	eax,1			;exit code for kernel
  xor	ebx,ebx			;return code
  int	byte 80h			;exit	    

;----------------------------------------------------------
; MAIN function for processing keys - HandleChar processes
; all keys and clicks.
;
HandleChar:
blp1:
get_key:
  call	read_keys		;get keyboard data
  cmp	byte [kbuf],-1		;check if mouse click
  jne	key_event		;jmp if key press
  call	mouse_event
  jmp	gs_exit
key_event:
;
; skip enabling keyboard status if in CMD mode and upper case key pressed
;
  cmp	byte [key_mode],0
  jne	enable_key_status
  cmp	byte [kbuf],' '
  je	gs_cont				;if space don't enable key mode
                                        ; this allows toggle of buttons.
  cmp	byte [kbuf],'A'
  jb	enable_key_status		;jmp if not upper case letter
  cmp	byte [kbuf],'Z'			;  we want to enable menu's if
  ja	enable_key_status		;    upper case letter was pressed
  jmp	gs_cont
enable_key_status:
  mov	byte [mouse_mode],0		;turn off menu's if key press
gs_cont:
  mov	eax,dword [kbuf]
  call	decode_key			;ecx = index or err(0)
  jecxz	gs_exit
  call	[ecx]				;call keyboard process !!!!
gs_exit:
  ret	

; (#2#) key commands  ***********************************
; Everything in this section is attached to a keyboard key
; or mouse event.  The tables in database are used to
; connect these events to keys or mouse events.
;----------------------- entered via jump table ------------
;
; char for edit buffer in kbuf
;
NormChar:
  mov	edi,[editbuf_cursor_ptr]	;get file data ptr
  cmp byte [edi],NEWLINE
  jz InsertChar			;if /n at cursor then overtype not allowed
  cmp byte [insert_overtype],1	;check insert/overtype mode
  jnz	OverWriteChar
InsertChar:
  call Insert1Byte		;insert current char in buffer.
  jc InsWriteEnd
OverWriteChar:
  mov	al,byte [kbuf]		;get char
  cmp	al,0dh			;check if enter key
  jne	stuff_it		;jmp if not <return>
  mov	al,0ah
stuff_it:
  stosb
  mov byte [file_change],CHANGED	;set changed flag to "*"
InsWriteEnd:
  call	key_right		;move cursor right
  ret

;-----	#esc - AEDIT set cmd mode ---------------------------------

set_cmd_mode:			;escape processing
  mov	dword [key_mode],0	;set CMD mode
  call	clear_block
scm_exit:  
  ret

; (#A#) key commands  ***********************************

  ;same as "a" (again) no special menu process

; (#B#) block menu    ***********************************

m8mode:
  mov	byte [mouse_mode],8
  ret

; (#C#) calc          ***********************************

m5_calc:
  call	calc
  mov	byte [mouse_mode],5
  ret

; (#D#) del block     ***********************************

m8_dblock:
  call	dmark_block
  jmp	m8_cont

; (#E#) QE exit       ***********************************

m_exit:
  call	save_and_exit
  ret

; (#F#) find menu     ***********************************

m7mode:
  mov	byte [mouse_mode],7
  ret

; (#G#) get block     ***********************************

m8_getblock:
  call	get_block
  jmp	m8_cont

; (#H#) help menu     ***********************************

m10mode:
  call	KeyHelp
  ret

; (#I#) insert mode   ***********************************

m6_insert:
  call	insert_mode
  mov	byte [mouse_mode],6
  ret

; (#J#) jump menu     ***********************************

m4mode:
  mov	byte [mouse_mode],4
  ret

;       #J  - AEDIT tag commands for jump menu----------------------

m4_eof:
  mov	ecx,999999
  jmp	short m4_entry
;-----------------------
m4_top:
  mov	ecx,1
  jmp	short m4_entry
;-----------------------
m4_tag1:
  mov	ecx,[tag_a]
  jmp	short m4_entry
m4_tag2:
  mov	ecx,[tag_b]
  jmp	short m4_entry
m4_tag3:
  mov	ecx,[tag_c]
  jmp	short m4_entry
m4_tag4:
  mov	ecx,[tag_d]
m4_entry:
  call	goto_line
  mov	byte [mouse_mode],4
  ret

m4_tags1:
  mov	edi,tag_a
  jmp	short m4_entrys
m4_tags2:
  mov	edi,tag_b
  jmp	short m4_entrys
m4_tags3:
  mov	edi,tag_c
  jmp	short m4_entrys
m4_tags4:
  mov	edi,tag_d
m4_entrys:
  mov	eax,[cursor_linenr]
  mov	[edi],eax
m4_exit:
  mov	byte [mouse_mode],4
  ret

; (#K#) find bacK     ***********************************

m_find_back:
  call	find_back
  ret


; (#L#) goto Line     ***********************************

m4_line:
  call	jump_line
  mov	byte [mouse_mode],4
  ret

; (#M#) Misc menu     ***********************************

m5mode:
  mov	byte [mouse_mode],5
  ret

; (#N#) New file      ***********************************

m_newfile:
  call	init_newfile
  mov byte [file_change],UNCHANGED	;set changed flag to " "
  mov	byte [mouse_mode],2
  ret	

; (#O#) Other file    ***********************************
;-----	#O   - other file    --------------------------------------

m3_other:
  call	other
  mov	byte [mouse_mode],3
  ret

; (#P#) paragraph     ***********************************

m5_paragraph:
  call	paragraph
  mov	byte [mouse_mode],5
  ret

; (#Q#) Quit menu     ***********************************

m2mode:
  mov	byte [mouse_mode],2
  ret 

; (#R#) Replace/fine  ***********************************

m7_replace:
  call	find_and_replace
  mov	byte [mouse_mode],7
  ret

; (#S#) Set menu      ***********************************

m9mode:
  call	update_config
;  mov	byte [mouse_mode],9
  ret

; (#T#) ediT menu     ***********************************

m6mode:
  mov	byte [mouse_mode],6
  ret

; (#U#) Update file   ***********************************

m_update:
  mov	byte [file_change],CHANGED	;force save of zero len files
  call	save_edit_file
  mov	byte [mouse_mode],2
  ret

; (#V#) Save file as ***********************************

m_write:
  mov	esi,file_path
  mov	byte [esi],0		;remove current filename if it exists
  mov	byte [file_change],CHANGED ;force save under new name
  call	save_edit_file
  mov byte [file_change],UNCHANGED	;set changed flag to " "
  mov	byte [mouse_mode],2
  ret

; (#W#) Window menu   ***********************************

m3mode:
  cmp	byte [mouse_mode],3
  jne	m3_10			;jmp if menu wanted
  jmp	window			;go toggle window
m3_10:
  mov	byte [mouse_mode],3
  ret

; (#X#) overtype      ***********************************

m6_overtype:
  call	xchange_mode
  mov	byte [mouse_mode],6
  ret

; (#Y#) insert/Yank file ********************************

m8_get:
  call	get_file
m8_cont:
  mov	byte [mouse_mode],8
  ret

; (#Z#) abort/deZert files *******************************

m_abort:
  mov	byte [exit_program_flg],2
  ret

; (#+#) find forward *************************************

m_find_fwd:
  call	find_forward
  mov	byte [mouse_mode],7
  ret

; orphans ********************************************


;       #  - AEDIT get hex  (no menu key)--------------------------

m6_hex:
  call	hex_input
  mov	byte [mouse_mode],6
  ret

; mark block         **********************************
;; no menu key attached ??

m8_markblock:
  call	mark_block
  jmp	short m8_cont


; (#a#) again         ***********************************
; removed, use macros instead  
again:
  cmp	byte [last_cmd],1
  jne	again_30		;jmp if last cmd was not find
  mov	edi,[editbuf_cursor_ptr]		;get search point
  call	find_again1
  mov	[editbuf_cursor_ptr],edi
again_30:
  cmp	byte [last_cmd],2	
  jne	again_40		;exit if last cmd was not a macro
  mov	eax,macro_buffer
  mov	[macro_ptr],eax
  mov	byte [macro_flag],2	;enable playback
again_40:
  cmp	byte [macro_flag],0
  je	again_90		;exit if not inside macro
  mov	dword [special_status_msg_ptr],again_err
again_90:
  mov	byte [macro_forever_flg],0
  ret

again_err: db "Can not repeat inside macro",0
  
; (#b#) block mark/unmark ****************************

mark_block:
  mov	edi,[editbuf_cursor_ptr]
  cmp	dword [blockbegin],0
  je	begin_block
  cmp	dword [blockbegin],edi
  je	clear_block

  mov   [blockend],edi
  cmp	edi,[blockbegin]
  jae	mb_1			;jmp if blockbegin first
  xchg  dword [blockbegin],edi
  xchg  dword [blockend],edi
mb_1:
  call save_block		;save block
  jmp  clear_block		;done saving block
begin_block:
  mov  dword [blockbegin],edi
  mov	byte [showblock],1
  jmp	mb_end
;
; entered externally.. beware
clear_block:
  mov	dword [blockbegin],0
  mov	byte [showblock],0
  mov	dword [blockend],0
mb_end:
  ret

; (#c#) calc          ***********************************
;
; simple calculator.
; if single number entered it is displays as decimal and hex
; if two numbers are entered they need an operator (+ - * /)
;    and the result is displayed as decimal and hex
;
; This code could be improved but it works so why bother.

calc:
  mov	esi,calc1_msg		;prompt message
  mov	edi,bakpath		;buffer for data
  mov	eax,40            	;max length of string
  mov	byte [str_terminator],0 ;allow both "esc" and "rtn" as terminators
  mov	byte [edi],0		;clear any existing string
  call	get_string
  jecxz	calc_1
  jmp	calc_exit		;exit if nothing entered
;
; eax = length of string entered
;
calc_1:
  mov	esi,bakpath		;get ptr to data
  call	calc_parse		;sets esi=start edi=ending separator
  cmp	byte [esi],' '
  jae	calc_2			;jmp if value ok
  jmp	calc_exit
calc_2:
  mov	al,byte [edi -1]	;check if hex
  cmp	al,'h'
  je	calc_hex1		;jmp if hex value
  cmp	al,'H'
  je	calc_hex1		;jmp if hex value
;
; assume first value is decimal ascii
;
  cmp	byte [esi],'-'		;check if negative number
  jne	calc_4			;jmp if not -
  inc	esi			;move past
  call	ascii_to_decimal
  neg	ecx			;convert to negative number
  inc	edi
  jmp	calc_10
calc_4:
  call	ascii_to_decimal	;result to ecx
  jmp	calc_10
calc_hex1:
  call	hex_ascii_to_binary

calc_10:
  mov	edx,ecx			;save value in edx
;
; go get next value
;
  mov	esi,edi
  call	calc_parse		;expect operator back
  
  mov	al,[esi]		;get first char
  cmp	al,'+'
  je	calc_plus
  cmp	al,'-'
  je	calc_minus
  cmp	al,'*'
  je	calc_mul
  cmp	al,'/'
  je	calc_div
  cmp	al,'n'
  je	calc_neg
  jmp	short calc_show
calc_plus:
  push	calc_add
  jmp	short calc_40
calc_minus:
  push	calc_sub
  jmp	short calc_40
calc_mul:
  push	calc_multiply
  jmp	short calc_40
calc_div:
  push	calc_divide
  jmp	short calc_40
calc_neg:
  jmp	calc_negate
calc_40:
  mov	esi,edi
  call	calc_parse
  cmp	byte [esi],' '
  jb	calc_show		;jmp if nothing available
  mov	al,byte [edi -1]	;check if hex
  cmp	al,'h'
  je	calc_hex2		;jmp if hex value
  cmp	al,'H'
  je	calc_hex2		;jmp if hex value
;
; assume first second is decimal ascii
;
  call	ascii_to_decimal	;result to ecx
  jmp	calc_60			;go do operation
calc_hex2:
  call	hex_ascii_to_binary
calc_60:
  pop	eax
  jmp	eax
;
; do calculation, values in edx,ecx
;
calc_add:
  add	ecx,edx
  jmp	short calc_show
calc_sub:
  sub	edx,ecx
  xchg	ecx,edx
  jmp	short calc_show
calc_multiply:
  mov	eax,edx
  xor	edx,edx
  mul	ecx
  mov	ecx,eax		;results in eax?
  jmp	short calc_show
calc_divide:  
  mov	eax,edx
  xor	edx,edx
  jecxz	calc_exita	;jmp if error
  div	ecx
  mov	ecx,eax		;results to eax
  jmp	short calc_show
calc_exita:
  jmp	calc_exit
calc_negate:
  neg	edx
  mov	ecx,edx
;
; display contents of ecx
;
calc_show:

  push	ecx
  mov	eax,ecx
  mov	dword [calc3_msg],'    '
  mov	dword [calc3_msg +4],'    '	
  mov	edi,calc3_msg + 8
  call	IntegerToAscii
  pop	ecx
  mov	edi,calc4_msg
  call	dword_to_hex_ascii
;
; setup for display call
;
  mov	eax,[status_color1]
  mov	bl,1
  mov	bh,[status_line_row]
  mov	ecx,calc2_msg
;
; put zero at end of message
;
  xor	edx,edx
  mov	dl,[term_columns]
  add	edx,calc2_msg
  mov	byte [edx],0
  
  call	display_color_at  	;display results
  mov	eax,[crt_cursor]	;put cursor at correct point
  call	move_cursor
  call	read_keys
calc_exit:
  ret  


; (#d#) block delete  ***********************************

dmark_block:
  mov	edi,[editbuf_cursor_ptr]
  cmp	dword [blockbegin],0
  je	begin_block
  cmp	dword [blockbegin],edi
  je	clear_dblock

  mov   [blockend],edi
  cmp	edi,[blockbegin]
  jae	mdb_1			;jmp if blockbegin first
  xchg  dword [blockbegin],edi
  xchg  dword [blockend],edi
mdb_1:
  call	save_block
  call	cut_block  
  jmp  clear_dblock		;done saving block
begin_dblock:
  mov  dword [blockbegin],edi
  mov	byte [showblock],1
  jmp	mdb_end
clear_dblock:
  mov	edi,[blockbegin]	;set top of display
  call	center_cursor
  mov	dword [blockbegin],0
  mov	byte [showblock],0
  mov	dword [blockend],0
mdb_end:
  ret

; (#e#) execute macro ***********************************

macro_execute_menu:
  mov	byte [last_find_status],1 ;set found=yes so macro does
;                                 ;not think we are at end forever repeat
  cmp	byte [macro_flag],0
  jne	mem_exit		;exit if marco not idle
  mov	esi,macro_prompt_msg
  mov	edi,char_out		;character buffer
  mov	byte [edi],0		;clear any existing buffer contents
  mov	eax,1			;max input string size
  call	get_string
  jecxz	mem_got
  jmp	mem_exit		;exit if nothing entered
mem_got:
  mov	al,[char_out]
  cmp	al,'y'			;execute again?
  je	mem_execute
  cmp	al,'f'			;execute to End of buffer?
  je	mem_forever
  jmp	mem_exit
mem_forever:
  mov	byte [macro_forever_flg],2	;set macro repeat forever
  mov	dword [do_again_ck],0
mem_execute:
  mov	eax,macro_buffer
  mov	[macro_ptr],eax
  mov	byte [macro_flag],2	;enable playback
  jmp	mem_exit
mem_exit:  
  ret

; (#f#) find          ***********************************
;
; input: edi = curosr position
;        [file_end_ptr] = end of buffer
; output: carry set if not-found and ignore following
;         edi - points to new cursor posn if found
;         [find_str_len] - length of find string
;         find_str - find string
find_forward:
  mov	dword [scan_direction],1	;set direction flag - forward
  call	find_string
  ret
	
; (#g#) get buffer/file *********************************

get_file:
  mov	esi,get_prompt_msg
  mov	edi,char_out		;character buffer
  mov	byte [edi],0		;clear buffer
  mov	eax,1			;max input string size
  call	get_string
  mov	al,byte [kbuf]
  cmp	al,03			;ctrl-c
  je	gf_exit
  cmp	al,1bh			;esc
  je	gf_exit
  cmp	al,0dh			;check if oa or 0d
  jbe	get_block		;
  cmp	al,'b'
  je	get_block
;get file
gf_file:
  mov	ecx,blockpath
  mov	byte [ecx],0		;clear current contents of blockpath
  cmp	byte [macro_flag],0	;if inside macro do not shell out
  jne	gf_a			;jmp if macro active
  call	exec_browser
;  jnc	gf_01			;jmp if something entered
  jc	gf_exit			;exit if nothing entered
gf_a:
;  mov	esi,block_msg		;prompt message
;  mov	edi,blockpath		;buffer for name
;  mov	byte [edi],0		;clear buffer contents
;  mov	eax,maxfilenamelen	;max length of filename
;  mov	byte [str_terminator],0 ;allow both "esc" and "rtn" as terminators
;  call	get_string
gf_01:
  mov	eax,blockpath
  mov	dl,11h			;insert file, find file in local dir
  cmp	byte [eax],0
  jnz	gf_2			;jmp if filename entered
  jmp	short gf_exit
;get block
get_block:			;entry point !!
  mov	eax,block_file_name
  mov	dl,12h			;insert file, find file at $HOME/base
gf_2:
  mov	ebx,[editbuf_cursor_ptr]	;get insert point
  call	file_read
;  js	gf_err			;exit if error

gf_exit:
  call	other
  call	other
  cmp	byte [active_window],4
  jb	gf_20			;jmp if not vertical window mode
  call	vertical_bar
gf_20:
  ret

; (#h#) key commands  ***********************************

;       #h - AEDIT                 ---------------------------------

; the "h" key calls KeyHelp


; (#i#) insert mode   ***********************************
;
insert_mode:
  mov	dword [key_mode],1		;set cmd/edit mode
  mov	dword [insert_overtype],1	;set insert/overtype mode
  call	clear_block			;clear block just incase
  ret

; (#j#) jump menu     ***********************************

jump_menu:
  mov	esi,jump_prompt_msg
  mov	edi,char_out		;character buffer
  mov	byte [edi],0		;clear buffer
  mov	eax,1			;max input string size
  call	get_string
  mov	al,byte [char_out]
  jecxz jm_1			;jmp if string entered
  jmp	jm_end  
jm_1:
  cmp	al,'s'
  jne	jm2			;jump if "s" for start of file
  mov	ecx,1			;move to beginning of file
  jmp	jm8
jm2: 
  cmp	al,'e'			;check if 'e' for end
  jne	jm3			;jump if not "e"
  mov   ecx,999999
  jmp	jm8
jm3:
  cmp	al,'l'			;check if 'l' for line#
  jne	jm4			;exit if not 'l'
  call	jump_line
  jmp	jm_end
  
jm4:
  cmp	al,'a'			;tag a
  jne	jm5
  mov	ecx,[tag_a]
  jmp	jm8
jm5:
  cmp	al,'b'
  jne	jm6
  mov	ecx,[tag_b]
  jmp	jm8

jm6:
  cmp	al,'c'
  jne	jm7
  mov	ecx,[tag_c]
  jmp	jm8

jm7:
  cmp	al,'d'
  jne	jm_end
  mov	ecx,[tag_d]
jm8:
  jecxz jm_end
  call	goto_line		;go to line in ecx
jm_end:
  ret
;-----------------------------
jump_line:
  mov esi,asklineno
  mov	edi,optbuffer
  mov	byte [edi],0		;clear buffer
  mov	eax,optslen
  mov	byte [str_terminator],0 ;allow both "esc" and "rtn" as terminators
  call	get_string
  mov	esi,optbuffer
  call	ascii_to_decimal
  jecxz	jl_exit			;exit if nothing entered
  call	goto_line		;go to line in ecx
jl_exit:
  ret

; (#k#) key commands  ***********************************
;       #k - AEDIT kill window ---------------------------------------
;; not implemented - available

; (#l#) key commands  ***********************************
;       #l - AEDIT             ---------------------------------------
;; not implemented - available

; (#m#) macro begin/end *********************************

macro_record_toggle:
  cmp	byte [macro_flag],1
  je	macro_stop
;
; macro record start
;
  cmp	byte [macro_flag],0
  jne	mrt_exit		;we are inside macro playback?
  mov	byte [macro_flag],1	;enable record
  mov	eax,macro_buffer
  mov	[macro_ptr],eax		;reinitialize pointer to buffer
  mov	eax,[status_color2]
  xchg	[status_color],eax
  mov	[status_color2],eax	;toggle colors
  jmp	mrt_exit
;
; macro record stop
;
macro_stop:
  mov	eax,[macro_ptr]
  mov	byte [eax-2],0		;zero out 'm' in macro buffer
  mov	eax,[status_color2]
  xchg	[status_color],eax
  mov	[status_color2],eax	;toggle colors
  mov	byte [macro_flag],0	;disable macro record
  mov	byte [last_cmd],2	;set macro as last cmd
mrt_exit:
  ret

; (#n#) key commands  ***********************************
;       #n - AEDIT other file ----------------------------------------
;; not implemented - available

; (#o#) other file    ***********************************

other:
  call	clear_block
;
; decode old window mode
;
  mov	eax,[active_window]
  or	eax,eax
  jz	win0mode  
  dec	eax
  jz	win1mode
  dec	eax
  jz	win2mode
  dec	eax
  jz	win3mode
  dec	eax
  jz	win4mode
  dec	eax
  jz	win5mode
;
; common processing 0. move new template for window
; (old modes 1-4)   1. display "dim" current file in non-active window
;                   2. save current file data & write to file
;                   3. move other file data to active area, read file?
;                   4. display new active window
; switch from mode 0 (single-a) file1 to mode 1 (single-b) file2
;
win0mode:
  mov	byte [active_window],1	;set new mode
  mov	ebx,term_statusln	;new dimensins for old window
  mov	ebp,term_statusln	;get new window dimensions
  jmp	short winswitch
;
; switch from mode1 (single-b) file2 to mode0 (single-a) file1
;
win1mode:
  mov	byte [active_window],0	;set new mode
  mov	ebx,term_statusln	;new dimensions for old window
  mov	ebp,term_statusln	;get new window dimensions
  jmp	short winswitch
;
; switch from mode2 (hor-a-top) to mode3 (hor_b_bottom)
;
win2mode:
  mov	byte [active_window],3	;set new mode
  mov	ebx,hor_a_status	;new dimensions for old window
  mov	ebp,hor_b_status	;get new window dimensions
  jmp	short winswitch
;
; switch from mode3 (hor-b-bottom) to mode2 (hor_a_top)
;
win3mode:
  mov	byte [active_window],2	;set new mode
  mov	ebx,hor_b_status	;new dimensions for old window
  mov	ebp,hor_a_status	;get new window dimensions
  jmp	short winswitch
;
; switch from mode4 (vert-left-a) to mode5 (vert_right-b)
;
win4mode:
  mov	byte [active_window],5	;set new mode
  mov	ebx,ver_a_status	;new dimensions for old window
  mov	ebp,ver_b_status	;get new window dimensions
  jmp	short winswitch
;
; switch from mode5 (vert-b-right) to mode4 (vert_a_left)
;
win5mode:
  mov	byte [active_window],4	;set new mode
  mov	ebx,ver_b_status	;new dimensions for old window
  mov	ebp,ver_a_status	;get new window dimensions
winswitch:
  call	switch_windows
winexit:
  ret

; (#p#) paragraph     ***********************************

paragraph:
  mov	esi,para1_msg		;prompt message
  mov	edi,char_out		;single character buffer
  mov	byte [edi],0		;clear buffer of strings
  mov	eax,1			;read one char
  call	get_string
  mov	al,byte [char_out]	;get char
  cmp	al,'m'
  jne	par_01			;jmp if not margin set
;
; set margins here
;
  mov	esi,para2_msg		;get left margin
  mov	edi,optbuffer
  mov	byte [edi],0		;clear buffer of strings
  mov	eax,2			;length of input
  mov	byte [str_terminator],0 ;allow both "esc" and "rtn" as terminators
  call	get_string
  mov	esi,optbuffer
  call	ascii_to_decimal	;results to ecx
  jecxz	p_abort			;exit if nothing entered
  mov	byte [left_margin],cl

  mov	esi,para3_msg		;get right margin
  mov	edi,optbuffer
  mov	byte [edi],0		;clear buffer
  mov	eax,2			;length of input
  mov	byte [str_terminator],0 ;allow both "esc" and "rtn" as terminators
  call	get_string
  mov	esi,optbuffer
  call	ascii_to_decimal	;results to ecx
  jecxz	p_abort			;exit if nothing entered
  mov	byte [right_margin],cl
p_abort:
  jmp	par_exit
;
; check if F(flow) option
;
par_01:
  cmp	al,'f'
  jne	p_abort			;jmp if no legal options entered
;
; paragraph cursor location
;
par_01a:
  mov	ecx,-1		;set boundry search up
  mov	esi,[editbuf_cursor_ptr]
  call	para_check
  mov	esi,edx
par_01b:
  dec	esi
  cmp	byte [esi],0ah
  jne	par_01b
  inc	esi
  mov	[top_of_para],esi ;save top
;
; go look for bottom of paragraph
;
  mov	ecx,1
  call	para_check
  mov	[end_of_para],edx
  cmp	edx,[top_of_para]
  jne	p_05
  jmp	par_60  
;
; make hole to give us some work room
;
p_05:
  mov	eax,100
  mov	edi,[top_of_para]
  push	edi
  call	make_hole
  pop	edi		;edi points to top of work area (fill)
  mov	esi,[top_of_para]
  add	esi,100
  mov	ebp,[end_of_para]
  add	ebp,100
;
;     edi - top fill ptr
;     esi - top of paragraph
;     ebp - end of paragraph
;
  mov	bl,[left_margin]
  mov	bh,[right_margin]
;
; this is the top of loop to format one line
;
par_06:
  mov	dl,1			;current column
;
; adjust for left margin by stuffing blanks till start of paragraph reached
;
par_08:
  mov	al,' '
  cmp	dl,[left_margin]	;dl=current column
  je	par_09			;jmp if at left margin starting point
  stosb				;store space
  inc	dl			;bump column
  jmp	par_08			;loop till left margin reached
;
; skip leading blanks at line beginning
;
par_09:
  cmp	byte [esi],' '		;blank at beginning of line?
  jne	par_10			;jmp if non-blank found
  inc	esi
  jmp	par_09			;remove leading blanks
;
; loop to move data [esi] -> [edi] till right_margin reached.
; replace 0ah with space
; 
par_10:
  cmp	esi,ebp
  jae	par_50			;jmp if paragraph formatted
  lodsb				;get next char.
  cmp	al,0ah
  jne	par_10a			;jmp if not 0ah
  mov	al,' '			;substitute space
par_10a:
  cmp	al,' '
  jne	par_11			;jmp if not space
  cmp	byte [edi-1],al		;did we store a space last?
  jne	par_11
  jmp	par_10			;skip this space
par_11:
  stosb
  inc	dl
  cmp	dl,[right_margin]
  jne	par_10			;loop till margin reached
;
; we have reached right margin.  now backtrack if cutting word in half
;
  cmp	al,' '
  je	par_12			;jmp if last character was space
  cmp	byte [esi],' '		;is next char a space
  jne	par_20			;jmp if partial word
  lodsb				;get space and ignore it
par_12:
  mov	al,0ah
  stosb
  jmp	par_06			;continue fill
;
; we are at right margin and a word is split, check if whole line is one word
;
par_20:
  push	edi			;save stuff ptr
  mov	ah,dl			;get right margin in -ah-
  shr	ah,1			;compute center of line
par_24:
  dec	ah
  jz	par_30			;jmp if this word too big to split
  dec	edi
  cmp	byte [edi],' '
  jne	par_24			;loop till beginning of word found
  pop	edi			;restore edi
  jmp	par_40			;go move word to next line
;
; split this big word and hope for best
;
par_30:
  pop	edi
  jmp	par_12
;
; we are still at right margin and it is possible to move split word to next line.
; go back to beginning of partial word and blank it out
;
par_40:
  mov	al,' '
  dec	esi
  dec	edi
;  mov	byte [edi],al		;blank partial word
  cmp	byte [edi],al
  jne	par_40			;loop till beginning of word found
;
; we are sitting on space before last word
;
  inc	esi			;skip over space
  mov	al,0ah
  stosb
  jmp	par_06			;go do next line  
;
; paragraph now formated, close hole
;  edi - points at end of good paragraph
;  esi/ebp - point at end of work area
;
par_50:
  mov	eax,esi		;get end of block
  sub	eax,edi		;compute size of hole
  call	DeleteByte	;close hole
  jc	par_70		;jmp if error
par_60:
  mov	edi,[end_of_para]
par_62:
  cmp	edi,[file_end_ptr]
  je	par_70
  inc	edi
  mov	al,[edi]
  cmp	al,0ah
  je	par_62
  cmp	al,' '
  je	par_62
  cmp	al,09h
  je	par_62
par_70:
  call	center_cursor
par_exit:
  ret  

;--------------
; assist with check for begin/end of paragraph
;  input: esi = current locaton in buffer
;         ecx = 1(search forward)  -1(search backwards)
; output:  esi = pointer to current char
;          edx = pointer to last text char (paragraph area)
;
para_check:
  mov	bl,0
  mov	edx,esi		;preload paragraph start
para_lp:
  cmp	cl,1
  je	pc_2		;jmp if forward scan
  cmp	esi,[editbuf_ptr]
  jmp	pc_4		;
pc_2:
  cmp	esi,[file_end_ptr]
pc_4:
  je	pc_stop
pc_lp:
  mov	al,[esi]	;get current char
  cmp	al,09h		;check if tab
  je	pc_30		;go ignore tabs
  cmp	al,' '
  je	pc_30  		;jmp to ignore space
  cmp	al,0ah
  je	pc_got_a
  mov	bl,0		;set consecutive 0a count to zero
  mov	edx,esi		;save text ptr
  jmp	pc_30
pc_got_a:
  inc	bl
  cmp	bl,2
  je	pc_exit
pc_30:
  add	esi,ecx
  cmp	esi,[editbuf_ptr]
  je	pc_exit
  cmp	esi,[file_end_ptr]
  je	pc_exit
  jmp	pc_lp
pc_stop:
  mov	edx,esi
pc_exit:
  ret

; (#q#) quit menu     ***********************************
;
; options are: Abort,Exit,Init,Update,Write,Esc
;
quit_menu:
  call	clear_status_line
  mov	esi,msg_quit		;prompt message
  mov	edi,char_out		;single character buffer
  mov	byte [edi],0		;clear buffer
  mov	eax,1			;read one char
  call	get_string
  mov	al,byte [char_out]
  cmp	al,"i"
  je	qm_init
  jmp	qm_2
;
; save current file and open new file "i"
;
qm_init:
  call	init_newfile
  jmp	qm_continue
qm_2:
  cmp	al,'w'
  jne	qm_4
;
; select a new name for active file "w"
;
sef_02: 	;---------  entry to write file with new name ------
  mov	esi,file1_entry_msg
  test	byte [active_window],1
  jz	sef_03
  mov	esi,file2_entry_msg
;--- entry point to save unnamed files, esi = prompt msg ptr --------
sef_03:
;clear file_path
  push	esi
  mov	edi,file_path
  xor	eax,eax
  mov	ecx,80
  cld
  rep	stosb
  pop	esi

  mov	eax,30			;max string length
  mov	edi,file_path
  mov	byte [str_terminator],0 ;allow either "esc" or "return" to end
  call	get_string
  or	ecx,ecx
  jnz	qm_exit			;jmp if no name entered
  call	expand_filename
  call	check_file		;check if existing file may be overwritten
  jc	qm_exit			;exit if user wants to abort  
  mov	byte [file_change],CHANGED ;force save under new name
  call	sef_20			;go write file
  jmp	qm_continue
qm_4:
  cmp	al,'u'
  jne	qm_5
;
; write current active file to disk "u"
;
  mov	byte [file_change],CHANGED	;force save of zero len files
  call	save_edit_file
  jmp	short qm_continue
qm_5:
  cmp	al,"a"
  jne	qm_6
  inc	byte [exit_program_flg]
  jmp	short qm_abort	;jmp if "abort"
qm_6:
  cmp	al,'e'		;check if save-and-exit
  jne	qm_exit
;
; save current file and exit "e"
;
qm_8:
  call	save_and_exit
  jmp	qm_exit
qm_abort:
  inc	byte [exit_program_flg]	;set flag to abort program
  jmp	short	qm_exit
qm_continue:
   mov byte [file_change],UNCHANGED	;set changed flag to " "
qm_exit:
  ret

;---------------------------------------------------
; save files and exit
;
save_and_exit:
  call	save_edit_file
  call	other			;switch to other window
  mov	edx,01000000h		;select bold text for active screen
  call	display_screen
  call	save_edit_file
  call	other			;restore active file for history save
  inc	byte [exit_program_flg]
  ret
;------------------------------------------------------

init_newfile:  
  mov	eax,[file_end_ptr]
  cmp	eax,[editbuf_ptr]	;check for empty file
  je	qm_1a			;jmp if file unchanged
  cmp	byte [file_change],CHANGED
  jne	qm_1a			;jmp if no data in current file
  mov	edi,file_path		;buffer to enter name
  cmp	byte [edi],0		;check if filename exists
  jnz	qm_1			;jmp if name exists
  mov	esi,filew_entry_msg
  mov	eax,30			;max string length
  mov	byte [str_terminator],0 ;allow either "esc" or "return" to end
  call	get_string
  or	ecx,ecx
  jnz	qm_1a			;jmp if no name entered
  call	expand_filename
  call	check_file		;are we overwriting an existing file?
  jc	init_newfile		;if yes and user aborts, try again
qm_1:
  call	save_edit_file		;save current file
qm_1a:
  mov	ecx,file_path
  call	exec_browser
  jnc	qm_1b			;jmp if filename from "dir" program
  mov	edi,file_path		;buffer to enter name
  mov	byte [edi],0		;zero out any existing filename
  mov	esi,filex_entry_msg
  mov	eax,30			;max string length
  mov	byte [str_terminator],0 ;allow either "esc" or "return" to end
  call	get_string
;
; read/setup for new file
;
qm_1b:
  mov	edx,_init
  call	read_edit_file
  ret
;--------------
  [section .data]
browser_name db	'|/usr/bin/file_browse',0
browser_out  db	'/tmp/tmp.dir',0
  [section .text]
;
; input:	ecx = filename store buf
; output:  carry = error
;          no-carry = success
exec_browser:
  push	ecx
  mov	esi,browser_name
  call	sys_ex
  pop	ebx		;get buffer for storing path from file_browse
  or	al,al
  jz	eb_cont		;jmp if no error
  stc
  jmp	short eb_exit	;exit if launch failed
eb_cont:
  mov	eax,browser_out	;get file name
  mov	dl,0ah		;simple file 
  call	file_read
  clc
eb_exit:
  ret
  
;--------------
; verify entered name will not overwrite an existing file
;  input: file_path has name of new file
; output: carry set if user wants to skip write
;
check_file:
  pusha
  mov	byte [result_flag],0	;preload file name ok state
  mov	ebx,file_path
  xor	edx,edx
  xor	ecx,ecx
  mov	eax,5			;open code
  int	byte 80h			;open read only
  push	eax
  or	eax,eax
  js	cf_expected_err
;
; whoops we may have an existing file, ask
;
  mov	eax,[status_color2]	;get color (change to status_color)
  mov	bh,[status_line_row]
  mov	bl,1			;column 1
  mov	ecx,overwrite_file_msg  ;get msg address
  call	display_color_at	;display message
  call	read_keys
  cmp	byte [kbuf],'y'
  je	cf_expected_err
  mov	byte [result_flag],1    
cf_expected_err:
  pop	ebx
  js	cf_skip_close		;kludge, redesign someday
  mov	eax,6			;close file code
  int	byte 80h
  call	error_check
cf_skip_close:
  popa
  cmp	byte [result_flag],1
  jne	cf_exit2
  stc
  jmp	cf_exit3
cf_exit2:
  clc
cf_exit3:
  ret
;-----------------------------------
; expand file name if incomplete
;  inputs: [file_path] has name
; output:  file_path has full path to local file
;
expand_filename:
  cmp	byte [file_path],'/'	;check if file already expanded
  je	ef_exit			;exit if no expansion needed
  mov	dword [fname_ptr],file_path
  call	build_current_path	;input = fname_ptr, output=path_buf
  mov	esi,path_buf
  mov	edi,file_path
  call	move_asciiz
ef_exit:
  ret  

; (#r#) replace text  ***********************************

find_and_replace:
  mov	byte [replace_all_flag],0
far_again:
  call find_forward		;point edi at string, length=find_str_len
  jc	far_exita		;jmp if no string entered
far_0:
  mov	[replace_ptr],edi	;save new file ptr
  mov	eax,[find_str_len]
  mov	esi,replace_msg		;get message "replace with"
  mov	edi,replacetext		;buffer for string
; compute max string length
  xor	eax,eax
  mov	al,[term_columns]
  sub	al,12

  mov	byte [str_terminator],1bh ;set "esc" as terminator for string
  call	get_string
  mov	[replace_str_len],eax
  cmp	cl,1
  jbe	far_1			;jmp if not ctrl-c
far_exita:
  jmp  far_exit2		;exit
far_1:
  mov	edx,01000000h		;select bold text for active screen
  call	display_screen

  cmp	byte [replace_all_flag],0
  jne	do_replace		;jmp if replace "all" active

  mov	eax,[status_color1]	;get color (change to status_color)
  mov	bh,[status_line_row]
  mov	bl,1			;column 1
  mov	ecx,replace_again_prompt;get msg address
  call	display_color_at	;display message

  mov	eax,[crt_cursor]	
  call	move_cursor
  call	read_keys
  mov	al,[kbuf]		;get char.
  cmp	al,'y'
  je	do_replace
  cmp	al,'s'
  je    skip_replace
  cmp	al,'a'
  jne	far_exit		;exit if unknown key press

replace_all:
  mov	byte [replace_all_flag],1
  jmp	do_replace

skip_replace:
  jmp	far_againj  	

do_replace:
  mov	edi,[replace_ptr]		;restore old buffer ptr
  mov eax,[find_str_len]	;get number of bytes to delete
  call DeleteByte
  jc	far_exit		;jmp if error
  mov	eax,[replace_str_len]	;replace string
  call make_hole		;edi = location to open
;  eax=lenght of string, esi=from  edi=to
  mov esi,replacetext
  call MoveBlock		;eax=length, esi=from, edi=to
far_againj:
  mov	edi,[replace_ptr]
  add	edi,[replace_str_len]
  call	find_again2
  jc	far_exit1		;exit if not found
  mov	[replace_ptr],edi
  call	compute_line
  mov	[cursor_linenr],edx
  jmp	far_1

far_exit1:
  mov	dword [special_status_msg_ptr],0	;disable "not found" msg
far_exit:
  call	key_left		;kludge so "again" key works
far_exit2:
  mov	al,~1
  and	byte [last_cmd],al	;disable find repeat
  ret

; (#s#) key commands  ***********************************

;setup_key:			;see m9mode:
;  call	update_config
;  ret

; (#t#) tag set       ***********************************

set_tag:
  mov	eax,1		;string length
  mov	esi,tag_msg
  mov	edi,char_out	;temp string buffer
  mov	byte [edi],0	;clear buffer of strings
  call	get_string
  jecxz	st_0		;jmp if string entered
  jmp	st_5		;jmp abort
st_0:
  mov	edi,[cursor_linenr]
  mov	al,byte [char_out]	;get tag character
  cmp	al,'a'
  jne	st_1
  mov	[tag_a],edi
  jmp	st_5
st_1:	cmp	al,'b'
  jne	st_2
  mov	[tag_b],edi
  jmp	st_5
st_2:	cmp	al,'c'
  jne	st_3
  mov	[tag_c],edi
  jmp	st_5
st_3:	cmp	al,'d'
  jne	st_5
  mov	[tag_d],edi
st_5:
  ret	

; (#u#) unused        ***********************************
; (#v#) unused        ***********************************

; (#w#) window toggle ***********************************

window:
;
; compute new window mode
;
  mov	eax,[active_window]
  test	al,6
  jz	w_10			;jmp if single > horizontal
  test	al,2
  jnz	w_20			;jmp if horizontal > vertical
;
; going from vertical to single
;
  xor	al,4			;adjust mode
  mov	byte [active_window],al	;set new mode
  mov	ebx,term_statusln	;new dimensions for old window
  mov	ebp,term_statusln	;get new window dimensions
  call	switch_windows
  jmp	win_exit

;
; going from single to horizontal
;
w_10:
  or	al,2			;adjust mode
  mov	byte [active_window],al	;set new mode
  mov	ebx,hor_a_status	;new dimensins for old window
  mov	ebp,hor_b_status	;get new window dimensions
  call	switch_windows
  jmp	win_exit
;
; going from horizontal to vertical
;
w_20:
  xor	al,6			;adjust mode
  mov	byte [active_window],al	;set new mode
  mov	ebx,ver_a_status	;new dimensions for old window
  mov	ebp,ver_b_status	;get new window dimensions
  call	switch_windows
  call	vertical_bar		;separate windows

win_exit:
  call	other
  call	other
  ret
	
; (#x#) eXchange/overtype *******************************

xchange_mode:
  mov	dword [key_mode],1		;set cmd/edit mode
  mov	dword [insert_overtype],0	;set insert/overtype mode
  call	clear_block			;clear block operations
  ret

; (#y#) unused key    ***********************************
; (#z#) unused key    ***********************************


;       #- - AEDIT find backwards **********************


find_back:
  mov	dword [scan_direction],-1	;set direction flag - forward
  call	find_string
  ret


; (#^a#) delete right  ***********************************
  
delete_right:
  mov	edi,[editbuf_cursor_ptr]
dr_10:
  cmp	byte [edi],0ah
  je	dr_done
  mov	eax,1		;delete one byte
  call	DeleteByte
  jc	dr_done		;jmp if error
  jmp	dr_10
dr_done:
  ret  

; (#^r#) hex input     ***********************************

hex_input:
  mov	esi,hex_msg		;prompt message
  mov	edi,optbuffer		;buffer for hex chars
  mov	byte [edi],0		;clear buffer
  mov	eax,2			;eax length of input
  mov	byte [str_terminator],0 ;allow both "esc" and "rtn" as terminators
  call	get_string
  jecxz hi_10			;jmp if data ok
  jmp	hi_exit			;exit if user aborted
hi_10:
  cmp	al,2
  jne	hi_exit			;exit if missing data
  mov	esi,optbuffer
  call	hex_to_byte		;returns char in -al-
  mov	byte [kbuf],al		;save new char for NormChar
  call	NormChar
hi_exit:  
  ret

; (#^u#) restore deleteted line *************************

restore_line:
  mov	edi,[editbuf_cursor_line_ptr]
  mov	ebx,edi			;save line begin
  mov	eax,[buffered_line_len]
  call	make_hole

  mov	edi,ebx
  mov	eax,[buffered_line_len]
  mov	esi,buffercopy		;saved line location
  call	MoveBlock
  call	KeyHome
  ret  

; (#^x#) delete left   ***********************************

delete_left:
  mov	edi,[editbuf_cursor_ptr]
dl_10:
  cmp	byte [edi-1],0ah
  je	dl_done
  call	key_left
  mov	eax,1		;delete one byte
  call	DeleteByte
  jc	dl_done		;jmp if error
  jmp	dl_10
dl_done:
  ret  

; (#^z#) delete line   ***********************************

;
; cut line and place in buffercopy, length of line = buffered_line_len
;   max size of buffercopy is buffercopysize
;
delete_line:
  call	clear_block
  mov	edi,[editbuf_cursor_line_ptr]
  cmp	edi,[file_end_ptr]
  je	dl_exit			;exit if at end of file
  mov	ebx,edi			;save line begin
  call	next_line
dll_10:
  cmp	edi,[file_end_ptr]	;check if at end of file now
  jbe	dll_20			;jmp if not at end of file
  dec	edi
  jmp	short dll_10
dll_20:
  sub	edi,ebx			;compute line length
  mov	[buffered_line_len],edi	;save line length

  mov	eax,edi			;line length to eax
  cmp	eax,buffercopysize	;check if line fits in buffer
  ja	dl_exit			;exit if line too big
  mov	esi,ebx			;line begin to esi
  mov	edi,buffercopy		;destination to edi
  call	MoveBlock
dl_cut:  
  mov	edi,ebx			;get start of line
  mov	eax,[buffered_line_len]
  call	DeleteByte		;remove line
  call	KeyHome
dl_exit:
  ret


; (#f1#) help          ***********************************
;
; Online Help: show the message followed by common text
;

KeyHelp:
  call	other
  call	other
  mov	esi,help_name		;help prog namd + error #
  call	sys_ex
  jmp	common_tail

help_name:  db	'|/usr/bin/asmref',0

; (# #) main menu     ***********************************
;        <space>, "<"

m1mode:
  cmp	byte [mouse_mode],1
  je	m1_toggle
  mov	byte [mouse_mode],1
  jmp	m1_exit
m1_toggle:
  mov	byte [mouse_mode],9
m1_exit:
  ret

; (#f2#) main menu     ***********************************
;        <f2>
f2_todo:
  call	other
  call	other
  mov	esi,todo_name
  call	sys_ex
  jmp	common_tail

todo_name:  db  '|/usr/bin/asmplan',0

; (#f3#) compile       ***********************************

; launches a.f3 from either: local dir, $HOME/.asmide/edit, or executable path
; Picks up results of a.f3 from $HOME/.asmide/edit/temp.2
;

f_make:
  test  byte [active_window],1
  jz	f_make10		;jmp if file1 active
;
; display error if user trying to compile file2
;
  mov	eax,[status_color2]	;get color (change to status_color)
  mov	bh,[status_line_row]
  mov	bl,1			;column 1
  mov	ecx,shell_err1		;get msg address
  call	display_color_at	;display message
  call	read_keys
f_make10:
  cmp	byte [file2_path],0
  je	f_make20		;jmp if file2 avail.
;  cmp	dword [file2_path],'f3.o'
;  je	f_make20		;jmp if file2 has old error file
  cmp	byte [file2_change],20h
  je	f_make20		;jmp if file2 unchanged
;
; file2 is not avialable to hold compile status report.  abort.
;
  mov	eax,[status_color2]	;get color (change to status_color)
  mov	bh,[status_line_row]
  mov	bl,1			;column 1
  mov	ecx,shell_err2		;get msg address
  call	display_color_at	;display message
  call	read_keys
  cmp	byte [kbuf],'y'
  je	f_make20
  jmp	short f3_exit
;
make_filename	db	'|/usr/share/asmedit/a.f3',0

f_make20:
  mov	byte [file_change],CHANGED	;force save of zero len files
  call	save_edit_file

  mov	esi,make_filename
  call	sys_ex
  cmp	al,11h
  je	f3_exit			;exit if launch failed

;setup file2
;
  mov	byte [file2_location],2  ;set flag saying file2 in temp file
  mov	byte [file2_change],20h
    
  mov	byte [active_window],5	;get new mode
  mov	ebx,ver_a_status	;new dimensions for old window
  mov	ebp,ver_b_status	;get new window dimensions
  call	switch_windows
  call	vertical_bar		;separate windows
  call	other
f3_exit:
  mov	byte [key_mode],0	;set command mode
  ret
  
; (#f4#) debugger ***********************************
bug_name  db	'|/usr/share/asmedit/a.f4|',0

f_bug:
  mov	edi,bakpath
  mov	esi,bug_name
  call	move_asciiz
  mov	esi,file_path
f_buf_10:
  call	move_asciiz
;
; strip off any .xxx at end of source file name
;
  mov	ecx,4			;loop count
f_buf_12:
  dec	edi
  cmp	byte [edi],'.'
  je	f_buf_20		;go truncate filename
  loop	f_buf_12
  jmp	f_buf_22
f_buf_20:
  mov	byte [edi],0		;trunate name
f_buf_22:
  mov	esi,bakpath
  call	sys_ex

  cmp	byte [active_window],0
  je	f_buf_exit
  call	window
f_buf_exit:
  ret

; (#f5#) key commands  ***********************************
; (#f6#) key commands  ***********************************
; (#f7#) key commands  ***********************************
; (#f8#) key commands  ***********************************
; (#f9#) key commands  ***********************************
; (#f10#) key commands  ***********************************
; (#f11#) key commands  ***********************************
; (#f12#) key commands  ***********************************

key_f5:
  mov	byte [file_change],'*'	;assume spell checker changed file
  mov	eax,'a.f5'
  jmp	short f_common
key_f6:
  mov	byte [file_change],'*'	;assume compare program changed file
  mov	eax,'a.f6'
  jmp	short f_common
key_f7:
  mov	eax,'a.f7'
  jmp	short f_common
key_f8:
  mov	eax,'a.f8'
  jmp	short f_common
key_f9:
  mov	eax,'a.f9'
  jmp	short f_common
key_fa:
  cmp	byte [confirm_flag],1
  je	key_fa2			;jmp if confirm enabled
  jmp	qm_8			;go to "qe" logic
key_fa2:
  call	confirm
  inc	byte [exit_program_flg]
  ret

key_fb:
  mov	eax,'a.fb'
  jmp	short f_common
key_fc:
  mov	eax,'a.fc'
f_common:
  push	eax			;save script name
  call	other			;create tmp.1
  call	other			;create tmp.2
  pop	eax			;restore the script name

  mov	[f_name],eax
  mov	edi,bakpath
  mov	esi,usr_base
  call	move_asciiz
  mov	esi,f_name
  call	move_asciiz
  mov	al,'|'
  stosb
  mov	esi,file1_tmp_name
  call	move_asciiz
  mov	al,'|'
  stosb
  mov	esi,file2_tmp_name
  call	move_asciiz
  mov	esi,bakpath
  call	sys_ex

  mov	eax,file_tmp_name
  mov	ebx,[editbuf_ptr]
  mov	dl,22h			;file editbuf with $HOME/base file
  call	file_read
  add	eax,[editbuf_ptr]	;compute file_end_ptr
 
  mov	[file_end_ptr],eax
  mov	byte [file_location],1	;set in memory state for file
  mov	byte [eax],0ah		;put 0ah at end of file
common_tail:
  call	other
  call	other
  cmp	byte [active_window],4
  jb	kh_20			;jmp if not vertical window mode
  call	vertical_bar
kh_20:
  ret

usr_base	db	'|/usr/share/asmedit/',0

; (#cursor#) key commands  ***********************************

key_down:
  mov	edi,[editbuf_cursor_ptr]	;scan
  cmp	edi,[file_end_ptr]
  jae	kd_exit			;jmp if at end of file
  call	next_line
  cmp	edi,[file_end_ptr]
  jb	kd_05			;jmp if not at end of file
;
; we are at end of file, check for special case, last line ends with 0ah
;
  mov	edi,[file_end_ptr]	;force end point, it may have strayed 
  cmp	byte [edi -1],0ah
  jne	kd_exit			;jmp if last line without 0ah at end  
kd_05:
  mov	bl,[crt_cursor]
  call	check_cursor_column
  mov	esi,edi
  call	compute_cursor_data
kd_exit:
  ret
;--------------------------  

key_up:
  cmp	dword [cursor_linenr],1
  je	ku_exit			;exit if at to line
  mov	edi,[editbuf_cursor_ptr]
  call	end_prev_line
  call	end_prev_line
  inc	edi			;move to start of line above current
  mov	bl,[crt_cursor]
  call	check_cursor_column
  mov	esi,edi			;setup to call compute_cursor_data

  mov	edi,[crt_top_ptr]	;at top of screen
  cmp	edi,[editbuf_cursor_line_ptr] ;check if at top of screen
  jne	ku_50			;jmp if not at top of scren
  call	end_prev_line
  call	end_prev_line
  inc	edi
  mov	[crt_top_ptr],edi

ku_50:
  call	compute_cursor_data
ku_exit:
  ret
;---------------------
key_right:
  mov	esi,[editbuf_cursor_ptr]
  cmp	esi,[file_end_ptr]
  je	kr_90			;exit if at eof
  inc	esi
  call	compute_cursor_data
kr_90:
  ret
;----------------

key_left:
  mov	esi,[editbuf_cursor_ptr]
  cmp	esi,[editbuf_ptr]
  je	kl_exitx
  dec	esi
  call	compute_cursor_data
kl_exitx:
  ret
;--------------------------------
; page down one screen
;
KeyPgDn:
  mov	edi,[crt_top_ptr]
  call	compute_line
  mov	[crt_top_linenr],edx
  mov	eax,edx
  xor	ebx,ebx
  mov	bl,[win_rows]
  add	eax,ebx			;compute target top line number
  mov	[target_top_linenr],eax

  mov	eax,[cursor_linenr]
  add	eax,ebx
  mov	[target_cursor_linenr],eax
;
; compute expected values for next display page
;
  mov	esi,[crt_top_ptr]
  mov	ecx,[crt_top_linenr]
;
; scan buffer to verify display top pointer
;
kpd_30:
  cmp	esi,[file_end_ptr]
  je	kpd_95
  lodsb
  cmp	al,0ah
  jne	kpd_30			;loop till end of page

  inc	ecx			;bump page number
  cmp	ecx,[target_top_linenr]
  jne	kpd_30			;loop if not at new top yet
  cmp	esi,[file_end_ptr]
  jae	kpd_95			;?
  mov	[crt_top_linenr],ecx	;save new top linenr
  mov	[crt_top_ptr],esi	;save new top data pointer
;
; scan buffer to verify new cursor pointer is ok
;
  mov	bl,1			;get starting row#
kpd_33:
  cmp	ecx,[target_cursor_linenr]
  je	kpd_36			;jmp if target line# has been reached
kpd_34:
  cmp	esi,[file_end_ptr]
  je	kpd_36			;jmp if cursor needs truncating
  lodsb
  cmp	al,0ah
  jne	kpd_34			;loop till end of line
  inc	bl			;bump row number for display
  inc	ecx			;bump cursor line number
  jmp	kpd_33

;
; we have found new cursor linenr and start of new cursor line (esi)
;
kpd_36:
  mov	[crt_cursor+1],bl	;save new cursor row
  mov	[cursor_linenr],ecx	;save new cursor linenr
  mov	edi,esi
  mov	bl,[crt_cursor]
  call	check_cursor_column
kpd_90:
  mov	esi,[editbuf_cursor_ptr]
kpd_95:
  call	compute_cursor_data
  ret

;----------------------------------------------------------------------
;
KeyPgUp:
  mov	edi,[crt_top_ptr]
  call	compute_line
  mov	[crt_top_linenr],edx
  mov	ecx,edx
  call	look_page_up
;
; compute start of line for new cursor position
;  edi=page top ptr  ecx=page top linenr
;
  mov	eax,[crt_top_linenr]
  mov	[crt_top_linenr],ecx	;set new top linenr
  mov	[crt_top_ptr],edi	;set new top ptr
;
; compute cursor linenr
;
  mov	edx,[cursor_linenr]
  sub	edx,eax			;(old cursor linenr)-(old top linenr)
  add	ecx,edx			;(new top linenr) + above
  mov	[cursor_linenr],ecx

  mov	ecx,edx			;get index into window for cursor
kpu_10:
  jecxz	kpu_12			;jmp if done
  call	next_line		;scan forward to cusrsor line
  dec	ecx
  jmp	kpu_10
;
; edi points at cursor line, find cursor column
;
kpu_12:
  mov	bl,[crt_cursor]
  call	check_cursor_column
  mov	esi,[editbuf_cursor_ptr]
  call	compute_cursor_data
  ret

;----------------
KeyHome:
  mov	esi,[editbuf_cursor_line_ptr]
  call	compute_cursor_data
  ret
;---------------  
KeyEnd:
  mov	edi,[editbuf_cursor_ptr]
  call	next_line
  dec	edi
  mov	esi,edi
  call	compute_cursor_data
  ret

;----------------------------------------------------------------------
; toggle insert/exchange mode

KeyIns:
  xor byte [insert_overtype],1		;toggle insert/overtype mode
  mov	byte [mouse_mode],6
  ret

; backspace key

KeyDell:
  call key_left
  je	kd_exitx			;jmp if at top of screen
  cmp	byte [insert_overtype],0	;check if insert mode
  jne	kd_insert_mode			;jmp if insert mode
  mov	edi,[editbuf_cursor_ptr]
  mov	byte [edi],' '
  jmp	kd_exit
kd_insert_mode:
  call	KeyDel				;jmp if at top of screen
kd_exitx:
  ret
  
; delete key

KeyDel:
  mov	edi,[editbuf_cursor_ptr]
  cmp edi,[file_end_ptr]
  jnb kd_end
  xor eax,eax
  inc eax
  call	DeleteByte
kd_end:
  ret

; (#3#) keyboard processing ******************************
  
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; input: esi = prompt message
;        edi = string buffer
;        status_color1 = color for input data
;        eax = max string length (single char strings return after char typed)
;        str_terminator (byte) = <esc> or <return> or 0 for either
; output: ecx = 0-got it  1-zero length 2-abort
;         eax = string length
;         str_begin = pointer to string text (part of prompt line)
; data: str_begin, str_ptr, str_max, str_cursor
;
get_string:
  cld
  mov	dword [str_max_count],eax
  mov	byte [get_string_flg],0	;set entered flag
  mov	[str_ptr],edi
  mov	[str_begin],edi		;save pointer to string buffer

  sub	ecx,ecx
  mov	cl,[term_columns]
  add	ecx,lib_buf		;compute length of prompt line
  mov	edi,lib_buf
gs_l:
  movsb				;move message to buffer
  cmp	byte [esi],0
  jne	gs_l
;
; move current contents of buffer to display
;
  mov	esi,[str_ptr]
gs_2:
  cmp	byte [esi],0
  je	gs_3
  lodsb
  cmp	al,20h
  jae	gs_2a		;jmp if not control char
  mov	al,'.'		;substitute '.' for control characters
gs_2a:
  stosb			;exit if string moved
  jmp	gs_2
gs_3:
  mov	[str_ptr],esi		;point at end of string

  mov	eax,[str_max_count]	;restore max string length  
  add	eax,[str_begin]
  mov	[str_max],eax		;sav max str ptr

  mov	eax,edi
  sub	eax,lib_buf		;compute cursor
  mov	ah,[status_line_row]
  add	al,1			;compute cursor location for entry
  mov	dword [str_cursor],eax	;store cursor for beginning of string

  mov	al,' '
gs_4:
  stosb				;clear end of prompt line
  cmp	edi,ecx
  jb	gs_4

  mov	byte [edi],0		;put zero at end  
  mov	dword [edi-8],'ESC='
  mov	dword [edi-4],'done'
    
  mov	eax,[status_color1]	;get color (change to status_color)
  mov	bh,[status_line_row]
  mov	bl,1			;column 1
  mov	ecx,lib_buf 		;get msg address
  call	display_color_at	;display message

gs_lpp:
  mov	eax,[str_cursor]
  call	move_cursor		;move cursor (ah=row al=column)
  call	read_keys		;fill kbuf
  cmp	byte [kbuf],-1
  jne	got_key			;jmp if keyboard action
; ignore mouse buttons
  jmp	gs_lpp
gs_ignorej:
  jmp	gs_ignore
got_key:
  mov	esi,kbuf
  mov	al,byte [esi]
  mov	ah,byte [str_terminator]	;
  cmp	al,ah			;check if terminator character
  je	gs_05			;jmp if end of input
  cmp	ah,0			;check if both "esc" and "rtn" terminators
  jne	gs_10			;jmp if single terminator in str_terminator
  cmp	al,1bh			;check for escape
  je	gs_05			;jmp if escape
  cmp	al,0dh
  jne	gs_10			;jmp if not end of data
gs_05:
  cmp	byte [esi+1],0
  jne	gs_ignore1		;jmp if not escape
  jmp	gs_done
gs_10:
  cmp	al,0dh
  jne	gs_12			;jmp if not <enter>
  mov	al,0ah			;substutite 0a for 0d
  jmp	gs_16			;jmp if <enter>
gs_12:
  cmp	al,08h			;check for rubout
  je	gs_rubout
  cmp	al,7fh			;check for rubout
  jne	gs_14			;jmp if not rubout
; process rubout here
gs_rubout:
  mov	byte [get_string_flg],1	;disable clearing of edit data
  mov	edi,[str_ptr]
  cmp	edi,[str_begin]
  je	gs_lpp			;ignore rubout if at start of string
  dec	edi
  mov	byte [edi],20h		;rubout character
  mov	dword [str_ptr],edi
  dec	dword [str_cursor]
  mov	cl,20h			;get char to display
  mov	eax,[status_color1]	;get display color
  mov	ebx,[str_cursor]	;get display location  
  call	display_char_at
gs_ignore1:
  jmp	gs_lpp			;try again
gs_abort:
  mov	ecx,2
  jmp	gs_end
gs_14:
  cmp	al,03h			;check for ctrl-c
  je	gs_abort		;jmp if abort
  cmp	al,12h			;check for ctrl-r (hex)
  jne	gs_15			;jmp if not ctrl-r
  call	gs_get_hex		;get hex char -> al
  jmp	short gs_16
gs_15:
  cmp	al,09h			;check for tab
  je	gs_16			;jmp if tab
gs_15a:
  cmp	al,20h
  jb	gs_ignorej		;jmp if non-alpha
  cmp	al,7eh
  ja	gs_ignore		;jmp if non-alpha
gs_16:
  mov	edi,[str_ptr]
  cmp	edi,[str_max]		;check if room
  jae	gs_ignore		;ignore char if out of room
  mov	byte [edi],al		;store char
; display string
  cmp	al,20h			;substitute "." for some characters
  jae	gs_17
  mov	al,'.'
gs_17:
  mov	cl,al			;get char to display
  cmp	byte [get_string_flg],0
  jne	gs_18			;jmp if not initial entry
;
; this is the initial pass through, clear existing entries if char. typed
;
  mov	eax,[str_ptr]
  mov	bl,[eax]		;get buffered char
  sub	eax,[str_begin]
  jz	gs_18			;jmp if not initial entries
  push	eax
  mov	eax,[str_begin]		;reset pointer
  mov	[eax],bl		;stuff new char at front of buffer
  mov	dword [eax+1],0		;clear end of buffer
  mov	[str_ptr],eax 
  pop	eax
  sub	[str_cursor],al		;adjust cursor
  call	blank_field
gs_18:  
  inc	byte [get_string_flg]	;disable this logic till next entry 
  mov	eax,[status_color1]	;get display color
  mov	ebx,[str_cursor]	;get display location  
  call	display_char_at
  mov	eax,[str_ptr]
  cmp	eax,[str_max]
  je	gs_ignore		;skip update if at end of entry area
  inc	dword [str_ptr]
  inc	dword [str_cursor]
gs_ignore:
  cmp	dword [str_max_count],1
  je	gs_done1		;exit if single char. entry
  jmp	gs_lpp
gs_done1:
gs_done:
  sub	ecx,ecx
  mov	eax,[str_ptr]
  mov	byte [eax],0		;terminate string
  sub	eax,[str_begin]
  jnz	gs_end
  mov	cl,1			;allow zero length stings for replace cmd
gs_end:
  ret 
;----------------------
blanks_msg	db	'                       ',0
blank_field:
  pusha
  mov	eax,[status_color1]	;get color (change to status_color)
  mov	ebx,[str_cursor]
  mov	ecx,blanks_msg		;get msg address
  call	display_color_at	;display message
  popa
  ret   
;----------------------
; get hex char inside string input
;  input: none
;  output: al = char
;
gs_get_hex:
  pusha
  call	read_keys
  mov	al,[kbuf]
  mov	[optbuffer],al
  call	read_keys
  mov	al,[kbuf]
  mov	[optbuffer+1],al
  mov	esi,optbuffer
  call	hex_to_byte
  mov	[kbuf],al	;save result  
  popa
  mov	al,[kbuf]
  ret

;--------------------------------------------------------------
; read keys and mouse data, and feeds macro/repeat data back
;  inputs: macro_flag 0=idle 1=record 2=playback
;          macro_ptr set externally and bumped internally.
; output:  kbuf had key sequences terminated by a zero
;               a byte of -1 signals mouse data (button, col, row)
;
read_keys:
  cld
;
; check if macro active
;
rk_20:
  cmp	byte [macro_flag],2	;check if playback active
  jne	rk_30			;jmp if macro playback inactive
  call	macro_playback		;go feed macro data
  cmp	byte [macro_flag],0
  je	rk_30			;jmp if macro done
  jmp	rk_exit
;
; normal key read
;
rk_30:
  call	poll_keyboard		;read keys to kbuf  
  call	mouse_check		;check if mouse data read
  call	save_macro_data
rk_exit:
  ret
;------------------------------------------------------
; macro playback
;  input: macro_flag - 0=idle 1=play 2=macro continue
;         macro_forever_flg 2=forever
;         macro_ptr = pointer to macro_buffer
;  output: set macro_flag = 0 if done and not "forever"
;
macro_playback:
  mov	esi,[macro_ptr]
  cmp	byte [esi],0		;check if this macro done
  jne	mp_30			;jmp if macro sequence active
;
; end of macro, are we in forever loop?
;
  test	byte [macro_forever_flg],2	;check if forever flag set
  jz	mp_50			;jmp if not forever macro
;
; check if "forever" is at end of data
;
  mov	ebx,[editbuf_cursor_ptr]
  inc	ebx
  cmp	ebx,[file_end_ptr]	;are we at end of file
  jae	mp_50			;jmp if at end of file

  sub	ebx,byte 2
  cmp	ebx,[do_again_ck]
  ja	mp_10			;jmp if cursor has moved
  mov	ebx,[do_again_ck2]
  cmp	ebx,[file_end_ptr]
  je	mp_50			;jmp if file end unchanged
;setup to do macro again
mp_10:
  mov	ebx,[file_end_ptr]
  mov	[do_again_ck2],ebx	;save file end
  mov	ebx,[editbuf_cursor_ptr]
  mov	[do_again_ck],ebx	;save cursor location
  mov	esi,macro_buffer	;setup to do it again

mp_20:
  cmp	byte [last_find_status],0 ;did last find succeed?
  je	mp_50			;exit if not found.
;
; store macro data in kbuf
;
mp_30:
  mov	edi,kbuf
mp_32:
  lodsb
  stosb
  or	al,al
  jnz	mp_32			;loop till macro data moved
  mov	[macro_ptr],esi
  jmp	mp_exit
;macro done, clear flags and pointers
mp_50:
  mov	byte [macro_flag],0	;clear macro flag
  mov	dword [macro_ptr],macro_buffer
  mov	byte [macro_forever_flg],0	;disable find again
mp_exit:
  ret
;---------------------------------------------
; read keys to kbuf
;  input: 
;  output: kbuf has keys
;
poll_keyboard:
  mov	ecx,kbuf
read_more:
  mov	edx,36			;read 20 keys
  mov	eax,3				;sys_read
  mov	ebx,0				;stdin
  int	byte 0x80
  or	eax,eax
  js	rm_exit
  add	ecx,eax
  mov	byte [ecx],0		;terminate char

  push	ecx
  mov	eax,162			;nano sleep
  mov	ebx,delay_struc
  xor	ecx,ecx
  int	byte 80h

  mov	word [poll_rtn],0
  mov	eax,168			;poll
  mov	ebx,poll_tbl
  mov	ecx,1			;one structure at poll_tbl
  mov	edx,20			;wait xx ms
  int	byte 80h
  test	byte [poll_rtn],01h
  pop	ecx
  jnz	read_more
;strip any extra data from end
  mov	esi,kbuf
  cmp	byte [esi],1bh
  je	mb_loop
  inc	esi
  jmp	short rm_20
;check for end of escape char
mb_loop:
  inc	esi
  cmp	esi,ecx
  je	rm_20			;jmp if end of char
  cmp	byte [esi],1bh
  jne	mb_loop			;loop till end of escape sequence
rm_20:
  mov	byte [esi],0		;terminate string
rm_exit:
  ret


  [section .data]
delay_struc:
  dd	0	;seconds
  dd	8	;nanoeconds
  [section .text]

  
;-----------------------
; format mouse data
;   input: kbuf has mouse escape sequenes
;          1b,5b,4d,xx,yy,zz
;            xx - 20=left but  21=middle 22=right 23=release
;            yy - column+20h
;            zz - row + 20h
;  output: kbuf = ff,button,column,row  
;
mouse_check:
;  mov	byte [ecx],0			;put zero at end of string
  cmp	word [kbuf],5b1bh		;check if possible mouse
  jne	mc_exit				;jmp if not mouse
  cmp	byte [kbuf+2],4dh
  jne	mc_exit			;jmp if not mouse
; read release key
  mov	eax,3				;sys_read
  mov	ebx,0				;stdin
  mov	ecx,kbuf+6
  mov	edx,20				;buffer size
  int	0x80				;read key
; format data
  mov	edi,kbuf
  mov	byte [edi],-1
  inc	edi			;signal mouse data follows
  mov	al,[kbuf+3]
  and	al,3
  stosb 			;store button 0=left 1=mid 2=right
  mov	al,[kbuf+4]
  sub	al,20h
  stosb				;store column 1+
  mov	al,[kbuf+5]
  sub	al,20h
  stosb				;store row
mc_exit:
  ret 
;---------------------------------------------
; are we in macro record mode?
;
save_macro_data:
  cmp	byte [macro_flag],1
  jne	smd_exit			;exit if no macro record
;
; we are in macro record mode
;
  mov	esi,kbuf
  mov	edi,[macro_ptr]
smd_80:
  cmp	edi,macro_buffer_end
  jb	smd_90   		;jmp if more room in record buffer
  mov	eax,[status_color1]	;get color (change to status_color)
  mov	bh,[status_line_row]
  mov	bl,1			;column 1
  mov	ecx,macro_error_msg	;get msg address
  call	display_color_at	;display message
  call	macro_record_toggle	;turn macros off
  jmp	smd_exit
smd_90:
  lodsb
  stosb
  or	al,al
  jnz	smd_80			;loop till macro data stored
  mov	[macro_ptr],edi
  stosb				;put extra zero on end to terminate macro
smd_exit:
  ret
;

;********************************** decode logic ********************
; lookup_key - scan key strings looking for match
;   ecx - index if found, 0 if not found
;
lookup_key:
  mov	esi,keystring_tbl
  xor	ecx,ecx
k1:	mov	edi,kbuf
  mov	al,byte [edi]		;get kbuf entry
  cmp	al,byte [esi]		;compare to keystring
  je	k4			;initial char. match
k2:	inc	esi
k3:	cmp	byte [esi],0		;end of tbl entry
  jne	k2			;loop if not end of tbl str
k3a:	inc	esi
  inc	ecx
  cmp	byte [esi],0		;check if end of table
  jne	k1			;jmp if more strings
  xor	ecx,ecx			;flag no match
  jmp	k6
;
; we have a match
;
k4:	inc	esi
  inc	edi
  mov	al,byte [edi]		;get next kbuf entry
  cmp	byte [esi],al		;match?
  jne	k3			;jmp if no match
  cmp	al,0			;end of kbuf string
  je	k5			;jmp if match at zero in both
  cmp	byte [esi],0		;end of table string
  jne	k4			;keep comparing if more data
;
; are we at end of this string

  jmp	k3a		
k5:	inc	ecx			;point ecx at match
k6:	ret
;---------------------
; decode_key - look up processing for this key
;  input - kbuf - has char zero terminated
;  output - ecx = ptr to processing or zero if no match
;           eax,ebx modified
decode_key:
  call	lookup_key
  jcxz	dk_end		;exit if no match
  mov	eax,ecx		;save index in -eax-
  mov	ecx,[key_mode] 	;get mode
  mov	ebx,cmd_index_tbl-1 ;we must be in cmd mode
  jecxz	dk3		;jmp if cmd mode
  mov	ebx,edit_index_tbl-1
;  dec	ecx
;  jecxz	dk3		;jmp if edit mode
;  mov	ebx,view_index_tbl-1
dk3:
  add	ebx,eax		;index into table
  xor	eax,eax
  mov	byte al,[ebx]	;get byte index to processing
  cmp	eax,0		;check if no process for this key
  jne	dk4		;jmp if process found
  sub	ecx,ecx
  jmp	dk_end
dk4:
  shl	eax,2		;convert to dword index
  mov	ecx,process_adr_tbl -4
  add	ecx,eax
dk_end:	ret

; (#4#) mouse processing ********************************
;---------------------------------
; look up mouse processing table
;  input: [mouse_mode]
; output: esi = table address
;    
get_mouse_table:  
  xor	eax,eax
  mov	al,[mouse_mode]
  shl	eax,2
  add	eax,mouse_tables-4
  mov	esi,[eax]		;get table
  ret
;-------------------------------------------------------------------
; process mouse event
;   input:  kbuf has mouse data -1,button,col,row
; output: ecx = process to call

mouse_event:
  mov	bl,[kbuf+2]	;get column 1+
  mov	bh,[kbuf+3]	;get row 1+
  mov	al,[kbuf+1]	;get event type
  mov	word [mouse_col],bx
  mov	byte [mouse_button],al
;
; check if click inside active window
;
  xor	eax,eax
  mov	al,[win_loc_row]
  cmp	bh,al		;compare mouse-line to window top line
  jb	me_42		;jmp if above active window
  add	al,[win_rows]	;compute end of window
  cmp	bh,al
  ja	me_42		;jmp if below active window
;
; check column
;
  mov	al,[win_loc_col]
  cmp	bl,al		;compare-column to window left edge
  jb	me_42		;jmp if active window left
  add	al,[win_columns]
  cmp	bl,al
  jbe	me_50		;jmp if inside active window
;
; we are not inside the active window, activate this window
;
me_42:
  mov	byte [mouse_mode],1
  push	ebx
  call	other		;display new active window
  pop	ebx
  jmp	me_90		;go move cursor
;
; we are inside active window, check if mouse_mode already active
;
me_50:
  cmp	byte [mouse_mode],0
  jne	me_51			;jmp if mouse active
  mov	byte [mouse_mode],1
  jmp	short me_90		;jmp if mouse inactive, go move cursor
;
; we are inside active window and mouse is active,  button press?
;
me_51:
  cmp	bh,[status_line_row]
  jne	me_90		;not button, go move cursor    
;
; decode mouse click using tables for each mode
;
  call	get_mouse_table		;returns table in eax
  call	decode_mouse_button
  jmp	short me_exit  
;
; we are inside active window, mouse_mode was inactive, move cursor?
;
me_90:
  cmp	bh,[status_line_row]
  je	me_96			;jmp if click on status line
  mov	[crt_cursor],bx		;store mouse click location
  xor	edx,edx
  mov	dl,[mouse_row]
  sub	dl,[win_loc_row]	;make virtual row
  add	edx,[crt_top_linenr]
  mov	[cursor_linenr],edx
  call	compute_pointer_from_linenr  ;returns edi=start of line
  or	edx,edx
  jz	me_92			;jmp if linenr found
;
; click was beyond end of file marker
;
  mov	al,[mouse_row]
  sub	al,dl			;compute new row
  mov	byte [crt_cursor+1],al	;store new row
  sub	[cursor_linenr],edx	;adjust linenr
;
; check if left-click to launch program
;
me_92:
  mov	[editbuf_cursor_line_ptr],edi
  mov	bl,[mouse_col]
  call	check_cursor_column
me_96:
me_exit:      
  ret

;--------------------------------------
; decode mouse button
;  input:  esi = mouse table
;          [mouse_col]
; output: esi points at table (button text) entry
;
decode_mouse_button:
  mov	bh,[win_loc_col] ;starting column
  mov	bl,[mouse_col]	;click point -> bl
  xor	eax,eax
dmb_10:
  mov	edx,[esi]	;get process
  add	esi,4		;move to button text
  mov	ecx,esi		;save for exit
dmb_15:
  lodsb
  cmp	al,8
  ja	dmb_20		;jmp if ascii
  cmp	al,0
  je	dmb_exit	;exit if no match
  add	bh,al		;move column
  jmp	dmb_10		;loop back to check next label
dmb_20:
  cmp	bh,bl		;are we at click
  je	dmb_30		;jmp if click point found
  inc	bh
  jmp	short dmb_15
;
; we have found click column and process, go do it
;
dmb_30:
  or	edx,edx
  jz	dmb_exit	;exit if not entry  
  mov	esi,ecx		;get pointer to label text  
  call	edx
dmb_exit:
  ret


; (#5#) file processing *********************************
;----------------------------------------------------------------------
; file setup
;  input: ebp = file end
;
file_setup:
  mov	edi,[editbuf_ptr]
  mov	dword [file_end_ptr],ebp
  mov	byte [ebp],0ah			;put 0ah at end of file

  mov	dword [editbuf_cursor_ptr],edi
  mov	dword [editbuf_cursor_line_ptr],edi
  mov	dword [crt_top_ptr],edi

  mov	dword [tag_a],0			;clear existing tags

  mov	byte [file_change],20h
  mov	byte [file_location],1	;set in memory state for file
  ret
;---------------------------------------------------
; confirm before exit
;
confirm:
  mov	eax,[exit_screen_color]
  mov	[status_color1],eax		;set color for get_string
  call	confirm_current
  call	other
  call	confirm_current
  ret
;------------------------
confirm_current:
  call	clear_screen
  mov	ecx,crlf_msg
  call	display_asciiz

  cmp byte [file_change],UNCHANGED	;check if file changed
  je	cc_exitx				;exit if file unchanged
;
; display FILE1> or FILE2> msg
;
  mov	ecx,file1_prompt
  test	byte [active_window],1
  jz	show_fnumber
  mov	ecx,file2_prompt
show_fnumber:
  call	display_asciiz
  mov	ecx,file_path
  cmp	byte [ecx],0			;check if named file
  jne	cc_show_name			;jmp if file has name
;
; modified file without a name
;
  mov	ecx,noname_msg
cc_show_name:
  call	display_asciiz
  mov	ecx,modified_msg
  call	display_asciiz
;
; ask if file needs saving
;
cc_get_key:
  mov	esi,save_msg
  mov	edi,char_out		;character buffer
  mov	byte [edi],0		;clear any existing buffer contents
  mov	eax,1			;max input string size
  call	get_string
  cmp	byte [char_out],'n'
  je	cc_exitx
  cmp	byte [char_out],'y'
  jne	cc_get_key		;exit if no  save
;
; user want to save file
;
  cmp	byte [file_path],0
  jne	cc_save_named
;
; save un-named file
;
  mov	ecx,crlf_msg
  call	display_asciiz
  call	sef_02
cc_exitx:
  jmp	short cc_exit
;
; save named file
;
cc_save_named:
  mov	esi,file_path
  call	sef_20

cc_exit:
  mov	ecx,crlf_msg
  call	display_asciiz
cc_exit2:		;-- used by save_edit_file
  ret

;---------------------------------------------------
; save edit file - assumes file to be saved is active
;  inputs:  [file_path]  = file path
;           [file_change] = 20h or "*"  - exits if not set
;
save_edit_file:
  mov	esi,file_path
  cmp byte [file_change],UNCHANGED	;check if file changed
  je	cc_exit2			;exit if file unmodified
  cmp	byte [esi],0		;check if file named
  jz	cc_exit2		;exit if file un-named
  cmp	byte [backup_flag],1	;backup enabled?
  jne	sef_20			;jmp if backups disabled_
;
; check if file is symlink
;
sef_05:
  mov	ebx,file_path
  mov	ecx,bakpath
  mov	edx,300			;size fo bakpath buffer
  mov	eax,85
  int	byte 80h			;read link
  or	eax,eax
  js	sef_07			;jmp if normal file
  add	eax,bakpath
  mov	byte [eax],0		;put zero at end of target file
;
; move linked file to path_buf
;
  mov	esi,ecx
  mov	edi,ebx
  call	move_asciiz
;
; create backup file name
;
sef_07:
  mov	esi,ebx			;get file_path
  mov edi,ecx			;bakpath
sef_10:
  call	move_asciiz
  mov	al,'~'
  stosb
  mov	al,0
  stosb

  mov	ecx,bakpath
  mov	ebx,file_path	;
  mov	eax,38		;rename file code
  int	byte 80h
  call	error_check
;
; open file to save edit buffer
;
; entry point for "Q" "W" keys to write file --------
sef_20:
  mov	eax,file_path
  cmp	byte [eax],0
  je	sef_exit
  mov	ebx,[editbuf_ptr]
  mov	ecx,[file_end_ptr]
  sub	ecx,ebx		;compute file length

  xor	edx,edx
  mov	dx,[file_attributes]
  or	edx,edx
  jnz	sef_21		;jmp if attributes ok
  mov	dx,644q
sef_21:
  mov	ebp,edx		;get file attributes
  mov	dl,9h		;preserve permissions & write local

  call	file_write
  call	error_check	;check for errors

sef_exit:
  ret

;-------------------------------------------------------------

save_block:
  mov	eax,block_file_name
  mov	ebx,[blockbegin]
  mov	ecx,[blockend]
  sub	ecx,ebx			;compute length of block
;  mov	dl,2			;write to $HOME/[base]
  mov	dl,0ah			;write with permissions in ebp
  push	ebp
  mov	ebp,0666q
  call	file_write
  pop	ebp
  call	error_check
sb_exit:
  ret

;--------------------------------------------------
; check program parameters for file name, init files
;  input:   esi = pointer to stack pointers
;  outupt:
;         
;
parse_command_line:
  lodsd				;get parameter count
  lodsd				;get pointer to program name
  lodsd				;get first parameter ptr
  or	eax,eax
  jz	pcl_50			;jmp if no more parameters
;
; we have found file1 (place in active database)
;
  push	esi
  mov	esi,eax
pcl_14:
  mov	edi,file_path  
pcl_16:
  call	move_asciiz		;save program name
  call	expand_filename		;expand filename
;
; check for additional parameters or file2
;
  pop	esi			;get stack pointers
  lodsd				;get next pointer
  or	eax,eax
  jz	pcl_30			;jmp if only one file
  mov	esi,eax
;
; we have found file2 (place in templateB database)
;
  mov	edi,file2_path  
  call	move_asciiz		;   save program name
pcl_30:
  mov	edx,_parse
  call	read_edit_file
  jmp	pcl_80
;
; no parameters entered
;
pcl_50:
;
; history has file name
;
  mov	edx,_his
  call	read_edit_file
pcl_80:
  ret
;----------------------------------------------
; read setup/history file if it exists
;  inputs: none
; output: al=0 success
;         al=1 abort
; note: get_history has two exit points.
;
history_filename db	'.a.ini',0

start_error:
 db 0ah
 db 'Setup files not found for this user or fatal error',0ah
 db 'occured.  Install needed? Press any key to continue',0ah
 db 0ah,0

get_history:
;  mov	dword [fname_ptr],history_filename	;?? needed
  mov	edi,ini_path
  call	find_home
  mov	al,'/'
  stosb
  mov	esi,history_filename
  call	move_asciiz
  mov	eax,33			;access kernel call
  mov	ebx,ini_path         
  mov	ecx,4  			;check for read permission
  int	byte 80h
  or	eax,eax
  jnz	rh_setup		;jmp if no a.ini
  jmp	uc_read			;jmp if a.ini found
;
; first time entry, do setup
;
rh_setup:
  mov	byte [config_code],'1'
  mov	esi,config_filename		;config program + first time flag
  call	sys_ex       
;
; return codes are: 0 - normal return
;                   5 - user aborted setup
;                  11 - could not start asmedit_setup
;                  -1 - ? error
  cmp	al,0				;success?
  je	gs_success			;jmp if files installed
  cmp	al,5h			;check if user abort
  je	rh_abort		;exit if user abort
;
; display error but do not use error_handler
;
rh_problem:
  mov	ecx,start_error
  call	display_asciiz
  call	read_keys
rh_abort:
  mov	al,1
  ret

gs_success:
  call	uc_read				;go restore a.ini
  jmp	uc_exit				;go save default settings
;------------------------------------------
; inputs: ; al = parameter for asmedit_setup
; output:   al = 0
;
update_config:
;
; write default config file out
;
  call	write_history_file
  call	error_check
;
; ask asmedit_setup to update a.ini
;
  mov	esi,config_filename		;config program + first time flag
  call	sys_ex
uc_launch2:
  or	al,al
  jnz	uc_exit
;------------------------------- entry point ---
; read a.ini back
;
uc_read:			;**** entry point from get_history
  mov	eax,ini_path
  mov	ebx,version		;buffer to read into
  mov	dl,09h			;simple file
  call	file_read		;returns file length or negative error# in eax, sign bit set
  js	uc_exit			;exit if error
  mov	esi,[editbuf_ptr]
  add	dword [editbuf_cursor_ptr],esi	;convert relative value to absolute
  mov	byte [active_window],0	
  mov	byte [file_location],1
  mov	byte [file_change],20h	;set unchanged status
uc_exit:
;
; save default settings
;
  mov	esi,insert_overtype
  mov	edi,saved_settings
  mov	ecx,18
  rep	movsb
  xor	eax,eax			;set return state to success
  ret
;------------------------------------------------------------
; compute_cursor_data - set all cursor variables from cursor_ptr
;  inpusts:  esi = cursor
;
compute_cursor_data:
  mov	ebp,[editbuf_ptr]
  mov	[editbuf_cursor_ptr],esi	;save cursor
ccd_01:
  cmp	esi,ebp			;check if at top of file
  je	ccd_11			;jmp if cursor at top of file
;
; scan back to start of line - to set editbuf_cursor_line_ptr
;
ccd_02:
  dec	esi
  cmp	byte [esi],0ah
  je	ccd_10			;exit if prev found
  cmp	esi,ebp			;esi = editbuf
  jne	ccd_02			;loop till start of line
  jmp	ccd_11
ccd_10:
  inc	esi
ccd_11:
  mov	[editbuf_cursor_line_ptr],esi	;save start of line with cursor
;
; scan back to set crt_top_ptr and crt_row
;
  mov	bl,1			;row 1
  mov	bh,[win_rows]		;total rows
ccd_12:
  cmp	esi,ebp			;esi = editbuf
  je	ccd_20			;go set values if at top of file
ccd_14:
  dec	esi
  cmp	byte [esi],0ah
  je	ccd_15			;loop till start of line
  cmp	esi,ebp			;exi = editbuf
  je	ccd_20			;go set values
  jmp	ccd_14
ccd_15:
  inc	esi			;check if we have found old crt_top_ptr
  cmp	esi,[crt_top_ptr]
  je	ccd_20			;jmp if we have found old crt_top_ptr
  dec	esi			;restore esi

  inc	bl
  dec	bh
  jnz	ccd_12			;loop till top of screen
  inc	esi			;move past 0ah to line start
  dec	bl			
;
ccd_20:
  mov	[crt_top_ptr],esi	;set display top ptr
  add	bl,[win_loc_row]	
  dec	bl			
  mov	[crt_cursor + 1],bl		;set row#
;
; now set column for display
;
  mov	edi,[editbuf_cursor_ptr]
  call	set_cursor_from_ptr
  mov	edi,[editbuf_cursor_ptr]
  call	compute_line		;set [cursor_linenr]
  mov	[cursor_linenr],edx
;
; compute crt_top_linenr
;
  xor	eax,eax
  mov	al,[crt_cursor+1]	;get display row
  sub	al,[win_loc_row]
  sub	edx,eax
  mov	[crt_top_linenr],edx

  ret  
;-------------------------------
; set highlight flag is .asm file
;
check_for_asmfile:
  mov	esi,file_path
  mov	byte [asm_comment_char],';'
pfs_60:				;scan to end of file name
  lodsb
  cmp	al,0
  jne	pfs_60
  cmp	dword [esi-5],'.asm'
  je	pfs_66			;jmp if .asm
  cmp	dword [esi-5],'.inc'
  je	pfs_66			;jmp if .inc
  cmp	word [esi-3],'.s'
  je	pfs_65			;jmp if not .s
pfs_62:
  dec	esi
  cmp	byte [esi],'/'
  jne	pfs_62
  inc	esi
  cmp	dword [esi],"make"
  je	pfs_65
  cmp	dword [esi],"Make"
  je	pfs_65
  mov	al,0			;preload highlight disable code

  mov	edx,[editbuf_ptr]
  cmp	word [edx],'#!'
  jne	pfs_70  		;jmp if not script
pfs_65:
  mov	byte [asm_comment_char],'#'
pfs_66:
  mov	al,1
pfs_70:
  mov	byte [show_asm],al
  ret
;---------------------------------------------------------
; write history file
;
write_history_file:
  test	byte [active_window],1
  jz	whf_10			;jmp if template1 active
  mov	edi,active_template
  mov	esi,file1_template
  mov	ecx,template_size
  rep	movsb
whf_10:
;
; restore default settings
;
  mov	esi,saved_settings
  mov	edi,insert_overtype
  mov	ecx,18
  rep	movsb
;
; write file
;
  mov	ebx,version		;output data
  mov	eax,ini_path
  mov	ecx,[editbuf_ptr]         
  sub	dword [editbuf_cursor_ptr],ecx	;make editbuf pointer relative
  mov	ecx,a_ini_size
  mov	dl,2
  call	file_write
  mov	ecx,[editbuf_ptr]
  add	dword [editbuf_cursor_ptr],ecx	;restore cursor ptr
; we don't want error reporting if the /.asmide/edit  missing, 
;  call	error_check
  ret
  
; (#6#) edit buffer & cursor processing *************************


;
; inputs: [scan_direction] - find direction 1=forward -1=back
;         edi - cursor position
;         [file_end_ptr] - end of search
; output: carry set if not-found and ignore following
;         edi - points to new cursor posn if found
;         [find_str_len] - length of find string
;         find_str - find string
;
find_string:
  mov	edi,[editbuf_cursor_ptr]
  mov [find_ptr],edi		;save start of find location
  mov esi,find_msg		;prompt message for find

;compute max string length
  xor	eax,eax
  mov	al,[term_columns]
  sub	al,12

  mov	edi,find_str		;get string buffer
  mov	byte [str_terminator],1bh ;set ESC as terminator for string
  call	get_string
  mov	[find_str_len],eax	;save string length
  jecxz	skip_asking		;jmp if string entered
  jmp	n_nofind		;exit if no string entered
skip_asking:
  mov  edi,[find_ptr]		;restore cursor position
  cmp	byte [get_string_flg],0
  jnz	find_again2		;jmp if new string entered

;--------------------------- entered with edi = search position -----
find_again1:
  cmp	byte [scan_direction],1	;are we searching forward
  jne	find_again2		;jmp if searching back
  add	edi,[find_str_len]	;move past last find

;--------------------------- entered with edi = search position -----
find_again2:
  call FndText
  jc n_nofind
;
; set paramaters for display edi=new cursor position
;
  call	center_cursor
  clc
  mov	byte [last_cmd],1	;last command was a find
  jmp n_end
n_nofind:
  mov	esi,[editbuf_cursor_ptr]
  call	compute_cursor_data
  stc
n_end:
  ret
;--------------------
;inputs
; [file_end_ptr] - end of file ptr
; find_str = match string
; edi - cursor position in buffer
; scan_direction  1 for forward -1 for reverse find
;output
; edi,ebx = match pointer if carry
; clobbered = ecx,eax,esi
;
FndText:
  dec	edi			;adjust buffer pointer for loop pre-bump
;                               ;adding "dec edi" kills find again.
ft_10:
  mov ch,[case_mask]		;get case mask
  mov esi,find_str		;get match string
  cld
  lodsb
  or	al,al
  jz	notfnd			;exit if no string entered
  call	check_al_case
fnd1:
  add edi,[scan_direction]	;direction of find control
  mov cl,byte [edi]
  call	check_cl_case
fnd6:
  cmp al,cl
  jne fnd8			;loop if no match
fnd2:
  mov ebx,edi
fnd3:
  lodsb			;get next match string char
  or al,al		;=end?
  jz fnd			;done if match
  call	check_al_case
fnd7:	inc edi
  cmp	edi,[file_end_ptr]
  jae	notfnd		;exit if string not found
  mov cl,byte [edi]	;get next buffer char
  call	check_cl_case
fnd10:	cmp al,cl
  jz fnd3			;loop if match
  mov edi,ebx
  jmp ft_10
fnd8:
  cmp edi,[file_end_ptr]
  ja notfnd
fnd9:
  cmp edi,[editbuf_ptr]
  jb	notfnd
  jmp	fnd1
notfnd:
  mov	byte [last_find_status],0	;set not found flag
  cmp	byte [replace_all_flag],0
  jne	ft_80			;jmp if not special msg needed
  mov	dword [special_status_msg_ptr],not_found_msg
ft_80:
  stc
  ret
fnd:
  mov	byte [last_find_status],1	;set found flag
  mov edi,ebx
  clc
  ret
;---------------------
; input: al = ascii
;        ch = mask
check_al_case:
  cmp	al,"a"
  jb	cac_exit
  cmp	al,"z"
  ja	cac_exit
  and	al,ch
cac_exit:
  ret
;--------------------
check_cl_case:
  cmp	cl,"a"
  jb	ccc_exit
  cmp	cl,"z"
  ja	ccc_exit
  and	cl,ch
ccc_exit:
  ret
;------------------------------------------------------------
;
; functions for INSERTING, COPYING and DELETING chars in text
;
; inputs: eax = number of bytes to delete
;         edi = beginning of block to delete
;         [file_end_ptr] = end of file
; output: carry set if error
;
DeleteByte:
  or eax,eax
  jz db_exit		;jmp if delete count = 0
  mov ecx,[file_end_ptr]
  cmp edi,ecx
  jb  db_ok		;jmp if inside file
  stc
  jmp	short db_exit
db_ok:
  push edi
  sub ecx,edi
  lea esi,[edi+eax]
  sub ecx,eax
  inc ecx
  cld
  rep movsb
  neg eax
  pop edi		;
  mov	byte [file_change],CHANGED
  add [file_end_ptr],eax
  clc
db_exit:
  ret
;
; insert character into file buffer
;  input: edi = cursor locaton
;         [file_end_ptr] = file end
;         eax = 
Insert1Byte:
  xor eax,eax
make_hole0:
  inc eax
;
; do NOT destroy eax
;
make_hole:
  or eax,eax
  jz mh_ret
  mov	ecx,[file_end_ptr]
  add	ecx,eax			;compute last loc. of combined files
  add	ecx,2000		;add in pad
  cmp	ecx,[editbuf_end]
  jb	SpaceAva
  mov	eax,12			;get error code
  call	error_handler
  stc
mh_ret:
  ret
  
SpaceAva:
  push edi
  mov esi,[file_end_ptr]
  lea ecx,[esi+1]
  sub ecx,edi
  lea edi,[esi+eax]
  std
  rep movsb
  pop edi		;
  cld
  mov	byte [file_change],CHANGED
  add [file_end_ptr],eax
  clc
  ret

;
; input: eax = move length
;        esi = from
;        edi = to
; output: edi unchanged
;
MoveBlock:
  push edi
  mov ecx,eax
  cld
  rep movsb
  pop edi
  clc
MoveBlEnd:
  ret



cut_block:
  mov eax,[blockend]
  mov	edi,[blockbegin]
  sub	eax,edi			;compute length of block
  call DeleteByte
  ret


;----------
; move asciiz string
;  input: esi = string ptr
;         edi = storage buffer
;         direction flag = cld
;  output: edi & esi updated to string ends
;
move_asciiz:
  lodsb
  stosb
  cmp	al,0
  jne	move_asciiz
  dec	edi		;point at zero on end of new string
  ret
;
;-----------------------------------
; scan back to find previous page
;  input: edi = ptr inside current top line
;         ecx = current line#
;         [win_rows] = size of page
;         [editbuf] = top of file
; output: edi = start of prev page
;         ecx = line #
look_page_up:
  xor	eax,eax
  mov	al,[win_rows]
lpu_10:
  call	end_prev_line
  cmp	edi,[editbuf_ptr]
  jb	lpu_20
  jne	lpu_11
  dec	ecx
  jmp	lpu_21
lpu_11:
  dec	ecx
  dec	eax
  jnz	lpu_10
  call	end_prev_line
lpu_20:
  inc	edi
lpu_21:
  ret  
;
;--------------------------------------
; compute pointer from line number
;  input: edx = line number
;  output: edi points at line beginning
;          edx = 0 if found, else distance from bottom of file
;
compute_pointer_from_linenr:
  mov	edi,[editbuf_ptr]
;  cmp	edx,1
;  je	cpfl_exit
  dec	edx
  jz	cpfl_exit		;exit if on top line
cpfl_lp:
  cmp	edi,[file_end_ptr]
  jae	cpfl_exit		;exit if end of file found before line
  call	next_line
  dec	edx
  jnz	cpfl_lp
cpfl_exit:    
  ret
;------------------------------
;----------------------------
; check cursor row
;  input: none
;         assumes [crt_top_ptr] and [editbuf_cursor_ptr] are correct
; output: [crt_cursor+1] (row)
;
check_cursor_row:
  push	edi
  mov	edi,[crt_top_ptr]
  mov	ebx,[editbuf_cursor_ptr]
  mov	eax,0			;starting row count
ccr_lp:
  call	next_line
  cmp	edi,ebx
  ja	ccr_match
  inc	eax
  jmp	ccr_lp
ccr_match:
  add	al,[win_loc_row]
  mov	[crt_cursor +1],al	;store row
  pop	edi
  ret  
;-------------------------------
; center cursor line
;  input: edi = current cursor ptr
;
center_cursor:
  cmp	edi,[editbuf_ptr]
  jae	cc_05			;jmp if pointer ok
  mov	edi,[editbuf_ptr]
cc_05:
  push	edi
  xor	ecx,ecx
  mov	cl,[win_rows]
  shr	ecx,1
cc_lp:
  cmp	edi,[editbuf_ptr]
  jbe	cc_11		;jmp if at top of file
  call	end_prev_line
  dec	ecx
  jnz	cc_lp
cc_10:
  inc	edi		;move to start of line
cc_11:
  cmp	edi,[editbuf_ptr]
  jb	cc_11a
  cmp	byte [edi-1],0ah ;check if at beginning of line
  je	cc_12
  dec	edi
  jmp	cc_11
cc_11a:
  mov	edi,[editbuf_ptr]
cc_12:  
  mov	[crt_top_ptr],edi
  call	compute_line
  mov	[crt_top_linenr],edx
;
  pop	edi
  call	set_cursor_from_ptr
  call	check_cursor_row
  call	compute_line
  mov	[cursor_linenr],edx
  ret
  
;---------------------------
; set paramaters from cursor column [crt_cursor]
; input: bl = cursor column (1 based)
;        edi = pointer somewhere in cursor row
; output: editbuf_cursor_line_ptr
;         crt_cursor (cursor column)
;         edi, editbuf_cursor_ptr
;
check_cursor_column:
  mov	byte [crt_cursor],bl		;store column
  call	end_prev_line
  inc	edi				;move to start of current line
;  mov	[editbuf_cursor_line_ptr],edi	;store line start
  xor	ebx,ebx
  mov	bl,[crt_cursor]
  sub	bl,[win_loc_col]		;convert to virutal column
  add	ebx,[crt_left_column]		;include scroll position
  inc	ebx				;make 1 based index so tabs work out

  xor	eax,eax
ccr_10:
  inc	eax				;make eax "1" based counter
  cmp	eax,ebx				;check if at match point
  je	ccr_50				;jmp if match
  cmp	byte [edi],09h			;check if sitting on tab
  jne	ccr_30				;jmp if not tab
  test	al,07
  jnz	ccr_10				;loop till tab expansion done
ccr_30:
  cmp	byte [edi],0ah
  je	ccr_50				;jmp if at end of line, no match
  inc	edi
  jmp	ccr_10				;move to next char
;
; we have found a match, edi = match  al,bl = virtual column
;
ccr_50:
  mov	dword [editbuf_cursor_ptr],edi	;save cursor ptr
ccr_exit:
  ret
    
;-------------------------
; set paramaters from cursor pointer
; input: edi = pointer to cursor data
;        crt_cursor+1 - assumes cursor row is correct
; output: editbuf_cursor_ptr  (stored)
;         crt_cursor - updated column
;         editbuf_cursor_line_ptr
;         crt_left_column
;         
set_cursor_from_ptr:
  push	edi
  mov	[editbuf_cursor_ptr],edi
  mov	ebx,edi			;save cursor ptr
  call	end_prev_line
  inc	edi			;move to start of current line
  mov	[editbuf_cursor_line_ptr],edi
;
; count text columns to cursor ptr (expanding tabs) (can be dword value)
;  edi = start of line
  mov	eax,1			;start line column at 1
ccp_05:
  cmp	edi,ebx
  je	ccp_50			;jmp if at match point
  cmp	byte [edi],09h		;check if on tab
  jne	ccp_20			;jmp if not tab
  dec	eax		
ccp_10:
  inc	eax
  test	al,07
  jnz	ccp_10			;skip for tab
  inc	eax		
  jmp	ccp_32
ccp_20:
  cmp	byte [edi],0ah		;check if at end of line
  je	ccp_50			;fix pointer if at end of line
ccp_30:
  inc	eax
ccp_32:
  inc	edi				;move to next char
  jmp	ccp_05
;
; we are now at cursor ptr, eax = 1 based column
;
ccp_50:
  sub	eax,[crt_left_column]		;remove scroll columns
  jbe	ccp_left			;jmp if cursor outside window left
;
; check if cursor inside window
;
  push	ecx
  sub	ecx,ecx
  mov	cl,[win_columns]		;get crt columns
  cmp	eax,ecx				;are we inside crt window?
  pop	ecx
  jbe	ccp_60				;jmp if inside window
;
; we are not in window, window is to our right
;
  add	eax,[crt_left_column]		;restore index
  inc	dword [crt_left_column]
  jmp	ccp_50				;scroll left and try again
;
; cursor is outside window left
;
ccp_left:
  add	eax,[crt_left_column]		;restore cursor index
  dec	dword [crt_left_column]
  jmp	ccp_50				;scroll right and try again
;
; cursor is inside window, convert to physical coordinate
;
ccp_60:
  dec	eax				;convert to zero based
  add	al,[win_loc_col]		
  mov	byte [crt_cursor],al		;store column
  pop	edi
  ret

;-----------------------
; move to end of previous line
; input: edi = ptr somewhere inside current line, possibly on 0ah
; output: edi = ptr to end of previous line
;
end_prev_line:
  dec	edi
  cmp	byte [edi],0ah
  jne	end_prev_line
  ret
;------------------------
; move to next line
; input:  edi = ptr somewhere inside current line
; output: edi = pointer to start (past 0ah) of next line
;
nl_lp:
  inc	edi
next_line:
  cmp	byte [edi],0ah
  jne	nl_lp
  inc	edi
  ret


;------------------------
; move to line number in ecx
;  input: ecx = line number
;  output: display data updated
;
goto_line:
  mov	edi,[editbuf_ptr]	;start at top of file
  xor	eax,eax
gl_10:
  inc	eax			;bump line count
  cmp	eax,ecx
  je	gl_match		;jmp if line found
  cmp	edi,[file_end_ptr]
  jae	gl_30			;jmp if at end of file
  call	next_line
  jmp	gl_10			;loop
gl_30:
  cmp	eax,1
  je	gl_exit			;jmp if empty file
  dec	eax
  call	end_prev_line
  call	end_prev_line
  inc	edi
gl_match:
  call	center_cursor
gl_exit:
  ret

;---------------------------
; compute line number from pointer
;  input:  edi = cursor ptr
;  output: edx = line number
;  
compute_line:
  push edi
  mov esi,[editbuf_ptr]		;get text start
  xchg esi,edi			;edi=start of text  esi=cursor position?
;
; compute current line#
;
  push ecx
  xor edx,edx
  cld

cl_lp:
  inc edx			;count line
  mov ecx,999999
  mov al,NEWLINE
  repne scasb			;scan for 0ah
  mov eax,999998			;find eol
  sub eax,ecx			;eax = distance to end
  cmp edi,esi			;at cursor posn?
  jbe cl_lp			;loop till end
  
  pop ecx
  pop edi
  ret
;
; (#7#) conversinon & calc  ***********************************
;--------------------
; convert dword to decimal ascii
;  input:  eax = binary
;          edi = start of storage area,
;          esi = number of digets to store
; output: edi = pointer to end of string
;               eax,ebx,ecx destroyed
dword_to_ascii:
  mov	ecx,10
  xchg eax,ebx
dta_entry:
  xchg eax,ebx
  cdq
  div ecx
  xchg eax,ebx
  mov al,dl
  and al,0fh
  add al,'0'
  push	eax
  dec	esi
  jz	dta_end	;jmp if correct number of digits stored
  call	dta_entry
dta_end:
  pop	eax
  stosb
  ret


;--------------------
; convert dword to decimal ascii
;  input:  eax = binary
;          edi = end of storage area, (decremented)
; output: edi = pointer to beginning of string
;               eax,ebx,ecx destroyed
IntegerToAscii:
  push	eax
  or eax,eax
  jns ItoA1
  neg	eax
ItoA1:
  push byte 10
  pop ecx
  std
  xchg eax,ebx
Connum1:
  xchg eax,ebx
  cdq
  div ecx
  xchg eax,ebx
  mov al,dl
  and al,0fh
  add al,'0'
  stosb
  or ebx,ebx
  jne Connum1
  pop	eax
  or	eax,eax
  jns	ita_exit
  mov	al,'-'
  stosb
ita_exit:
  cld
  ret

;-------
; parse string for calc
;  input: esi = string ptr
;  output: esi = ptr to beginning of string
;          edi = pointer to string ending separator character
;
calc_parse:
  cmp	byte [esi],0
  je	cp_exit		;jmp if end of data
  cmp	byte [esi],' '
  jne	cp_10		;jmp if beginning of string
  inc	esi
  jmp	short calc_parse
cp_10:
  push	esi
  lodsb			;get first char
  cmp	al,'0'
  jb	cp_30		;if first char then move past
cp_lp:
  lodsb
  cmp	al,'0'
  jae	cp_lp		;jmp if possible number
  dec	esi		;move back to unknown char.
cp_30:
  mov	edi,esi
  pop	esi
cp_exit:
  ret  
  
;-----------------------------
; input al = data byte
; output ax = char
;  
byte_to_hex:
  mov	ah,al
  shr	al,1
  shr	al,1
  shr	al,1
  shr	al,1
  cmp	al,10
  sbb	al,69h
  das
  xchg	al,ah
  and	al,0fh
  cmp	al,10
  sbb	al,69h
  das
  xchg  al,ah
  ret

;-------------------------------
; convert binary dword to hex ascii string
;  input: ecx = binary
;         edi = storage area
;  output: edi points to end of stored string
;
dword_to_hex_ascii:
  push	eax
  push	edx
  cld
  mov	dl,4		;loop count
dtha_lp:
  rol	ecx,8
  mov	eax,ecx
  and	eax,0ffh	;isolate byte
  call	byte_to_hex
  stosw
  dec	dl
  jnz	dtha_lp
  pop	edx
  pop	eax
  ret

;---------------------------	
; hex ascii to binary
;  inputs:  esi = ptr to hex ascii
;  output:  ecx = binary hex value
;
hex_ascii_to_binary:
	push	eax
	push	ebx
	cld
	xor	ebx,ebx		;clear accumulator
ha_loop:
	lodsb
	mov	cl,4
	cmp	al,'a'
	jb	ha_ok1
	sub	al,20h		;convert to upper case if alpha
ha_ok1:	sub	al,'0'		;check if legal
	jc	ha_exit		;jmp if out of range
	cmp	al,9
	jle	ha_got		;jmp if number is 0-9
	sub	al,7		;convert to number from A-F or 10-15
	cmp	al,15		;check if legal
	ja	ha_exit		;jmp if illegal hex char
ha_got:	shl	ebx,cl
	or	bl,al
	jmp	ha_loop
ha_exit:
	mov	ecx,ebx
	pop	ebx		
	pop	eax
	ret	

;- - - - - - - - - - - - - - -
; convert 2 hex ascii characters to 1 hex byte
;  inputs: esi points at hex data
;  output: no carry - al = hex byte
;             carry - bad input data
;
hex_to_byte:
	cld
	push	ecx
	mov	ch,0
	call	hex_nibble
	jc	at1_exit	;jmp if conversion error
	call	hex_nibble
	mov	al,ch
at1_exit:
	pop	ecx
	ret
;---------------------------	
; inputs:  ch = accumulator for hex
; output:  ch = hex nibble in lower portion
;
hex_nibble:
	lodsb
	mov	cl,4
	cmp	al,'a'
	jb	hn_ok1
	sub	al,20h		;convert to upper case if alpha
hn_ok1:	sub	al,'0'		;check if legal
	jc	hn_abort	;jmp if out of range
	cmp	al,9
	jle	hn_got		;jmp if number is 0-9
	sub	al,7		;convert to number from A-F or 10-15
	cmp	al,15		;check if legal
	ja	hn_abort	;jmp if illegal hex char
hn_got:	shl	ch,cl
	or	ch,al
	clc
	jmp	hn_exit
hn_abort:
	stc
hn_exit:		
	ret	

;-----------------------------------
; convert ascii to decimal
;  input: esi = ptr to asciiz
;  output; ecx = integer

ascii_to_decimal:
  xor	ecx,ecx
  xor	eax,eax
  mov	bl,9
  cld
atd_lp:
  lodsb
  sub al,'0'
  js atd_exit
  cmp al,bl
  ja atd_exit
  lea ecx,[ecx+4*ecx]
  lea ecx,[2*ecx+eax]
  jmp short atd_lp
atd_exit:
  ret

; (#8#) error,kernel,shell out *********************************
;--------------------------------------------------------
; error_handler - shell out and display error message
;  inputs:  eax = error number, either + or -
;  outputs: none
;
error_check:
  or	eax,eax
  jns	eh_exit				;jmp if no error
error_handler:
  push	eax
  call	clear_screen
  pop	eax
  or	eax,eax
  jns	eh_10
  neg	eax
eh_10:
  mov	edi,err_str
  mov	esi,3
  call	dword_to_ascii
;
  mov	esi,err_name			;error prog namd + error #
  call	sys_ex
  jnc	eh_exit				;exit if launch ok

  mov	eax,[status_color1]	;get color (change to status_color)
  mov	bh,[status_line_row]
  mov	bl,1			;column 1
  mov	ecx,err_name		;get msg address
  call	display_color_at	;display message
  call	read_keys
eh_exit:
  ret
;-----------------
terminal_setup:
  mov ecx,5401h
  call IOctlTerminal0
  call	error_check
  mov esi,termios_orig
  mov edi,termios
  mov edx,edi
  push byte termios_struc_size
  pop ecx
  cld
  rep movsb
  mov byte [edx+termios_struc.c_cc+6],1
  and byte [edx+termios_struc.c_lflag+0],(~0000002q & ~0000001q & ~0000010q)
  and byte [edx+termios_struc.c_iflag+1],(~(0002000q>>8) & ~(0000400q>>8))
  or  byte [edx+termios_struc.c_iflag],40h  ; 0ah > 0dh
  mov ecx,5402h
  call IOctlTerminal
  call	error_check
;
; send escape sequence to turn on mouse
;
  mov	ecx,mouse_escape
  call	display_asciiz
  ret
;----------------------------------------------------
terminal_restore:
  mov	ecx,5402h
IOctlTerminal0:
  mov	edx,termios_orig
IOctlTerminal:		;*** entry point for terminal control calls
  mov ebx,xstdin
  mov eax,54
  int	byte 80h
  ret
;--------------------------------------------------------------
; scan process table to see if multiple copies of "a" are
; executing.
;
process_scan:
  mov	eax,[editbuf_ptr]	;buffer for scan
  mov	ebx,max			;buffer length
  mov	ecx,our_name
ps_25:
  call	process_search
  or	eax,eax
  jz	ps_41			;jmp if end of process table
  js	ps_81			;jmp if error
; we have found a match
  inc	byte [match_cnt]
  xor	eax,eax			;set continue flag
  jmp	short ps_25
; adjust file names
ps_41:
  mov	al,[match_cnt]
  or	al,al
  jz	ps_81			;jmp if error
  dec	al
  shr	al,1			;convert into adjust value
  add	[file1_tmp_name_stuff +4],al
  add	[file_tmp_name_stuff +4],al
  add	[file2_tmp_name_stuff +4],al
  add	[block_file_name_stuff],al
ps_81:
  ret

our_name:  db 'a',0

  [section .data]
match_cnt:  db 0
  [section .text]  
;---------------------------------------------------------------
    
; (#9#) display handlers  **************************************
;---------------------
;

;----------------------------------------------------------------
set_window_sizes:
  call	read_window_size
  movzx	eax,byte [crt_columns]
  shl	eax,16
  or	ax,[crt_rows]
;
; setup single window template
;
sd_10:
  mov	[winsize_sav],eax	;save size to check for term resize
  mov	bh,al			;save copy of row count
  mov	[win_rows],al
  shr eax,16
  mov	bl,al			;save copy of column count
  mov	[win_columns],al
;
; setup column count info
;
  mov byte [term_columns],al
  mov	[hor_a_columns],al
  mov	[hor_b_columns],al
  test	al,1			;check if odd column count
  jnz	odd_col
  shr	al,1
  mov	[ver_a_columns],al
  dec	al
  mov	[ver_b_columns],al
  jmp	sd_12
odd_col:
  shr	al,1
  mov	[ver_a_columns],al
  mov	[ver_b_columns],al
;
; setup row count info
;
sd_12:
  mov	al,bh
  dec eax
  mov byte [term_rows],al
  mov	[ver_a_rows],al
  mov	[ver_b_rows],al
  mov	al,bh
  test	al,1			;check if even number of rows
  jz	even_rows
  shr	al,1
  mov	[hor_a_rows],al
  dec	al
  mov	[hor_b_rows],al
  jmp	sd_20
even_rows:
  shr	al,1
  dec	al
  mov	[hor_a_rows],al
  mov	[hor_b_rows],al
;
; setup upper left corner - row
;
sd_20:
  mov	al,[hor_a_rows]
  inc	al
  inc	al
  mov	[hor_b_loc_row],al
;
; setup upper left corner - column
;
  mov	al,[ver_a_columns]
  inc	al
  inc	al
sd_41:
  mov	[ver_b_loc_col],al
;
; move selected template to active window
;
  mov	esi,win_type_a
  mov	edi,win_type
  mov	ecx,win_template_size
  cmp	byte [file_path],0	;check if history file has path
  je	sd_45			;jmp if no history file loaded
  mov	esi,status_line_row_a
  mov	edi,status_line_row
  mov	ecx,win_short_size
sd_45:
  rep	movsb
;
; fill in status line locatons
;
  mov	byte [term_statusln],bh	;single window status line location
  mov	byte [hor_b_status],bh
  mov	byte [ver_a_status],bh
  mov	byte [ver_b_status],bh
  mov	al,[hor_a_rows]
  inc	al
  mov	byte [hor_a_status],al

  mov	[status_line_row],bh	;set active window status line location
  ret


;---------------------------------------------
; fill in active window data
;
active_window_setup:
  mov	al,byte [active_window]
  mov	[win_type],al		;store win type
  cmp	al,0
  je	sd_48			;jmp if single (file1)
  cmp	al,1
  je	sd_50			;jmp if single (file2)
  cmp	al,2
  je	sd_52			;jmp if horizontal b
  cmp	al,3
  je	sd_54			;jmp if horizontal a
  cmp	al,4
  je	sd_56			;jmp if veritical b
; must be vertical-a window
  mov	al,[term_statusln]	;get status line location
  mov	[status_line_row],al
  mov	eax,dword [ver_a_loc_col]
  mov	dword [win_loc_col],eax
  jmp	sd_90

sd_48:				;single window, file1

sd_50:				;single window, file2
  mov	al,[term_statusln]	;get status line location
  mov	[status_line_row],al
  mov	eax,dword [term_loc_col]
  mov	dword [win_loc_col],eax
  jmp	sd_90
sd_52:				;horizontal b
  mov	al,[hor_b_status]	;get row for status line
  mov	[status_line_row],al
  mov	eax,dword [hor_b_loc_col]
  mov	dword [win_loc_col],eax
  jmp	sd_90
sd_54:				;horizontal a
  mov	al,[hor_a_status]	;get rows in horizontal-a window
  mov	[status_line_row],al
  mov	eax,dword [hor_a_loc_col]
  mov	dword [win_loc_col],eax
  jmp	sd_90
sd_56:				;vertical b
  mov	al,[ver_a_status]	;get status row
  mov	[status_line_row],al
  mov	eax,dword [ver_b_loc_col]
  mov	dword [win_loc_col],eax

sd_90:    
  ret
;-----------------------------------
vertical_bar:
  mov	al,[ver_a_columns]
  inc	al
  mov	ah,1
  mov	bl," "
  mov	bh,[win_rows]
  call	display_repeat_vertical
  ret
;----------------------------------
clear_screen:
  push	edx
  mov	eax,[exit_screen_color]
  call	set_color
  mov	ecx,clear_msg
  call	display_asciiz
  pop	edx
  ret
clear_msg: db 1bh,'[2J',0

;  push	edx
;  mov	eax,[exit_screen_color]
;  call	set_color
;  mov	al,1		;column
;  mov	ah,1		;row
;  mov	bl,0ah
;  mov	bh,[term_columns]
;  call	display_repeat_vertical
;  pop	edx
;  ret
;-------------------------------------
;repeat character down vertical column
; input al = column (ascii)
;       ah = row (ascii)
;       bl = char
;       bh = repeat count
;
display_repeat_vertical:
  mov	byte [display_char],bl
  mov	byte [repeat_count],bh
drv_lp:
  push	eax
  call	move_cursor		;al=column ah=row

  mov	ecx,display_char	;get ptr to character
  mov edx,1			;write one char
  mov eax, 0x4			; system call 0x4 (write)
  mov ebx, stdout		; file desc. is stdout
  int 0x80
  pop	eax			;restore ah-row al-column
  inc	ah
  dec	byte [repeat_count]
  jnz	drv_lp
  ret  
  
;---------------------------
; switch windows or files, called from "W" or "O" commands
;  input: ebx = ptr to window dimensions (style for old file)
;         ebp = ptr to window dimensions (style for new file)
;         [active_window] = new window mode
;
switch_windows:
  call	save_current_win
  call	restore_window
;
; setup database for new file
;
;  mov	esi,[editbuf_cursor_ptr]
;  call	compute_cursor_data		;
  ret  

;-------------------------------
; restore window
;  input:  ebp = style for restored window

restore_window:    
;
; get template for new window
;
  mov	al,[active_window]
  mov	esi,file1_template
  test	al,1
  jz	move_template
  mov	esi,file2_template
move_template:
  cld
  mov	edi,active_template
  mov	ecx,template_size
mt_10:
  lodsb
  stosb
  dec	ecx
  jnz	mt_10
  mov	al,[active_window]
  mov	[win_type],al		;store window mode in active database
;
; move window dimensions into active database
;
  mov	esi,ebp
  mov	edi,status_line_row
  mov	ecx,5
  rep	movsb			;move new window dimensions to old win
;
; check file status
;
af_file:
  cmp	byte [file_location],2
  je	af_read_temp
  cmp	byte [file_path],0	;check if named file
  je	af_noname		;jmp if file un-named
;
; file has a name, read it
;
  call	expand_filename		;expand any partial names
  mov	edx,_restnam
  call	read_edit_file
  jmp	short af_exit3
;
; file un-named
af_noname:
  mov	edx,_initnul
  call	read_edit_file
  jmp	af_exit3
;
; temp file exists
;
af_read_temp:
  mov	edx,_resttmp
  call	read_edit_file
  jmp	af_exit3
af_exit2:
  call	error_handler  
af_exit3:
  ret
;--------------------------------------------------------------
; read_edit_file - bit driven read of edit file, see below
;  inputs:  edx = control bits
;
  [section .data]

_his	equ	1		;called from history read
_parse	equ	2		;called from parse of filename
_null1	equ	4		;null parse/history path
_init	equ	8		;called from init
_initnul equ	10h		;null path for init.
_restnam equ	20h		;called from restore file, named
_resttmp equ	40h		;restore tmp file path

  [section .text]

read_edit_file:
  test	edx,_resttmp
  jz	ref_04			;jmp if filename at file_path
  mov	eax,file_tmp_name
  jmp	short ref_06		;jmp if read of temp file  
ref_04:
  cmp	byte [file_path],0
  jnz	ref_05			;jmp if name found
  mov	edx,_null1		;preload force null file type 1
  test	edx,_init+_restnam
  jz	ref_05			;jmp if type 1 null file
  mov	edx,_initnul
ref_05:
  test	edx,_his+_parse+_init+_restnam+_resttmp
  jz	ref_10			;skip read if null file
  mov	eax,file_path
ref_06:
  push	edx
  test	edx,_parse+_init	;check if create bit needed
  jnz	ref_07			;jmp if create needed
  test	edx,_resttmp
  jz	ref_06a
  mov	dl,26h			;read tmp file from $HOME/.asmide/edit
  jmp	ref_08
ref_06a:
  mov	dl,25h			;local file, fill editbuf, create if missing
  jmp	ref_08
ref_07:
  mov	dl,25h			;local file, create, fill editbuf
ref_08:
  mov	ebx,[editbuf_ptr]
ref_09:
  call	file_read
  pop	edx
  jns	ref_10			;jmp if file read ok
  mov	edx,_null1
  mov	byte [file_path],0	;kill file name in history
ref_10:
  test	edx,_null1+_initnul
  jz	ref_12			;jmp if normal read, eax=len ebp=attr
;
; this is a null file
;
  mov	eax,[editbuf_ptr]
  mov	dword [editbuf_cursor_ptr],eax
  xor	eax,eax
  mov	ebp,0644q		;default attributes
ref_12:
  test	edx,_resttmp
  jnz	ref_12a			;jmp to ignore temp file attributes  
  mov	ecx,ebp			;move attributes
  mov	[file_attributes],cx	;save attributes
ref_12a:
  mov	ecx,[editbuf_ptr]
  mov	[ecx-1],byte 0ah	;put 0ah around
  add	eax,ecx			;compute buffer end
  mov	[file_end_ptr],eax	;save file end
  mov	byte [eax],0ah		;  around file data
  mov	byte [file_location],1	;file is now in memory
;
; don't clear tags if restore or history
;
  test	edx,_his+_resttmp
  jnz	ref_13			;jmp to keep current tags
  mov	dword [tag_a],0		;clear tags
ref_13:
;
; check history data
;
  test	edx,_his+_resttmp
  jz	ref_20			;jmp if not history or restore
  mov	esi,[editbuf_cursor_ptr]	;get cursor ptr from history file
  cmp	esi,[editbuf_ptr]
  jb	ref_20			;jmp if pointer wrong
  cmp	esi,eax
  jbe	ref_24			;jmp if pointer ok
ref_20:    
  mov	esi,[editbuf_ptr]
;
; setup editbuf_cursor_ptr
;
  mov	[editbuf_cursor_ptr],esi
ref_24:
;  push	edx
  call	compute_cursor_data
  call	check_for_asmfile
;  pop	edx
ref_50:
  ret
;
;---------------------------------------------------------------
; input: ebx = pointer to window dimensions for restored window
; 
save_current_win:
  cld
  push	ebp
  mov	esi,ebx
  mov	edi,status_line_row
  mov	ecx,5
  rep	movsb			;move new window dimensions to old win
  xor	edx,edx			;non-acive file color
  call	display_screen
  call	display_status_line
;
; write old win -> temp file
;
  mov	eax,file_tmp_name
  mov	ebx,[editbuf_ptr]
  mov	ecx,[file_end_ptr]
  sub	ecx,ebx
;  mov	dl,2
  mov	dl,0ah			;write local , permissions in ebp
  push	ebp
  mov	ebp,0666q
  call	file_write
  pop	ebp
  call	error_check
;
; save old win -> template
;
  mov	byte [file_location],2	;indicate temp file created
  mov	edi,file1_template
  test	byte [win_type],1	;check if template a or b
  jz	template_sav
  mov	edi,file2_template
template_sav:
  mov	esi,active_template
  mov	ecx,template_size
ts_10:
  cld
  rep	movsb
  pop	ebp
  ret


;-------
; a helper for other status line functions:
; simply init an empty line
;
clear_status_line:
  cld
  pusha
  mov edi,lib_buf
  mov al,SPACECHAR
  xor	ecx,ecx
  mov	cl,[term_columns]
  jecxz	csl_exit		;exit if terminal info not read yet
  add	ecx,30			;clear extra area for vt-100 sequences
csl_10:
  stosb
  dec	ecx
  jnz	csl_10
  mov al,0
  stosb
csl_exit:
  popa
  ret

;------------------------------------------------------
; inputs: 1. active window database
;         edx = 01000000 bold win   00000000 normal win
;
display_screen:
  mov	ebp,[crt_top_ptr]	;initialze to display first line
  mov	dh,[win_rows]		;dh=total rows
  mov	bh,0			;get starting virtual row of cursor
ds_1:
  mov	edi,lib_buf		;data storage area
  mov	bl,0			;get starting virtual column of cursor
  mov	ecx,[crt_left_column]	;scroll (file line) right count
  mov	dl,[win_columns]	;dl=total columns 
;
; registers: eax - scratch
;            ebx - bh=starting virtual row  bl=starting virtual column
;            ecx - scroll left countdown
;            edx - flags , total-rows , total-columns
;            esi - scratch
;            edi - stuff pointer in lib_buf
;            ebp - buffer pointer to editbuf (file data)
;
;            
  call	check_color
ds_2:
  cmp	ebp,[file_end_ptr]
  jb	ds_4			;jmp if not at end of file
;
; fill screen with blanks
;
ds_3:
  mov	al,20h			;get space
  mov	ecx,[crt_left_column]
ds_3a:
  call	stuff_char
  jnz	ds_3a			;loop till line filled
  mov	bl,0			;virtual column = 0
  call	display_line
  mov	edi,lib_buf		;restore data storage area
  inc	bh			;move to next row  
  mov	dl,[win_columns]	;dl=columns 
  dec	dh
  jnz	ds_3			;loop till done
  jmp	ds_exit			;exit if done
 
ds_4:
  call	check_color
  cmp	byte [ebp],0ah		;check if at end of line
  jne	ds_10			;jmp if current line has data
;
; fill current lib_buf with blanks
;
  mov	al,20h			;get space
ds_5:
  call	stuff_char
  jnz	ds_5			;loop till line filled
  jmp	ds_50
  
ds_10:
  mov	al,byte [ebp]		;get display char
  inc	ebp			;move to next char
  cmp	al,09h			;check for tab
  jne	ds_30			;jmp if not tab
;
; tab found, expand
;
  mov	al,20h			;get space
ds_12:
  call	stuff_char
  jz	ds_42			;jmp if at end of window
  test	bl,7
  jnz	ds_12
  jmp	ds_2

ds_30:
  cmp	al,7fh
  ja	ds_31			;jmp if in range 7f-ff
  cmp	al,20h			;check for special char
  jae	ds_40			;jmp if char ok
ds_31:
  mov	al,'.'			;substitute "."
ds_40:
  call	stuff_char
  jnz	ds_2			;jmp if not end of window


ds_42:
; edi now points to end of truncated line
; feed end of line into check_color incase it is in .asm comment and
; needs to change color back.
;
dsl_54:
  mov	al,byte [ebp]
  cmp	al,0ah
  je	dsl_54a
  cmp	ebp,[file_end_ptr]
  jae	dsl_55
  inc	ebp
  jmp	dsl_54
dsl_54a:
  call	check_color
dsl_55:

;
; end of window encountered
;
ds_50:
  mov	bl,0			;virtual column = 0
  call	display_line
  inc	bh			;move to next row  
  dec	dh
  jz	ds_exit			;exit if last row displayed
ds_52:
  cmp	ebp,[file_end_ptr]
  jae	ds_60			;jmp if at end of file
  cmp	byte [ebp],0ah
  je	ds_54			;jmp if at end of line
;
; move forward in editbuf to end of line
;
  inc	ebp
  jmp	ds_52

ds_54:
  inc	ebp
  jmp	ds_1			;go do another line
;
; move past EOL (0ah) in editbuf and loop for next line
;
ds_60:
  jmp	ds_1

ds_exit:
  call	color_cursor
  ret  

;---------------------------
display_line:
  push	ebx
  push	edx
  mov	ax,bx			;get cursor position
  add	ax,word [win_loc_col]	;compute physical crt column  
  call	move_cursor
  mov	edx,edi			;get lib_buf ptr
  sub	edx,lib_buf		;compute lenght of string
  mov	ecx,lib_buf		;get buffer to display
  mov eax, 0x4			; system call 0x4 (write)
  mov ebx, stdout		; file desc. is stdout
  int 0x80
  pop	edx
  pop	ebx
  ret

;---------------------------
; input: [edi] = stuff point
;          al  = character
;         ecx = scroll left count
;          bl = virtual column
;          dl = screen size
; output: if (zero flag) end of line reached
;         if (non zero flag) 
;             either character stored
;                 or ecx decremented if not at zero
;
stuff_char:
  jecxz	sc_active	;jmp if file data scrolled ok
  dec	ecx
  inc	bl		;bump column for tab expansion
  or	edi,edi		;clear zero flag
  ret
sc_active:
  stosb			;move char to lib_buf
  inc	bl
  dec	dl
  ret

;----------------------

;sets text color for blocks and windows, this includes
; highlighting for .asm comments also.
;  inputs: [showblock] - 0 if no blocks active
;          [ebp] - current display posn
;          [edi] - storage ptr
;          [blockbegin] - block start
;          [blockend] - block end
;          edx 0100,0000=use bold_text_color <- set by caller
;              0001,0000=current attr = text_color <- set by program
;              0002,0000=current attr = block_color <- set by program
;              0004,0000=asm highlight
;
check_color:
  cmp byte [showblock],0
  je isb_no_blk			;jmp if no block
  mov	esi,[editbuf_cursor_ptr]
  cmp	esi,[blockbegin]	;check if block grows up or down
  jb  growing_up
; block is normal, gowing down, display from blockbegin to cursor
  cmp	ebp,[blockbegin]
  jb	isb_no_blk		;jmp if display infront of block
  cmp	ebp,esi
  ja	isb_no_blk		;jmp if beyond block
  jmp	isb_in_blk
growing_up:			;growing up, display cursor to blockbegin
  cmp	ebp,esi
  jb	isb_no_blk		;jmp if display infront of block
  cmp	ebp,[blockbegin]
  ja	isb_no_blk		;jmp if beyond block
isb_in_blk:
  test	edx,00020000h		;check if block attr active
  jnz	isb_exita		;exit if in-block and attr set already
  and	edx,0ff00ffffh		;clear other attributes flags
  or	edx,00020000h
;
; move block attribute to buffer
;
  mov	eax,[high_text_color]
  call	move_color
isb_exita:
  jmp	isb_exit

isb_no_blk:
  test	edx,00020000h
  jz	isb_10			;jmp if not in blk and attr is not block
  and	edx,0ff00ffffh		;clear block active flag and text active flg
;
; block attribute not active and not inside block - asm check
;
isb_10:
  cmp	byte [show_asm],0
  je	isb_20			;jmp if asm comments not active
  mov	al,[ebp]		;get current char
  test	edx,00040000h		;check if comment active
  jz	isb_asm_no
;
; asm comments highlighted, wait for 0ah to disable
;
  cmp	al,0ah
  jne	isb_exit
  and	edx,0ff00ffffh		;clear block active flag and text active flg
  jmp	isb_20			;go set normal attr
;
; block not active, asm comments not active, check for ':'
;
isb_asm_no:
  cmp	al,[asm_comment_char]	;  ';'
  jne	isb_20			;go check for normal color state
  or	edx,00040000h		;set asm highlight active
  mov	eax,[asm_text_color]
  call	move_color
  jmp	isb_exit
isb_20:
  test	edx,00010000h		;check if text color attribute active
  jnz	isb_exit		;exit if text attribute set
  or	edx,00010000h		;set text attribute
;
; move normal attribute to buffer
;
  mov	eax,[bold_edit_color]
  cmp	byte [key_mode],1
  je	isb_24			;jmp if in command mode
  mov	eax,[bold_cmd_color]	;use edit color for non-command modes
isb_24:
  test	edx,01000000h
  jnz	isb_30			;jmp if bold text needed
  mov	eax,[norm_text_color]
isb_30:
  call	move_color
isb_exit:
  ret
;----------------------------
;
color_cursor:
  mov	eax,[cursor_color]	;get color (change to status_color)
  mov	bx,[crt_cursor]  
  mov	ecx,[editbuf_cursor_ptr]	;get ptr to data
  mov	cl,[ecx]		;get char under cursor
  cmp	cl,0ah
  je	cc_x05			;jmp   if 0ah
  cmp	cl,09h			;check if tab
  jne	cc_x10
cc_x05:
  mov	cl,' '
cc_x10:
  call	display_char_at	;display message
  ret  
;---------------------------
; input - eax = aaxxffbb  (aa-attribute ff-foreground  bb-background)
;   30-black 31-red 32-green 33-brown 34-blue 35-purple 36-cyan 37-grey
;   attributes 0-normal 1-bold 4-underscore 7-inverse
;   (see /src/lib/vttest for color chart) menu > 11 - 4 - 2
move_color:
  mov	byte [vcs1],al
  mov	byte [vcs2],ah
  rol	eax,8
  mov	byte [vcs_atr],al
  mov	esi,vt100_color_str
  cld
  call	move_asciiz
  ret

;------------------------------------------
; status line displayed if mouse inactive
;
keyboard_status_line:
  mov	ah,[status_line_row]
  mov	edi,lib_buf		;setup to move data
  call	color1
  mov eax,'CMD '		;setup to stuff CMD,INS,OVR status
  cmp byte [key_mode],0
  je  ssl_1			;jmp if command mode
  mov eax,"INS "
  cmp byte [insert_overtype],1		;check insert/overtype mode
  jz ssl_1
  mov eax,"OVR "
ssl_1:
  mov	dword [edi],eax
  add	edi,3

  call	color0
  mov	dword [edi],'mode'
  add	edi,4
    
  mov	ecx,2
  call	spaces

  call	color1
  mov	eax,[cursor_linenr]  
  call	stuff_decimal		;stuff line number
  call	color0
  mov	dword [edi],"line"
  add	edi,4

  mov	ecx,2
  call	spaces

  call	color1
  xor	eax,eax
  mov	al,[crt_cursor]		;get column
  sub	al,byte [win_loc_col]
  add	eax,[crt_left_column]
  call	stuff_decimal		;stuff display column
  call	color0
  mov	dword [edi],'col '
  add	edi,4
  
  mov	ecx,1
  call	spaces

  call	color1
  mov	esi,[editbuf_cursor_ptr]	;cursor pointer for editbuf
  mov  al,byte [esi]		;get character
  call	byte_to_hex
  mov	word [edi],ax
  add	edi,2
  call	color0  
  mov  dword [edi],'hex '
  add	edi,4

  mov	ecx,1
  call	spaces

  mov	dword [edi],'file'
  add	edi,4
  call	color1

  mov	al,'1'
  test	byte [win_type],1	;check if file1 or file2 active
  jz	ssl_08			;jmp if file1
  mov	al,'2'
ssl_08:
  stosb				;indicate file "1" or "2"

  mov	al,' '
  stosb				;put space after filex

  mov	al,byte [file_change]
  stosb				;stuff change flag "*" or "space"
  
  call	color0  
  mov esi,file_path		;get pointer to filename
;
; find end of filename, (setup to show filename without full path)
;
ssl_09:
  lodsb
  cmp	al,0
  jne	ssl_09			;loop till end of filename
;
; move back to beginning of filename
;
ssl_09a:
  dec	esi
  cmp	byte [esi-1],'/'
  je	ssl_10			;jmp if at beginning of name
  cmp	esi,file_path
  jne	ssl_09a
;
; move filename without full path
;
ssl_10:
  lodsb
  or al,al
  jz ssl_12			;jmp if end of name
  stosb
  jmp	ssl_10			;loop till file name moved
ssl_12:

  mov	ecx,3
  call	spaces
  
  mov	dword [edi],' F1='
  add	edi,4
  mov	dword [edi],'help'
  add	edi,4
  mov	byte [edi],0		;force status line length
  call	truncate_status_line
  call	write_status_line
  ret

;--------------------------------------------
;  input:  edi = end of status line
;
write_status_line:
  mov	ah,[status_line_row]
  mov	al,1
  call	move_cursor		;position cursor

  mov	edx,edi
  sub	edx,lib_buf		;compute length of line
  mov	ecx,lib_buf
  mov eax, 0x4			; system call 0x4 (write)
  mov ebx, stdout		; file desc. is stdout
  int 0x80
  
  mov	eax,[crt_cursor]
  call	move_cursor
  ret
  
;--------------------------------------
; now truncate status line if too long
;  output: edi = end pointer
;
truncate_status_line:
  mov	esi,lib_buf		;start of status line
  xor	ecx,ecx
  mov	cl,[term_columns]	;ecx=length of status line
ssl_50:
  lodsb
  cmp	al,1bh			;check for color code
  jne	ssl_51			;jmp if not color
  add	esi,13			;move past color code
  jmp	ssl_50	
ssl_51:
  cmp	al,0
  jne	ssl_52
  mov	edi,esi			;fill remainder of line with spaces
  mov	al,' '
ssl_51a:
  stosb
  loop	ssl_51a
  jmp	ssl_55
ssl_52:
  loop	ssl_50			;loop till end of display
;
; esi now points to end of truncated/filled status line
; scan rest of line for color change codes
; The color codes need to be appended to keep display color correct
;
  mov	edi,esi
ssl_54:
  lodsb				;
  cmp	al,0
  je	ssl_55
  cmp	al,1bh
  jne	ssl_54
  stosb
  mov	ecx,13
  rep	movsb
  jmp	ssl_54  
ssl_55:
  ret
;------------------------

; input: edi = storage pointer
color0:
  mov	eax,[status_color]
  call	move_color
  ret

; input: edi = storage ptr
color1:
  mov	eax,[status_color1]
  call	move_color
  ret

; input: ecx=number of spaces needed
;        edi=storage pointer
spaces:
  mov	al,' '
  stosb
  loop	spaces
  ret  
;--------------------------------------
; input: eax=binary
;output: edi=data ptr
;        ecx=length
stuff_decimal:
  push	edi
  mov	edi,bakpath+8		;temp buffer
  mov	byte [edi],0		;put zero at end of data
  call	IntegerToAscii
  mov	esi,edi			;get string begin
  mov	ecx,bakpath+8		;get end of string
  sub	ecx,edi			;compute length
  pop	edi			;get storage point
  inc	esi			;move to data
  rep	movsb
  ret
    
;------------------
; make status line buttons
;  input:  esi = control table pointer
;
make_buttons:
  cld
  mov	edi,lib_buf
mb_10:
  add	esi,4		;skip over process
;
; check if name present
;
mb_12:
  lodsb
  cmp	al,8
  jb	mb_20		;jmp if end of name found
  stosb
  jmp	mb_12
;
; check if end of table
;
mb_20:
  cmp	al,0
  je	mb_40
  call	mouse_spaces
  jmp	mb_10		;go do next button
;
; end of table found
;
mb_40:
  mov	al,40
  call	mouse_spaces
  mov	al,0
  stosb				;put zero at end of status line
  call	truncate_status_line
  call	write_status_line
  ret    
;---------------
mouse_spaces:
  push	esi
  xor	ecx,ecx
  mov	cl,al
  mov	eax,[bold_edit_color]
  cmp	byte [key_mode],1
  je	ms_11			;jmp if in command mode
  mov	eax,[bold_cmd_color]
ms_11:
  call	move_color
  mov	al,' '
  rep	stosb
  mov	eax,[status_color1]
  call	 move_color
  pop	esi
  ret

;-------------------------------
; input: eax = color (aa??ffbb) attribute,foreground,background
;        bl = column
;        bh = row
;       ecx = message ptr (asciiz)
;
display_color_at:
  push	ecx
  push	ebx
  call	set_color
  pop	eax
  call	move_cursor
  pop	ecx
  call	display_asciiz
  ret
  
;-------------------------------
; display_asciiz - output string
;  input: ecx - ponter to string
;
	%define stdout 0x1
	%define stderr 0x2

display_asciiz:
  xor edx, edx
.count_again:	
  cmp [ecx + edx], byte 0x0
  je .done_count
  inc edx
  jmp .count_again
.done_count:	
  mov eax, 0x4			; system call 0x4 (write)
  mov ebx, stdout			; file desc. is stdout
  int 0x80
  ret
;-------------------------------
; input: eax = color (aa??ffbb) attribute,foreground,background
;        bl = column
;        bh = row
;        cl = ascii char
;
display_char_at:
  push	ecx
  push	ebx
  call	set_color
  pop	eax
  call	move_cursor
  pop	ecx

  cmp	cl,20h
  jae	dca_2			;jmp if possible alpha
  mov	cl,'?'
dca_2:
  cmp	cl,7eh
  jbe	dca_4			;jmp if legal alpha
  mov	cl,'?'
dca_4:
  mov	byte [char_out],cl
  mov	ecx,char_out		;display data
  mov eax, 0x4			; system call 0x4 (write)
  mov ebx, stdout		; file desc. is stdout
  mov	edx,1			;write one char
  int 0x80

  ret
  
;--------------------------
; input - eax = aaxxffbb  (aa-attribute ff-foreground  bb-background)
;   30-black 31-red 32-green 33-brown 34-blue 35-purple 36-cyan 37-grey
;   attributes 0-normal 1-bold 4-underscore 7-inverse
;   (see /src/lib/vttest for color chart) menu > 11 - 4 - 2
;
set_color:
  mov	byte [vcs1],al
  mov	byte [vcs2],ah
  rol	eax,8
  mov	byte [vcs_atr],al
  mov	ecx,vt100_color_str
  call	display_asciiz
  ret  
;--------------------------
; input al = column (1-xx)
;       ah = row    (1-xx)
;

move_cursor:
  push	edi
  push	eax
  mov	word [vt_row],'00'
  mov	word [vt_column],'00'
  mov	edi,vt_column+2
  call	quick_ascii
  pop	eax
  xchg	ah,al
  mov	edi,vt_row+2
  call	quick_ascii
  mov	ecx,vt100_cursor
  mov	eax,4
  mov	edx,vt100_end - vt100_cursor
  mov	ebx,1		;stdout
  int	byte byte 80h
  pop	edi
  ret
;-------------------------------------
; input: al=ascii
;        edi=stuff end point
quick_ascii:
  push	byte 10
  pop	ecx
  and	eax,0ffh		;isolate al
to_entry:
  xor	edx,edx
  div	ecx
  or	dl,30h
  mov	byte [edi],dl
  dec	edi  
  or	eax,eax
  jnz	to_entry
  ret

  [section .data]
vt100_cursor:
  db	1bh,'['
vt_row:
  db	'000'		;row
  db	';'
vt_column:
  db	'000'		;column
  db	'H',0
vt100_end:
  
 [section .text]
  
;
;------------------------
; input: none
;

cmd_msg	db	"CMD",0
ins_msg	db	"INS",0
ovr_msg	db	"OVR",0
mode_msg db	'mode  ',0

display_status_line:
  cld
  call	clear_status_line

  mov	ecx,[special_status_msg_ptr]	;check if special msg needed
  jecxz dsl_05			;jmp if no special messages to display
  mov	eax,[status_color2]	;get color (change to status_color)
  mov	bh,[status_line_row]
  mov	bl,1			;column 1
  call	display_color_at	;display message
  mov	dword [special_status_msg_ptr],0
  jmp	short dsl_exit
dsl_05:
  cmp	byte [mouse_mode],0
  jne	dsl_10
  call	keyboard_status_line
  jmp	dsl_exit
dsl_10:
  call	get_mouse_table
  call	make_buttons
dsl_exit:
  ret
;------------------------------------------------------------------
memory_setup:
  call	memory_init
  inc	eax			;start at second location
  mov	[editbuf_ptr],eax
  mov	[crt_top_ptr_a],eax
  mov	[editbuf_cursor_line_ptr_a],eax
  mov	[editbuf_cursor_ptr_a],eax
  mov	[crt_top_ptr_b],eax
  mov	[editbuf_cursor_line_ptr_b],eax
  mov	[editbuf_cursor_ptr_b],eax
  mov	[file_end_ptr],eax
  mov	[editbuf_cursor_ptr],eax
  mov	[editbuf_cursor_line_ptr],eax
  mov	[crt_top_ptr],eax
  add	eax,max
  mov	ebx,eax
  mov	eax,45
  int	byte 80h	;allocate big block
  mov	[editbuf_end],eax
  ret
;----------------------------------------------------------------
; OUTPUT
;    eax = start adr for next allocation using brk
;    ebx = first start address found by call to
;          memory_init or zero if this is first
;          call to memory_init

memory_init:
  xor	ebx,ebx
  mov	eax,45
  int	byte 80h
  mov	ebx,[alloc_top]
  or	ebx,ebx
  jnz	mi_exit
  mov	[alloc_top],eax
mi_exit:
  or	eax,eax		;set sign
  ret

;-------------------------------------------------
  [section .data]
alloc_top: dd 0     
  [section .text]

;----------------------------------
%include "signal.inc"
%include "launch.inc"
%include "file.inc"
%include "proc.inc"

  [section .data]

; (#10#) database - err msg + messages *************************

; CONSTANT DATA AREA
;

jump_prompt_msg db	'jump to: tags(a,b,c,d) line(l) start(s) end(e) ? ',0
get_prompt_msg  db	'get:  buffer(b)  file(f) ? ',0
msg_quit:	db	'Abort, Exit, Init, Update, Write, <esc>',0

filename db 'FILENAME:',0
block_msg db 'enter ESC for last block or Filename: ',0
asklineno db 'GO LINE:',0

file1_entry_msg db	'ESC or name for'
file1_prompt	db	' FILE1 > ',0
file2_entry_msg db	'ESC or name for'
file2_prompt	db	' FILE2 > ',0
filex_entry_msg db	'enter name for new file  or "esc" : ',0
filew_entry_msg db	'Enter ESC or name for saving current file:',0
modified_msg	db	'  (is modified)'
crlf_msg       	db	0ah,0
save_msg	db	' Save? (y/n) > ',0
noname_msg	db	' (un-named) ',0

overwrite_file_msg db	'Existing file found, overwrite? (y/n): ',0

tag_msg		db	'set tag(a,b,c,d?)',0
;

; (#11#) database - menu tables ********************************

mouse_tables:
  dd	m1_menu
  dd	m2_quit
  dd	m3_window
  dd	m4_jump
  dd	m5_misc
  dd	m6_edit
  dd	m7_find
  dd	m8_block
  dd	m9_function
;------------------------------------------
m1_menu:
  dd	0	;null process
; db	null	;no name
  db	3	;end of name, 1 space
;
  dd	m2mode	;Quit menu
  db	'Quit'
  db	1	;space
;
  dd	m3mode
  db	'Window';window menu
  db	1	;end of table
;
  dd	m4mode	;jump menu
  db	'Jump'
  db	1
;
  dd	m5mode	;misc menu
  db	'Misc'
  db	1
;
  dd	m6mode	;edit menu
  db	'edit(Ins)'
  db	1
;
  dd	m7mode	;find menu
  db	'Find'
  db	1
;
  dd	m8mode	;Block
  db	'Block'
  db	1
;
  dd	m9mode	;Setup
  db	'Setup'
  db	1
;
  dd	m10mode	;help
  db	'Help'
  db	4
;
  dd	KeyPgUp		;pgup
  db	'PGUP'
  db	1
;
  dd	KeyPgDn		;pgdn
  db	'PGDN'
  db	0
;---------------------------  
  
m2_quit:		;control table
  dd	0	;null process
; db	null	;no name
  db	3	;end of name, 1 space
;
  dd	m1mode
  db	'< back'
  db	2
;  
  dd	m_abort		;abort (deZert)
  db	'(Z)abort'	;QA
  db	2
;
  dd	m_exit
  db	'Exit'		;QE
  db	2
;
  dd	m_newfile
  db	'New-file'	;QI
  db	2
;
  dd	m_update
  db	'Update'	;QU
  db	2 
;
  dd	m_write
  db	'saVe-as'	;QW
  db	0		;end of table
  
;-----------------------
m3_window:		;control table
  dd	0	;null process
; db	null	;no name
  db	3	;end of name, 1 space
;
  dd	m1mode
  db	'<-back'
  db	2
;
  dd	m3mode	;window
  db	'Window-split'
  db	2
;
  dd	m3_other
  db	'Other_window'
  db	0

;-----------------------
m4_jump:		;control table
  dd	0	;null process
; db	null	;no name
  db	1	;end of name, 1 space
;
  dd	m1mode
  db	'<back'
  db	1
;
  dd	m4_line
  db	'Line'
  db	1
;
  dd	m4_top
  db	'top'
  db	1
;
  dd	m4_eof
  db	'eof'
  db	2
;
  dd	m4_tags1
  db	'tag a'
  db	1
;
  dd	m4_tags2
  db	'tag b'
  db	1
;
  dd	m4_tags3
  db	'tag c'
  db	1
;
  dd	m4_tags4
  dB	'tag d'
  db	2
; 
  dd	m4_tag1
  db	'go a'
  db	1
;
  dd	m4_tag2
  db	'go b'
  db	1
;
  dd	m4_tag3
  db	'go c'
  db	1
;
  dd	m4_tag4
  db	'go d'
  db	2
;
  dd	KeyPgUp
  db	'pgup'
  db	1
;
  dd	KeyPgDn
  db	'pgdn'
  db	0
;-----------------------
m5_misc:		;control table
  dd	0	;null process
; db	null	;no name
  db	1	;end of name, 1 space
;
  dd	m1mode
  db	'<-back'
  db	1
;
  dd	m5_paragraph
  db	'Paragraph'
  db	1
;
  dd	m5_calc
  db	'Calculator'
  db	1
;
  dd	f_make
  db	'F3-make'
  db	1
;
  dd	f_bug
  db	'F4-debug'
  db	1
;
  dd	key_f5
  db	'F5'
  db	1
  
;
  dd	key_f6
  db	'F6'
  db	1
  
  dd	key_f7
  db	'F7'
  db	1
  
  dd	key_f8
  db	'F8'
  db	1
  
  dd	key_f9
  db	'F9'
  db	1
  
  dd	key_fa
  db	'F10'
  db	1
  
  dd	key_fb
  db	'F11'
  db	1
  
  dd	key_fc
  db	'F12'
  db	0
  
;-----------------------
m6_edit:		;control table
  dd	0	;null process
; db	null	;no name
  db	3	;end of name, 1 space
;
  dd	m1mode
  db	'<-back'
  db	2
;
  dd	m6_insert
  db	'Insert mode'
  db	2
;
  dd	m6_overtype
  db	'Xovertype mode'
  db	2
;
  dd	m6_hex
  db	'hex edit'
  db	0
  
;-----------------------
m7_find:		;control table
  dd	0	;null process
; db	null	;no name
  db	3	;end of name, 1 space
;
  dd	m1mode
  db	'<-back'
  db	2
;
  dd	find_forward		;key routine used so again works
  db	'<+>forward find'
  db	2
;
  dd	find_back		;key routine used so again works
  db	'bacK find'
  db	2
;
  dd	m7_replace
  db	'Replace'
  db	0
  
;-----------------------
m8_block:		;control table
  dd	0	;null process
; db	null	;no name
  db	3	;end of name, 1 space
;
  dd	m1mode
  db	'<-back'
  db	2
;
  dd	m8_markblock
  db	'Block begin/end'
  db	2
;
  dd	m8_dblock
  db	'block Delete'
  db	2
;
  dd	m8_getblock
  db	'Get block'
  db	2
;
  dd	m8_get
  db	'Yank (get/insert) file'
  db	0


;-----------------------
m9_function:	;control table
  dd	0	;null process
; db	null	;no name
  db	3	;end of name, 1 space
;
  dd	m1mode	;
  db	'<-back'
  db	1
;
  dd	KeyHelp
  db	'F1 help'
  db	1
;
  dd	m1mode
  db	'F2 todo'
  db	1
;
  dd	f_make
  db	'F3 make'
  db	1
;
  dd	f_bug
  db	'F4 debug'
  db	1
;
  dd	key_f5
  db	'f5 spell'
  db	1
;
  dd	key_f6
  db	'F6 compare'
  db	1
;
  dd	key_f7
  db	'F7 print'
  db	1
;
  dd	key_fa
  db	'F10 exit'
  db	0
;
;-----------------------

; (#12#) database - key tables *********************************

 [section .data]

; the keystring_tbl is seached after user presses a key.  Each
; key press can generate up to 5 bytes of information and this
; table is searched to find what key it is.  The match location
; is used as an index into the next set of tables which point
; at the process to call.

keystring_tbl:
  db 1bh,0			;1 esc
  db 1bh,5bh,31h,31h,7eh,0	;2 f1
  db 1bh,5bh,31h,32h,7eh,0	;3 f2
  db 1bh,5bh,31h,33h,7eh,0	;4 f3
  db 1bh,5bh,31h,34h,7eh,0	;5 f4
  db 1bh,5bh,31h,35h,7eh,0	;6 f5
  db 1bh,5bh,31h,37h,7eh,0	;7 f6
  db 1bh,5bh,31h,38h,7eh,0	;8 f7
  db 1bh,5bh,31h,39h,7eh,0	;9 f8
  db 1bh,5bh,32h,30h,7eh,0	;10 f9
  db 1bh,5bh,32h,31h,7eh,0	;11 f10
  db 1bh,5bh,32h,33h,7eh,0	;12 f11
  db 1bh,5bh,32h,34h,7eh,0	;13 f12
  db 1bh,5bh,48h,0		;14 pad_home
  db 1bh,5bh,41h,0		;15 pad_up
  db 1bh,5bh,35h,7eh,0		;16 pad_pgup
  db 1bh,5bh,44h,0		;17 pad_left
  db 1bh,5bh,43h,0		;18 pad_right
  db 1bh,5bh,46h,0		;19 pad_end
  db 1bh,5bh,42h,0		;20 pad_down
  db 1bh,5bh,36h,7eh,0		;21 pad_pgdn
  db 1bh,5bh,32h,7eh,0		;22 pad_ins
  db 1bh,5bh,33h,7eh,0		;23 pad_del
  db 7fh,0			;24 backspace
  db 1ah,0			;25 ctrl_z
  db 01h,0			;26 ctrl_a
  db 60h,0			;27 lquote
  db 7eh,0			;28 ~
  db 09h,0			;29 tab
  db 40h,0			;30 @
  db 23h,0			;31 #
  db 24h,0			;32 $
  db 25h,0			;33 %
  db 5eh,0			;34 ^
  db 26h,0			;35 &
  db 2ah,0			;36 *
  db 28h,0			;37 (
  db 29h,0			;38 )
  db 5fh,0			;39 _ underscore
  db 2bh,0			;40 +
  db 31h,0			;41 1
  db 32h,0			;42 2
  db 33h,0			;43 3
  db 34h,0			;44 4
  db 35h,0			;45 5
  db 36h,0			;46 6
  db 37h,0			;47 7
  db 38h,0			;48 8
  db 39h,0			;49 9
  db 30h,0			;50 0
  db 2dh,0			;51 - dash
  db 3dh,0			;52 =
  db 'q',0			;53 q
  db "w",0			;54 w
  db "e",0			;55 e
  db "r",0			;56 r
  db "t",0			;57 t
  db "y",0			;58 y
  db "u",0			;59 u
  db "i",0			;60 i
  db "o",0			;61 o
  db "p",0			;62 p
  db "[",0			;63 [
  db "]",0			;64 ]
  db "\",0			;65 \ nasm -can't accept \ at end of line
  db 'Q',0		;66
  db 'W',0		;67
  db 'E',0		;68
  db 'R',0		;69
  db 'T',0		;70
  db 'Y',0		;71
  db 'U',0		;72
  db 'I',0		;73
  db 'O',0		;74
  db 'P',0		;75
  db '{',0		;76
  db '}',0		;77
  db '|',0		;78
  db 'a',0		;79
  db 's',0		;80
  db 'd',0		;81
  db 'f',0		;82
  db 'g',0		;83
  db 'h',0		;84
  db 'j',0		;85
  db 'k',0		;86
  db 'l',0		;87
  db ';',0		;88
  db 27h,0		;89 single quote 
  db 0dh,0		;90  enter 
  db 'A',0		;91
  db 'S',0		;92
  db 'D',0		;93
  db 'F',0		;94
  db 'G',0		;95
  db 'H',0		;96
  db 'J',0		;97
  db 'K',0		;98
  db 'L',0		;99
  db ':',0		;100
  db 22h,0		;101 double quote
  db 'z',0		;102
  db 'x',0			;103
  db 'c',0			;104
  db 'v',0			;105
  db 'b',0			;106
  db 'n',0			;107
  db 'm',0			;108
  db ',',0			;109
  db '.',0			;110
  db '/',0			;111
  db 'Z',0			;112
  db 'X',0			;113
  db 'C',0			;114
  db 'V',0			;115
  db 'B',0			;116
  db 'N',0			;117
  db 'M',0			;118
  db '<',0			;119
  db '>',0			;120
  db '?',0			;121
  db ' ',0			;122 space
; the above are vt100, next is xterm unique keys
  db 1bh,4fh,50h,0		;123 F1
  db 1bh,4fh,51h,0		;123 F2
  db 1bh,4fh,52h,0		;123 F3
  db 1bh,4fh,53h,0		;123 F4
;the above are xterm unique, next is linux-console unique
  db 1bh,5bh,5bh,41h,0		;127 F1
  db 1bh,5bh,5bh,42h,0		;128 f2
  db 1bh,5bh,5bh,43h,0		;129 f3
  db 1bh,5bh,5bh,44h,0		;130 f4
  db 1bh,5bh,5bh,45h,0		;131 f5
  db 0ah,0			;132 enter
  db 03h,0			;133 ctrl-c
  db 18h,0			;134 ctrl-x
  db 15h,0                      ;135 ctrl-u
  db 12h,0			;136 ctrl-r
  db 21h,0			;137 explamation point
  db 1bh,5bh,31h,7eh,0		;138 home (non-keypad)
  db 1bh,5bh,34h,7eh,0		;139 end (non-keypad)
  db 08,0			;140 backspace
  db 1bh,4fh,78h,0		;141 pad_up
  db 1bh,4fh,79h,0		;142 pad_pgup
  db 1bh,4fh,74h,0		;143 pad_left
  db 1bh,4fh,76h,0		;144 pad_right
  db 1bh,4fh,71h,0		;145 pad_end
  db 1bh,4fh,72h,0		;146 pad_down
  db 1bh,4fh,73h,0		;147 pad_pgdn
  db 1bh,4fh,70h,0		;148 pad_ins
  db 1bh,4fh,6eh,0		;149 pad_del
  db 1bh,4fh,77h,0		;150 pad_home
  db 1bh,4fh,42h,0		;151 pad down
  db 1bh,4fh,41h,0		;152 pad up
  db 1bh,4fh,43h,0		;153 pad right
  db 1bh,4fh,44h,0		;154 pad left
  db 1bh,4fh,48h,0		;155 pad home
  db 1bh,4fh,46h,0		;156 pad end
  db 0		;end of table
;
;
; command mode uses this table to convert keystrokes into actions
;
cmd_index_tbl:
  db 00	;'esc',0	;1 -
  db 59	;'f1',0		;2 - help
  db 47	;'f2',0		;3 - main menu
  db 50	;'f3',0		;4 - make/compiler
  db 51	;'f4',0		;5 - debugger
  db 79	;'f5',0		;6 - user defined
  db 80	;'f6',0		;7 - user def
  db 81	;'f7',0		;8
  db 82	;'f8',0		;9
  db 83	;'f9',0		;10
  db 84	;'f10',0	;11
  db 85	;'f11',0	;12
  db 86	;'f12',0	;13
  db 10	;'home',0	;14 - KeyHome
  db 11	;'up',0		;15 - KeyUp
  db 12	;'pgup',0	;16 - KeyPgUp
  db 13	;'left',0	;17 - KeyLeft
  db 14	;'right',0	;18 - KeyRight
  db 15	;'end',0	;19 - KeyEnd
  db 16	;'down',0	;20 - KeyDown
  db 17	;'pgdn',0	;21 - KeyPgDn
  db 18	;'ins',0	;22 - KeyIns
  db 19	;'del',0	;23 - KeyDel
  db 30	;'backspace',0	;24 - KeyDell
  db 31	;'ctrl_z',0	;25 - delete_line
  db 34	;'ctrl_a',0	;26 - delete_right
  db 00	;'lquote',0	;27
  db 00	;'~',0		;28
  db 07	;'tab',0	;29 tab
  db 00	;'@',0		;30
  db 00	;'#',0		;31
  db 00	;'$',0		;32
  db 00	;'%',0		;33
  db 00	;'^',0		;34
  db 00	;'&',0		;35
  db 00	;'*',0		;36
  db 00	;'(',0		;37
  db 00	;')',0		;38
  db 00	;'_',0		;39
  db 20	;'+',0		;40 m_find_fwd
  db 00	;'1',0		;41
  db 00	;'2',0		;42
  db 00	;'3',0		;43
  db 00	;'4',0		;44
  db 00	;'5',0		;45
  db 00	;'6',0		;46
  db 00	;'7',0		;47
  db 00	;'8',0		;48
  db 00	;'9',0		;49
  db 00	;'0',0		;50
  db 69	;'-',0		;51 -  find backwards
  db 00	;'=',0		;52
  db 02	;'q',0		;53 - exit menu + calculator? quit_menu
  db 01	;'w',0		;54 - toggle window state
  db 06	;'e',0		;55 - execute macro
  db 78	;'r',0		;56 - find & replace
  db 71	;'t',0		;57 - set tag
  db 00	;'y',0		;58
  db 00	;'u',0		;59
  db 74	;'i',0		;60 - enter exchange mode
  db 07	;'o',0		;61 - other window
  db 62	;'p',0		;62 - paragraph
  db 00	;'[',0		;63
  db 00	;']',0		;64
  db 00	;'\',0		;65
  db 39	;'Q',0		;66
  db 42	;'W',0		;67
  db 03	;'E',0		;68
  db 21	;'R',0		;69 find and replace
  db 41	;'T',0		;70
  db 44	;'Y',0		;71
  db 04	;'U',0		;72
  db 29	;'I',0		;73
  db 37	;'O',0		;74
  db 38	;'P',0		;75
  db 00	;'{',0		;76
  db 00	;'}',0		;77
  db 00	;'|',0		;78
  db 70	;'a',0		;79 - again -repeat last find
  db 00	;'s',0		;80
  db 76	;'d',0		;81 - delete block
  db 68	;'f',0		;82 - find forward- find
  db 77	;'g',0		;83 -  (insert file) - 
  db 59	;'h',0		;84 - KeyHelp
  db 67	;'j',0		;85 - jump menu
  db 00	;'k',0		;86
  db 00	;'l',0		;87
  db 00	;';',0		;88
  db 00	;'rquote',0	;89 single quote 
  db 00	;'enter',0	;90  enter 
  db 00	;'A',0		;91
  db 40	;'S',0		;92
  db 26	;'D',0		;93
  db 22	;'F',0		;94
  db 27	;'G',0		;95
  db 28	;'H',0		;96
  db 32	;'J',0		;97
  db 23	;'K',0		;98 m_find_back
  db 32	;'L',0		;99
  db 00	;':',0		;100
  db 00	;double-quote,0	;101 double quote
  db 00	;'z',0		;102
  db 73	;'x',0		;103 - enter xchange mode
  db 60	;'c',0		;104 - calculator
  db 00	;'v',0		;105
  db 48	;'b',0		;106 - mark_block - mark buffer
  db 00	;'n',0		;107
  db 05	;'m',0		;108 - macro record
  db 00	;'comma',0	;109
  db 00	;'period',0	;110
  db 00	;'/',0		;111
  db 45	;'Z',0		;112
  db 43	;'X',0		;113
  db 25	;'C',0		;114
  db 08	;'V',0		;115
  db 24	;'B',0		;116
  db 09	;'N',0		;117
  db 36	;'M',0		;118
  db 46	;'<',0		;119
  db 00	;'>',0		;120
  db 00	;'?',0		;121
  db 46	;'space',0	;122 space - main menu 
; the above are vt100, next is xterm unique keys
  db 59	;'f1',0		;123 F1 - help
  db 47	;'f2',0		;124 F2
  db 50	;'f3',0		;125 F3
  db 51	;'f4',0		;126 F4
;the above are xterm unique, next is linux-console unique
  db 59	;'f1',0		;127 F1
  db 47	;'f2',0		;128 f2
  db 50	;'f3',0		;129 f3
  db 51	;'f4',0		;130 f4
  db 79	;'f5',0		;131 f5
;appended keys
  db 00	;'enter',0	;132 enter
  db 00 ;'ctrl-c',0	;133 ctrl-c
  db 35 ;'ctrl-x',0	;134 ctrl-x
  db 49 ; ctrl-u	;135 ctrl-u
  db 61 ; ctrl-r	;136 ctrl-r hex in
  db 00 ; explamation   ;137 explamation
  db 10 ; home		;138
  db 15	; end  		;139
  db 30 ; backspace	;140 08h=backspace
  db 11	;'up',0		;141 - KeyUp
  db 12	;'pgup',0	;142 - KeyPgUp
  db 13	;'left',0	;143 - KeyLeft
  db 14	;'right',0	;144 - KeyRight
  db 15	;'end',0	;145 - KeyEnd
  db 16	;'down',0	;146 - KeyDown
  db 17	;'pgdn',0	;147 - KeyPgDn
  db 18	;'ins',0	;148 - KeyIns
  db 19	;'del',0	;149 - KeyDel
  db 10	;'home',0	;150 - KeyHome
  db 16 ;               ;151 - KeyDown
  db 11 ;               ;152 - KeyUP
  db 14 ;		;153 - KeyRight
  db 13 ;		;154 - KeyLeft
  db 10 ;		;155 - home
  db 15 ;		;156 - end
;
; edit mode uses this table to convert key presses into actions.
; each possible key press has associated action.  Raw data can be
;  processed with control-r command.
;  
edit_index_tbl:
  db 72	;'esc',0	;1
  db 59	;'f1',0		;2
  db 47	;'f2',0		;3
  db 50	;'f3',0		;4
  db 51	;'f4',0		;5
  db 79	;'f5',0		;6
  db 60	;'f6',0		;7
  db 81	;'f7',0		;8
  db 82	;'f8',0		;9
  db 83	;'f9',0		;10
  db 84	;'f10',0	;11
  db 85	;'f11',0	;12
  db 86	;'f12',0	;13
  db 10	;'home',0	;14 - KeyHome
  db 11	;'up',0		;15 - KeyUp
  db 12	;'pgup',0	;16 - KeyPgUp
  db 13	;'left',0	;17 - KeyLeft
  db 14	;'right',0	;18 - KeyRight
  db 15	;'end',0	;19 - KeyEnd
  db 16	;'down',0	;20 - KeyDown
  db 17	;'pgdn',0	;21 - KeyPgDn
  db 18	;'ins',0	;22 - KeyIns
  db 19	;'del',0	;23 - KeyDel
  db 30	;'backspace',0	;24 - KeyDell
  db 31	;'ctrl_z',0	;25 - delete_line
  db 34	;'ctrl_a',0	;26 - delete_right
  db 63	;'lquote',0	;27
  db 63	;'~',0		;28
  db 63	;'tab',0	;29 tab
  db 63	;'@',0		;30
  db 63	;'#',0		;31
  db 63	;'$',0		;32
  db 63	;'%',0		;33
  db 63	;'^',0		;34
  db 63	;'&',0		;35
  db 63	;'*',0		;36
  db 63	;'(',0		;37
  db 63	;')',0		;38
  db 63	;'_',0		;39
  db 63	;'+',0		;40
  db 63	;'1',0		;41
  db 63	;'2',0		;42
  db 63	;'3',0		;43
  db 63	;'4',0		;44
  db 63	;'5',0		;45
  db 63	;'6',0		;46
  db 63	;'7',0		;47
  db 63	;'8',0		;48
  db 63	;'9',0		;49
  db 63	;'0',0		;50
  db 63	;'-',0		;51
  db 63	;'=',0		;52
  db 63	;'q',0		;53
  db 63	;'w',0		;54
  db 63	;'e',0		;55
  db 63	;'r',0		;56
  db 63	;'t',0		;57
  db 63	;'y',0		;58
  db 63	;'u',0		;59
  db 63	;'i',0		;60
  db 63	;'o',0		;61
  db 63	;'p',0		;62
  db 63	;'[',0		;63
  db 63	;']',0		;64
  db 63	;'\',0		;65
  db 63	;'Q',0		;66
  db 63	;'W',0		;67
  db 63	;'E',0		;68
  db 63	;'R',0		;69
  db 63	;'T',0		;70
  db 63	;'Y',0		;71
  db 63	;'U',0		;72
  db 63	;'I',0		;73
  db 63	;'O',0		;74
  db 63	;'P',0		;75
  db 63	;'{',0		;76
  db 63	;'}',0		;77
  db 63	;'|',0		;78
  db 63	;'a',0		;79
  db 63	;'s',0		;80
  db 63	;'d',0		;81
  db 63	;'f',0		;82
  db 63	;'g',0		;83
  db 63	;'h',0		;84
  db 63	;'j',0		;85
  db 63	;'k',0		;86
  db 63	;'l',0		;87
  db 63	;';',0		;88
  db 63	;'rquote',0	;89 single quote 
  db 63	;'enter',0	;90  enter 
  db 63	;'A',0		;91
  db 63	;'S',0		;92
  db 63	;'D',0		;93
  db 63	;'F',0		;94
  db 63	;'G',0		;95
  db 63	;'H',0		;96
  db 63	;'J',0		;97
  db 63	;'K',0		;98
  db 63	;'L',0		;99
  db 63	;':',0		;100
  db 63	;double-quote,0	;101 double quote
  db 63	;'z',0		;102
  db 63	;'x',0		;103
  db 63	;'c',0		;104
  db 63	;'v',0		;105
  db 63	;'b',0		;106
  db 63	;'n',0		;107
  db 63	;'m',0		;108
  db 63	;'comma',0	;109
  db 63	;'period',0	;110
  db 63	;'/',0		;111
  db 63	;'Z',0		;112
  db 63	;'X',0		;113
  db 63	;'C',0		;114
  db 63	;'V',0		;115
  db 63	;'B',0		;116
  db 63	;'N',0		;117
  db 63	;'M',0		;118
  db 63	;'<',0		;119
  db 63	;'>',0		;120
  db 63	;'?',0		;121
  db 63	;'space',0	;122 space
; the above are vt100, next is xterm unique keys
  db 59	;'f1',0		;123 F1 - help
  db 47	;'f2',0		;124 F2
  db 50	;'f3',0		;125 F3
  db 51	;'f4',0		;126 F4
;the above are xterm unique, next is linux-console unique
  db 59	;'f1',0		;127 F1
  db 47	;'f2',0		;128 f2
  db 50	;'f3',0		;129 f3
  db 51	;'f4',0		;130 f4
  db 79	;'f5',0		;131 f5
;appended keys  
  db 63	;'enter',0	;132 enteri
  db 00 ;'ctrl-c',0	;133 ctrl-c
  db 35 ;'ctrl-x',0	;134 ctrl-x
  db 49 ; ctrl-u	;135 ctrl-u
  db 61 ; ctrl-r	;136 ctrl-r  -hex in
  db 63 ; explamation   ;137 explamation  
  db 10 ; home		;138
  db 15	; end  		;139
  db 30 ; backspace     ;140
  db 11	;'up',0		;141 - KeyUp
  db 12	;'pgup',0	;142 - KeyPgUp
  db 13	;'left',0	;143 - KeyLeft
  db 14	;'right',0	;144 - KeyRight
  db 15	;'end',0	;145 - KeyEnd
  db 16	;'down',0	;146 - KeyDown
  db 17	;'pgdn',0	;147 - KeyPgDn
  db 18	;'ins',0	;148 - KeyIns
  db 19	;'del',0	;149 - KeyDel
  db 10	;'home',0	;150 - KeyHome
  db 16 ;               ;151 - KeyDown
  db 11 ;               ;152 - KeyUP
  db 14 ;		;153 - KeyRight
  db 13 ;		;154 - KeyLeft
  db 10 ;		;155 - home
  db 15 ;		;156 - end
;
; all keyboard routines are listed here for attachment
; to keys.  See tables above for pointers (index) to
; these routines.  A zero indicates this is unused
; entry, otherwise a process address is specified.

process_adr_tbl:
  dd window    	;01 w - toggle window state
  dd quit_menu	;02 q
  dd m_exit    	;03  - save & exit
  dd m_update  	;04 save file
  dd macro_record_toggle ;05 enable/disable macro record
  dd macro_execute_menu	;06  execute macro
  dd other     	;07  switch buffers
  dd m_write	;08  save file as
  dd m_newfile	;09 QI init new file
  dd KeyHome	;10
  dd key_up	;11
  dd KeyPgUp	;12
  dd key_left	;13
  dd key_right	;14
  dd KeyEnd	;15
  dd key_down	;16
  dd KeyPgDn	;17
  dd KeyIns	;18
  dd KeyDel	;19 ;was ^g ws
  dd m_find_fwd ;20
  dd m7_replace	;21
  dd m7mode	;22 find menu
  dd m_find_back ;23
  dd m8mode	;24 block menu
  dd m5_calc	;25
  dd m8_dblock  ;26
  dd m8_getblock ;27
  dd m10mode	;28 help menu
  dd m6_insert  ;29
  dd KeyDell	;30 ^h pico ^h emac ^h ws - del char left
  dd delete_line ;31 
  dd m4mode	;32 jump menu
  dd m4_line	;33 jump to line
  dd delete_right ;34 delete to end of line
  dd delete_left ;35 - delete to begining of line
  dd m5mode	;36 misc menu
  dd m3_other	;37 
  dd m5_paragraph ;38
  dd m2mode	;39 quit menu
  dd m9mode	;40 setup menu
  dd m6mode	;41 edit menu
  dd m3mode    	;42 window menu
  dd m6_overtype ;43
  dd m8_get	 ;44
  dd m_abort	;45
  dd m1mode	;46 main menu
  dd f2_todo	;47 KeyEmaCtrlY  - yank (paste)
  dd mark_block	;48 mark_block
  dd restore_line ;49
  dd f_make     ;50
  dd f_bug     	;51
  dd 0      	;52
  dd 0        	;53
  dd 0     	;54
  dd 0   	;55
  dd 0         	;56	;help pgdn
  dd 0     	;57	;help pgup
  dd 0         	;58
  dd KeyHelp	;59 f1 - help
  dd calc	;60  calculator
  dd hex_input	;61 ^r hex input
  dd paragraph 	;62 paragraph (p)
  dd NormChar	;63 tab, space, etc. - insert into buffer
  dd 00		;64 KeySuspend	 
  dd 00         ;65
  dd 0   	;66
  dd jump_menu	;67  j jump - aedit jump menu 
  dd find_forward ;68 f find - aedit find forward  
  dd find_back	;69  - find - aedit find back
  dd again	;70 - again for find,replace,macros
  dd set_tag	;71 - set tag
  dd set_cmd_mode ;72 - esc 
  dd xchange_mode ;73 - enter exchange mode
  dd insert_mode	;74 - enter insert mode
  dd 0     	;75 -
  dd dmark_block ;76 - mark delete block
  dd get_file	;77 - get buffer or file
  dd find_and_replace ;78 - find and replace text
  dd key_f5	;79
  dd key_f6	;80
  dd key_f7	;81
  dd key_f8	;82
  dd key_f9	;83
  dd key_fa	;84
  dd key_fb	;85
  dd key_fc	;86

; (#13#) database - active win/file data ***********************
;---------------------------------------------------------------
  [section .data]

;-- display section ------------
;------------------------------------------------------------------------
; colors = aaxxffbb  (aa-attribute ff-foreground  bb-background)
;   30-black 31-red 32-green 33-brown 34-blue 35-purple 36-cyan 37-grey
;   attributes 30-normal 31-bold 34-underscore 37-inverse
norm_text_color	dd 30003734h ;used for inactive window
;			     ;grey-foreground=7 blue-backgound=4 0=norm attr
bold_edit_color	dd 31003734h ;used for active window in edit mode
;			     ;grey-foreground=7 blue-backgound=4 0=bold attr
bold_cmd_color	dd 31003334h ;used for active window in command mode
;			     ;grey-foreground=7 blue-backgound=4 0=bold attr
high_text_color	dd 31003634h ;used for highlighting block
;			     ;grey-foreground=7 blue-backgound=4 0=inver attr
asm_text_color	dd 31003234h ;used to highlight comments ";"
;			     ;cyan-foreground=6 blue-backgound=4 0=norm attr
status_color	dd 30003037h ;used for status line
status_color1	dd 30003137h ;used for special data on status line
status_color2	dd 31003331h ;used for error messags or macro record
exit_screen_color dd 31003334h ;used for error messags on status line
cursor_color	dd 30003137h
;----------------------------------------------------------  
; (#14#) database - misc command data *************************************


hex_msg	db	'Enter hex (2 characters):',0
calc1_msg db	'Enter <number> <operator +-*/> <number> :',0
calc2_msg db	'Calc results = '
calc3_msg db	'          <- decimal    '
calc4_msg db	'          <- hex  (any key to cont.)                     ',0
para1_msg  db	'Select  F(flow paragraph) M(set margin) :',0
para2_msg  db	'Enter left margin (1 -> 255) :',0
para3_msg  db	'Enter right margin (2 -> 255) :',0
;

macro_flag db	0	;0=idle 1=record 2=playback
macro_ptr  dd	0	;points into macro_buffer
macro_prompt_msg db 'Execute macro - yes? no? forever? (y,n,f):',0
macro_error_msg	db  'Macro buffer full, aborting',0

;save_active_window	dd	0	;used by help
;save_mouse_mode		dd	0	;used by help


shell_err1	db	'F3 functions only work on file1 (press key) ',0
shell_err2	db	'F3 functions require file2, continue? y/n',0
;shell_err3	db	'external program not found (press key)',0

; find database

find_msg:	db	'find what? :',0
not_found_msg	db	' Not found ',1bh,'[0K',0  ;msg + erase to end of line vt code
find_str	times (maxfilenamelen+1) db 0
find_str_len 	dd	0
find_ptr	dd	0
;
; repeat data used by "again" command and others. 
do_again_ck	dd	0	;used by macro repeat to watch cursor
do_again_ck2	dd	0	;end of buffer ptr for repeat forever check
macro_forever_flg	db	0	;0=disabled  2=macro forever
last_cmd	db	0	;1=find 2=macro
;
; replace database

replace_msg	db 'Replace with: ',0
replace_again_prompt db   'Replace - Yes? Skip? All? Quit? (y/s/a/q):',0
replace_ptr	dd	0
replacetext	times (maxfilenamelen+1) db 0
replace_str_len dd	0
replace_all_flag db	0	;0=normal replace 1=replace all

exit_program_flg dd	0	;0=run 1=exit program
signal_abort	db	0	;0=no abort, 1=abort

mouse_col	db	0	;data from vt100 mouse reporting
mouse_row	db	0	;data from vt100 mouse report
mouse_button	db	0	;data from vt100 mouse report (read_keys)

str_max		dd	0	;max string ptr
str_max_count	dd	0	;max characters to input
str_ptr		dd	0	;current string edit point
str_begin	dd	0	;start of string
str_cursor	dd	0	;cursor for string entry, row,column
str_terminator	db	0dh	;terminator for string (1b=esc 0d=return)
char_out	db	0,0,0	;char display in get_string

;
kbuf	times 20 db	0	;data from keyboard (read_keys)
get_string_flg	db	0	;set each time get_string entered

poll_tbl	dd	0	;stdin
		dw	1	;events of interest
poll_rtn	dw	-1	;return from poll

top_of_para	dd	0	;points at first data char
end_of_para	dd	0	;points at first 0ah pair

display_char	db	0	;used by vertical repeat
repeat_count	db	0

editbuf_end	dd	0	;current end of editbuf
buffered_line_len dd	0	;lenght of line cut with ^z
result_flag	db	0	;output from check_file routine  

vt100_color_str:
  db	1bh,'['
vcs_atr:
  db	0,'m'
  db	1bh,'[4'
vcs1:
  db	0
  db	'm'
  db	1bh,'[3'
vcs2:
  db	0
  db	'm'
  db	0

;mouse_escape	db   1bh,'c',1bh,"[?1000h",0	;reset then enable mouse
mouse_escape	db   1bh,"[?1000h",0	;reset then enable mouse

f_name	db	'    ',0

buf_file_exists	db	0	;set if buffer written to file
block_file_name	db '/tmp/tmp.blk'
block_file_name_stuff db '0',0

;
; the following pointers are to arguements for external programs
;
enviro_ptrs	dd	0		;pointer to stack pointer for env

target_cursor_linenr	dd	0
target_top_linenr	dd	0
special_status_msg_ptr	dd	0

config_filename	db	'|/usr/share/asmedit/asmedit_setup|' 
config_code     db	'x',0

;----------------------------------------------------------------
; window dimensions
;           single window
term_statusln	db	0	;status line row
term_loc_col	db	1	;column of upper left corner
term_loc_row	db	1	;row of upper left corner
term_columns	db	0	;total column
term_rows	db	0	;total rows
;           top  horizontal window
hor_a_status	db	0	;status line row
hor_a_loc_col	db	1	;column of upper left corner
hor_a_loc_row	db	1	;row of upper left corner
hor_a_columns	db	0	;total column
hor_a_rows	db	0	;total rows
;           bottom horizontal window
hor_b_status	db	0	;status line row
hor_b_loc_col	db	1	;column of upper left corner
hor_b_loc_row	db	0	;row of upper left corner
hor_b_columns	db	0	;total column
hor_b_rows	db	0	;total rows
;           left vertical window
ver_a_status	db	0	;status line row
ver_a_loc_col	db	1	;column of upper left corner
ver_a_loc_row	db	1	;row of upper left corner
ver_a_columns	db	0	;total column
ver_a_rows	db	0	;total rows
;           right vertical window
ver_b_status	db	0	;status line row
ver_b_loc_col	db	0	;column of upper left corner
ver_b_loc_row	db	1	;row of upper left corner
ver_b_columns	db	0	;total column
ver_b_rows	db	0	;total rows

;---------file templates---------------------------------
file1_template:
file1_location	db	0
file1_change	db	20h	;20h=unchanged "*"=changed
file1_end_ptr	dd	0	;pointer to last char+1
file1_path	times 300 db (0)	;file name
file1_tmp_name	db	'/tmp/asmedit.tmp.'
file1_tmp_name_stuff db '1',0
tag_a1	dd	0
tag_b1	dd	0
tag_c1	dd	0
tag_d1	dd	0
file1_attributes dw	0
; buffer/block data.
blockbegin1 dd	0	;beginning of block
blockend1   dd	0	;end of block
showblock1  dd	0	;used if display of block needed
show_asm1   dd	1	;used if display of asm highlighting active
asm_comment_char1 db	';'

win_type_a	db	0	;set from active_window
editbuf_cursor_ptr_a dd	0	;pointer to cursor data in editbuf
editbuf_cursor_line_ptr_a dd 0	;ponter to start of line with cursor
cursor_linenr_a	dd	1	;line number of cursor
crt_top_ptr_a	dd	0	;top line ptr
crt_top_linenr_a dd	1	;line number for top crt diplayed line
crt_left_column_a dd	0	;column number for left window edge
crt_cursor_a	dd	0101h	;row/col for display cursor
status_line_row_a db	0	;column for status line
win_loc_col_a	db	1	;column of upper left corner
win_loc_row_a	db	1	;row of upper left corner
win_columns_a	db	0	;total column
win_rows_a	db	0	;total rows
;----------------------------------------------------
file2_template:
file2_location	db	0
file2_change	db	20h	;20h=unchanged "*"=changed
file2_end_ptr	dd	0	;pointer to last char+1
file2_path	times 300 db (0)	;file name
file2_tmp_name	db	'/tmp/asmedit.tmp.'
file2_tmp_name_stuff db '2',0
tag_a2	dd	0
tag_b2	dd	0
tag_c2	dd	0
tag_d2	dd	0
file2_attributes dw	0
; buffer/block data.
blockbegin2 dd	0	;beginning of block
blockend2   dd	0	;end of block
showblock2  dd	0	;used if display of block needed
show_asm2   dd	1	;used if display of asm highlighting active
asm_comment_char2 db	';'

win_type_b	db	0	;(set from active_window)
editbuf_cursor_ptr_b dd	0	;pointer to cursor data in editbuf
editbuf_cursor_line_ptr_b dd 0	;ponter to start of line with cursor
cursor_linenr_b	dd	1	;line number of cursor
crt_top_ptr_b	dd	0	;top line ptr
crt_top_linenr_b dd	1	;line number for top crt diplayed line
crt_left_column_b dd	0	;column number for left window edge
crt_cursor_b	dd	0101h	;row/col for display cursor
status_line_row_b db	0	;column for status line
win_loc_col_b	db	1	;column of upper left corner
win_loc_row_b	db	1	;row of upper left corner
win_columns_b	db	0	;total column
win_rows_b	db	0	;total rows

template_size	equ	$-file2_template
win_template_size equ	$-win_type_b
win_short_size	equ	$-status_line_row_b        
;--------------------------------------------------------------------------

;---------------------------------------------------------
;
%include "a.inc"

; (#15#) database - buffers *******************************************
;--- unitialized data -------------------------------------

[section .bss]
[bits 32]

;----------------------------------------------------------------
; launch engine input data block.
; Set this up before calling launch engine
;
 [section .bss]

path_flag	resb	1	;0=local executable (in current working dir)
				;1=search executable path for name, needs entry_stack
				;2=ename_ptr has path + name + parameters
                                ;3=ename has name + parameters and pname has path
                                ;4=ename has name + path base is $HOME/[base]
				
launch_flag	resb	1	;0=launch and wait for completion, 1=launch and continue
                                ;2=launch and die
ename_ptr	resd	1	;pointer to executable program name + parameters
pname_ptr	resd	1	;ponter to path, only needed if path_flag=3
;
; work area for lanuch_engine
;
;env_ptr		resd	1	;pointer to env pointers on stack

execve_args	resd	1	;pointer to path and name text
parm1_ptr	resd	1	;pointer to parameter1
parm2_ptr	resd	1	;pointer to parameter2
		resd	5	;leave room for 5 parameters
execve_term	resd	1	;end of parameters, must be zero

; see execve_status & execve_buf below
;--------------------------------------------------------------
saved_settings: resb	18
;--------------------------------------------------------------
;
; macro data consists of each key press followed by zero
; byte.  The end of a macro is two consecutive zero bytes.
macro_buffer resb 300 	;may overflow, follow with buffer
macro_buffer_end	equ	$
bakpath resb  maxfilenamelen+1
ini_path resb 20
;
; terminal settings  sent to kernel & termios_orig
termios: resb termios_struc_size
termios_orig: resb termios_struc_size

winsize: resb winsize_struc_size
winsize_sav	resd	1	;previous window size

scan_direction resd 1
last_find_status resb	1	;0=not found 1 = found
;
; buffercopy holds lines deleted by control-z
;
buffercopysize equ 512
buffercopy resb buffercopysize

lib_buf resb 256
; note:  lib_buf overflows into blockpath, so don't move below.
blockpath resb maxfilenamelen+1
optbuffer resb optslen 	;buffer for search/replace options and for ^QI

max equ 102400
;text resb max
  resb 1		;dummy
editbuf_ptr	resd	1

;
