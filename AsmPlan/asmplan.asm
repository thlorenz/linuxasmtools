
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
  extern install_signals
  extern key_decode2
  extern key_decode1
  extern read_stdin
  extern kbuf
  extern err_msg
  extern env_stack
  extern enviro_ptrs
  extern block_write_all
  extern dword_to_l_ascii
  extern crt_clear
  extern crt_color_at
  extern crt_str
  extern move_cursor
  extern mov_color
  extern file_delete
  extern select_1up_list_left
  extern crt_window
  extern mouse_enable
  extern blk_find
  extern lib_buf
  extern reset_clear_terminal

; ----------- Seasonal plan Program Version beta .1.0 ------------
;****f* asmedit/a_plan *
; NAME
;  a_plan - todo and note taker
; INPUTS
;  * usage:  a_plan <project name>     
;  * The projects are stored at $HOME/asmplan
;  * If a_plan is not passed a project name
;  * it opens the first project found.  If no
;  * projects are found it opens a dummy project.
;  * -
;  * Program operations are optimized for mouse
;  * usage and a short help file is available
;  * from within a_plan.           
; OUTPUT
;  * Entries are stored in files that match the name of
;  * each project.  Files are in ascii and can be editied
;  * with any text editor if the format is preserved.
; NOTES
; * file: asmplan.asm
; * This file is a standalone ELF binary.
; * ----------------------------------------------
;*******
;----------------------------------------------------------------------
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
;----------------------------------------------------------------------

%include 'struc.inc'

[section .text]

; ----------- test code --------------
;  jmp	.t
;.msg  db	0ah,'we arrived at ----',0ah,0
;.t: pusha
;   mov	ecx,.msg
;      call	crt_str
;      popa
;----------- test code ------------------
;
;1 main *******************************************************************
; The program begins execution here...... 
;
  global  main

main:
  cld
  call	env_stack
  call	mouse_enable
  call	setup
  call  signal_install
restart:
  call	init_project
  jc	exit1            	;exit if project data corrupted
;
; This is the top level loop that responds to keys and clicks
;
main_loop:
  call	display_project_list
  call	display_todos
  call	highlight_selected
  call	display_menu
  call	read_stdin
  cmp	byte [kbuf],-1		;check if mouse click
  jne	key_event		;jmp if key press
  call	mouse_event
  jmp	ml_end
key_event:
  mov	eax,dword [kbuf]
  call	decode_key			;ecx = index or err(0)
  jecxz main_loop			;ignore unknown keys
;;  mov	ecx,[ecx]			;get process
ml_end:
  jecxz	main_loop			;igonre clicks in unknown area
  call	ecx				;call keyboard process !!!!
  cmp	byte [exit_program_flg],0	 ;does user want to exit?
  je	main_loop			;loop back for another key or mouse event
  cmp	byte [exit_program_flg],2
  je	restart
exit1:
  jmp	exit_program

;
;2 init *******************************************************************
%include "setup.inc"

;---------------------------------------

signal_install:
  mov	ebp,signal_table
  call	install_signals
  ret
;----------
  [section .data]
signal_table:
  db	28
sig_mod1:
  dd	winch_signal
  dd	0
  dd	0
  dd	0
  db	0		;end of install table
  [section .text]
;
winch_signal:
  call	read_window_size	;pre compute window sizes
  call	display_project_list
  call	display_todos
  call	display_menu
  ret


;3 men commands *******************************************************************
;                                                                ( see below )
;-------------------------------------------------------------
;--------- main menu  commands --------------------------
;-------------------------------------------------------------
;------------------------------------------------------
display_project_list:
  mov	edi,lib_buf
  mov	ebp,project_list
  mov	ecx,[left_column]
  mov	dl,[crt_columns]
;
; store separator
;
dlp_05:
  mov	eax,[project_bar_color]
  call	mov_color
  mov	al,' '
  call	stuff_char
  jz	dlp_90		;jmp if edge of screen reached
  cmp	byte [ebp],0	;check if end of list
  je	dlp_80		;go fill rest of screen with blanks
  call	stuff_char
  jz	dlp_90		;jmp if edge of screen reached
  cmp	byte [ebp],0	;check if end of list
  je	dlp_80		;go fill rest of screen with blanks
;
; check if next project is selected
;
  cmp	ebp,[project_ptr]
  jne	dlp_22		;jmp if not current project  
;
; project was found, set color
;
  mov	eax,[selected_proj_button_color]
  call	mov_color
  jmp	short dlp_23
;
; project not current, set color
;
dlp_22:
  mov	eax,[proj_button_color]
  call	mov_color
dlp_23:
  mov	esi,ebp		;get ptr to next project name
dlp_24:
  lodsb			;move project name
  or	al,al
  jz	dlp_30		;jmp if name moved
  call	stuff_char
  jz	dlp_90		;jmp if end of screen reached
  jmp	dlp_24		;continue moving project name
dlp_30:
  mov	ebp,esi		;update pointer to project list
  jmp	dlp_05		;go to top of loop
;
; fill rest of line with blanks
;
dlp_80:
  cmp	dl,10			;at date append trigger?
  jne	dlp_84
  call	add_date
  jmp	short dlp_86
dlp_84:
  mov	al,' '
  call	stuff_char
  jnz	dlp_80
dlp_86:
  mov	byte [edi],0		;put zero at end of proj list
;
; end of screen reached
;
dlp_90:
  mov	al,1			;colulmn 1
  mov	ah,1			;row 1 
  call	move_cursor 
  mov	ecx,lib_buf
  call	crt_str     
  ret
;------------------------------------------------------
; inputs: edi = stuff point
;         ecx = 0
;         dl=10

add_date:
  call	get_raw_time		;returns raw time in eax,ebx
  mov	ebx,format4
  call	raw2ascii
  ret
format4:
  db '7- 2 6-',0

;------------------------------------------------------
;
display_todos:
  mov	dh,2			;starting row
  mov	ebp,[display_top_ptr]	;get pointer to data buffer
  mov	ecx,[left_column]	;scroll left count
  mov	al,[crt_rows]
  sub	al,2
  mov	[last_todo_row],al	;save last row number
;
; data format  
; _1990/10/01 This is an example project entry, 0ah line2   ,0ah, 0ah
;
dt_top:
  mov	dl,[crt_columns]	;columns
  mov	edi,lib_buf		;line build area
  mov	eax,[todo_data_color]
;
; compare todo's date to current date and set color for due/pending
;
  push	esi
  push	edi
  push	ecx
  mov	esi,ebp
  add	esi,year_field		;ptr to todo
  mov	edi,ascii_year		;ptr to current date
  mov	ecx,8
  cld
  rep	cmpsb
  ja	dt_color
  mov	eax,[todo_due_color]  
dt_color:
  pop	ecx
  pop	edi
  pop	esi
  call	mov_color
;
; check for null file
;
  cmp	ebp,[file_end_ptr]
  jne	dt_02			;jmp if records avail
  jmp	dt_60			;jmp if null file
dt_02:
  mov	al,byte [ebp]
  cmp	al,0ah
  jne	dt_04			;jmp if data record
  je	dt_30			;jmp if at end of todo's
dt_04:
  call	stuff_char
  mov	al,'_'
;
; build date for display
;
dt_10:
  call	stuff_char		;store "_"
  mov	esi,ebp
  add	esi,month_field		;move to month
dt_15:
  lodsb
  call	stuff_char
  lodsb
  call	stuff_char
  mov	al,' '
  call	stuff_char		;put space at end
;
; move day
;
  lodsb
  call	stuff_char
  lodsb
  call	stuff_char
  mov	al,' '
  call	stuff_char
;
; move text of todo
;
  mov	esi,ebp
  add	esi,text_field
dt_22:
  lodsb
  cmp	al,0ah			;check if end of data
  je	dt_30			;jmp if end of text field
  call	stuff_char
  jnz	dt_22			;loop if not at edge of screen
;
; we have reached the end of screen
;
dt_24:
  mov	al,0
  stosb				;put zero at end of data
  jmp	dt_50			;go display line
;
; we have reached end of line, fill rest of line with blanks
;
dt_30:
  mov	al,' '
  call	stuff_char
  jnz	dt_30
  mov	al,0
  stosb				;put zero at end of data  
;
; move data ptr to end of todo
;
dt_50:
  cmp	word [esi-1],0a0ah
  je	dt_51			;jmp if we are at end of todo
  inc	esi
  jmp	dt_50			;loop till end of line found
dt_51:
;
; check if this todo has extended data
;
  mov	ebx,ebp			;get ptr to start of current todo
  add	ebx,sched_field
  test	byte [ebx],20h
  jz	dt_51a			;jmp if single line todo
  mov	byte [edi - 2],'>'
dt_51a:
  inc	esi			;move past 0a at end of todo
  mov	ebp,esi			;save start of next line
;
; display line
;
dt_52:
  push	edx
  push	ecx
  mov	al,1			;colulmn 1
  mov	ah,dh			;row x 
  call	move_cursor 
  mov	ecx,lib_buf
  call	crt_str
  pop	ecx
  pop	edx     

  inc	dh			;move to next row
  cmp 	dh,[last_todo_row]
  ja	dt_70			;jmp if all rows displayed
;
; both of the following end of data checks are needed
;
  cmp	ebp,[file_end_ptr]	;check if raw data exhausted
  je	dt_60			;jmp if no more raw data
  jmp	dt_top
;
; we are at end of raw data, fill remaining lines with blanks
;
dt_60:
  mov	dl,[crt_columns]
  mov	edi,lib_buf
  mov	al,' '
dt_62:
  call	stuff_char
  jnz	dt_62			;loop till line filled
  mov	byte [edi],0		;put zero at end of line
  jmp	dt_52			;go display line
dt_70:
  mov	[next_page_ptr],ebp
  ret


;---------------------------
; input: [edi] = stuff point
;          al  = character
;         ecx = scroll left count
;          dl = screen size
; output: if (zero flag) end of line reached
;         if (non zero flag) 
;             either character stored
;                 or ecx decremented if not at zero
;
stuff_char:
  jecxz	sc_active	;jmp if file data scrolled ok
  dec	ecx
  or	edi,edi		;clear zero flag
  ret
sc_active:
  stosb			;move char to lib_buf
  dec	dl  
  ret

;----------------------------------------------------------------
new_proj:
  mov	eax,[todo_data_color]  
  call	crt_clear
  mov	eax,[todo_data_color]  
  mov	ebx,0102h		;get cursor location
  mov	ecx,new_proj_msg1	;get msg address
  call	crt_color_at	;display message
; get prompted string or mouse event
;  input:  ebp -> prompt message ptr       +0 (dword)
;                 prompt message color ptr +4 (dword)
;                 data buffer ptr          +8 (dword)   has zero or preload
;                 max string length       +12 (dword)
;                 color ptr               +16 (dword)
;                 display row             +20 (db)       prompt row
;                 display column          +21 (db)
;                 allow 0d/0a in str      +22 (db)	;0=no 1=yes
  mov	ebp,proj_name_input_table
  mov	dword [ebp],new_proj_msg2		;store promopt message  
  mov	byte [proj_name_col],2			;restore column of 2
  call	get_prompted_string
  cmp	al,0
  jne	np_exit				;jmp if no valid name entered
np_10:
  call	process_todos
  cmp	dword [file_end_ptr],fbuf
  je	skip_sort1			;jmp if zero entries
  call	sort_todos
skip_sort1:
  call	write_sorted_project
;
; write new project file
;
  mov	edi,parsed_project
  call	create_project
  call	get_project_names
  mov	byte [exit_program_flg],2	;trigger restart
np_exit:
  ret
;-------------------------------------------------------

del_proj:
  mov	esi,del_proj_msg1	;get msg address
  call	select_project		;get project name in edi
  cmp	edi,0
  je	dp_exit			;jmp if no file available  
  push	edi			;save project name
  mov	edi,lib_buf
  mov	esi,home_path
  call	str_move
  pop	esi
  call	str_move
  mov	ebx,lib_buf
  call	file_delete
  call	get_project_names
dp_exit:
  mov	byte [exit_program_flg],2	;trigger restart
  ret
;-----------------------------------------------------------  

open_proj:
  call	process_todos
  cmp	dword [file_end_ptr],fbuf
  je	skip_sort3			;jmp if zero entries
  call	sort_todos
skip_sort3:
  call	write_sorted_project
;
; get name of project to open
;
  mov	esi,open_proj_msg1	;get msg address
  call	select_project		;get project name in edi
  cmp	edi,0
  je	op_exit			;jmp if no file available  
  mov	[pname],edi
;
; setup pointer to selected project
;
  mov	ebp,project_list+1000
  mov	esi,[pname]
  mov	edi,project_list
  mov	edx,1			;search fwd
  mov	ch,0ffh			;match case
  call	blk_find
  mov	[project_ptr],ebx
;
; move project name to parsed project
;
  mov	edi,parsed_project
  mov	esi,ebx
  call	str_move
op_exit:
  mov	dword [selected_todo],fbuf
  mov	byte [exit_program_flg],2	;trigger restart
  ret
;-----------
  [section .data]
pname	dd	0
  [section .text]
;-----------------------------------------------------------  
add_todo:
  call	update_todo_template
  mov	esi,todo_template
  mov	edi,todo_temp1
  call	move_todo
  mov	edi,todo_temp2
  call	move_todo
  mov	eax,todo_temp1		;pass todo ptr in eax
  call	edit_todo		;edit todo in todo_temp1
; return code in -al- 2=normal 3=delete 4=previous 5=next 6=abort
  cmp	al,2
  je	at_normal		;jmp if normal return
  cmp	al,3
  je	at_exit			;jmp if delete button pressed
  cmp	al,6
  je	at_exit			;jmp if abort button pressed
  cmp	al,4
  je	at_previous
  call	append_edits		;save edits
  jmp	add_todo		;we are at end of buffer, go add another  
at_previous:
  call	append_edits		;go save edit
  mov	esi,[file_end_ptr]
  call	prev_todo
  jc	at_exit			;exit if at top
  call	prev_todo
  jc	at_exit			;exit if at top
  mov	dword [active_todo_ptr],esi
  jmp	edit_jump
at_normal:
  call	append_edits
at_exit:
  mov	byte [exit_program_flg],0	;set normal processing
  ret

;-------------------------------------------------------
append_edits:
  call	check_for_blank_todo
  jc	ae_exit			;jmp if todo blank
  mov	esi,todo_temp1
  mov	edi,[file_end_ptr]
  call	insert_todo
ae_exit:
  ret
  
;--------------------------------------------------------
save_edits:
  call	check_for_blank_todo
  jc	se_exit
  mov	esi,todo_temp1
  mov	edi,[active_todo_ptr]	;add todo to buffer
  call	insert_todo
se_exit:
  ret
;--------------------------------------------------------
restore_edits:
  call	check_for_blank_todo
  jc	re_exit
  mov	esi,todo_temp2
  mov	edi,[active_todo_ptr]	;add todo to buffer
  call	insert_todo
re_exit:
  ret
;-----------------------------------------------------------
; input:  todo at todo_temp1
; output: carry set if blank
;  
check_for_blank_todo:
  mov	esi,todo_temp1
  add	esi,text_field
cfbt_lp:
  cmp	word [esi],0a0ah
  je	cfbt_blank
  mov	al,[esi]
  inc	esi
  cmp	al,' '
  je	cfbt_lp			;loop if space
  cmp	al,0ah
  je	cfbt_lp			;loop if line separator
  clc
  jmp	cfbt_exit2
cfbt_blank:
  stc
cfbt_exit2:
  ret

;-----------------------------------------------------------  
; extract todo from buffer and save before calling edit_todo
;
edit_jump:
  mov	esi,[active_todo_ptr]
  call	cut_todo		;extract todo
  mov	eax,todo_temp1
  call	edit_todo
; return code in -al- 2=normal 3=delete 4=previous 5=next 6=abort
  cmp	al,2
  je	ej_normal		;jmp if normal return
  cmp	al,3
  je	ej_exit			;jmp if delete button pressed
  cmp	al,6
  jne	ej_cont
  call	restore_edits
  jmp	ej_exit
ej_cont:
  cmp	al,4
  je	ej_previous
  call	save_edits		;save edits
  mov	esi,[active_todo_ptr]
  call	next_todo
  jc	do_add			;jmp if at end
  mov	[active_todo_ptr],esi
  jmp	edit_jump
do_add:
  jmp	add_todo		;we are at end of buffer, go add another  
ej_previous:
  call	save_edits		;save edits
  mov	esi,[active_todo_ptr]
  call	prev_todo
  jc	ej_exit			;jmp if at top already
  mov	[active_todo_ptr],esi
  jmp	edit_jump
ej_normal:
  call	save_edits
ej_exit:
  mov	byte [exit_program_flg],0	;set normal processing
 ret

;-----------------------------------------------------------
down_key:
  mov	esi,[selected_todo]
  cmp	esi,[file_end_ptr]
  je	sf_exit			;exit if at end of buffer
  call	next_todo
  cmp	esi,[file_end_ptr]
  je	sf_exit			;exit if at end of buffer
  mov	[selected_todo],esi
  cmp	esi,[next_page_ptr]
  jne	sf_exit
  mov	esi,[display_top_ptr]
  call	next_todo
  mov	[display_top_ptr],esi
sf_exit:
  ret
;-----------------------------------------------------------

page_fwd:
  mov	eax,[next_page_ptr]
  cmp	eax,[file_end_ptr]
  je	pf_exit
  mov	[display_top_ptr],eax
  mov	[selected_todo],eax
pf_exit:
  ret

;-----------------------------------------------------------
up_key:
  mov	esi,[selected_todo]
  cmp	esi,fbuf
  je	sb_exit			;exit if at top
  call	prev_todo
  mov	[selected_todo],esi
  cmp	esi,[display_top_ptr]
  jae	sb_exit			;exit if still in window
  mov	esi,[display_top_ptr]
  call	prev_todo
  mov	[display_top_ptr],esi	;move window top
sb_exit:
  ret

;-----------------------------------------------------------

page_back:
  mov	esi,[display_top_ptr]
  cmp	esi,fbuf
  je	pb_exit
  mov	bl,1
pb_loop:
 call	prev_todo
  jc	pb_exit		;exit if top of screen
  inc	bl
  cmp	bl,[crt_rows]
  jne	pb_loop		;loop if not page yet  
pb_exit:
  mov	[display_top_ptr],esi
  mov	[selected_todo],esi
  ret

;-------------------------------------------------------------------
; inputs:  esi = pointer to current todo
; output:  no-carry = esi is pointer to next todo
;          carry = esi points at end of buffer, no more todos
;
next_todo:
  cmp	esi,[file_end_ptr]
  jae	nt_exit2			;jmp if at end of buffer
  cmp	word [esi],0a0ah
  je	nt_exit1			;jmp if next todo found
  inc	esi
  jmp	next_todo
nt_exit1:
  add	esi,2
  cmp	esi,[file_end_ptr]
  je	nt_exit2			;jmp if at end of file
  clc
  jmp	nt_exit3
nt_exit2:
  stc
nt_exit3:
  ret

;--------------------------------------------------------------------
; inputs: esi =  pointer to current todo
; output: no-carry = esi is pointer to previous todo
;         carry = esi is pointer to end of buffer
;
prev_todo:
  cmp	esi,fbuf
  je	pt__exit3				;jmp if no previous todo
  sub	esi,2				;skip over 0a0a at end of previous todo
pt__lp:
  cmp	esi,fbuf
  je	pt__exit2			;jmp if previous found
  dec	esi
  cmp	word [esi],0a0ah
  jne	pt__lp				;loop till end of todo found
pt__exit1:
  add	esi,2				;move past 0a0ah
pt__exit2:
  clc
  jmp	pt__exit4			;go exit
pt__exit3:
  stc
pt__exit4:
  ret

;-----------------------------------------------------------
;search:

%include 'search.inc'

;-----------------------------------------------------------
config:
;-----------------------------------------------------------
;help:
%include 'help.inc'

;-----------------------------------------------------------
; main menu commands
;-----------------------------------------------------------  
complete:
  mov	esi,[active_todo_ptr]
  cmp	byte [esi],'C'
  jne	c_40
  mov	byte [esi],'_'
  jmp	short c_60
c_40:
  mov	byte [esi],'C'
c_60:
  ret
;--------------------------------------------
delete:
  mov	esi,[active_todo_ptr]
  cmp	byte [esi],'D'
  jne	d_40
  mov	byte [esi],'_'
  jmp	short d_60
d_40:
  mov	byte [esi],'D'
d_60:
  ret

;--------------------------------------------
exit_:
  mov	byte [exit_program_flg],1
  ret

;--------------------------------------------
;  input:  edi = end of status line
;
display_menu:
  mov	esi,menu_line1
  call	build_line
  mov	ah,[crt_rows]
  dec	ah
  mov	al,1
  call	move_cursor		;position cursor
  mov	ecx,lib_buf
  call	crt_str

  mov	esi,menu_line2
  call	build_line
  mov	ah,[crt_rows]
  mov	al,1
  call	move_cursor		;position cursor
  mov	ecx,lib_buf
  call	crt_str

  ret
;------------------------------------------
; build one display line using table
;  input: esi = table ptr
;
build_line:
  mov	edi,lib_buf
  mov	ecx,[left_column]
  xor	edx,edx
  mov	dl,[crt_columns]
  sub	dl,1
;
bl_10:
  lodsb
  cmp	al,8
  jb	bl_20    		;jmp if spacer between buttons
  call	stuff_char2		;store button text
  jns	short bl_10		;loop till end of screen
  jmp	bl_80			;jmp if end of screen
;
; we have encountered a spacer or end of table
;
bl_20:
  push	eax
  mov	eax,[todo_data_color]	;get color to use for spacer
  call	mov_color
  pop	eax
;
  cmp	al,0			;end of table
  je	bl_40			;jmp if end of table
;
; spacer char.
;
  mov	al,' '
  call	stuff_char2
  js	bl_80			;jmp if end of screen
  mov	eax,[button_color]
  call	mov_color
  jmp	bl_10			;go up and move next button text
;
; we have reached the end of table, fill rest of line with blanks
;
bl_40:
  mov	al,' '
  call	stuff_char2
  jns	bl_40
;
; end of screen reached, terminate line
;
bl_80:
  mov	al,0
  stosb				;put zero at end of display
  ret  
;------------------------
;---------------------------
; input: [edi] = stuff point
;          al  = character
;         ecx = scroll left count
;         edx = screen size
; output: if (zero flag) end of line reached
;         if (non zero flag) 
;             either character stored
;                 or ecx decremented if not at zero
;
stuff_char2:
  jecxz	sc_active2	;jmp if file data scrolled ok
  dec	ecx
  or	edi,edi		;clear zero flag
  ret
sc_active2:
  stosb			;move char to lib_buf
  dec	edx  
  ret


; input: edi = storage pointer
color0:
  mov	eax,[todo_data_color]
  call	mov_color
  ret

; input: edi = storage ptr
color1:
  mov	eax,[button_color]
  call	mov_color
  ret

; input: ecx=number of spaces needed
;        edi=storage pointer
spaces:
  mov	al,' '
  stosb
  loop	spaces
  ret  
;-------------------------------------------------------------------
; returns pointer to project name
;  input; esi=ptr to prompt message
; output: edi = project name ptr
;             = 0 if error or no name available
select_project:
; mov	esi,menu1_msg
 call	show_text_right		;display hints
 mov	edi,fbuf		;work area for menu display
 mov	esi,project_list	;asciiz strings
 call	select_1up_list_left
; returns al= 0 ESC pressed
  or	al,al
  jz	sp_err			;exit if escape
;look up project name
  mov	esi,project_list
  mov	bl,al			;save project#
sp_lp1:
  dec	bl
  jz	sp_got
sp_lp2:
  lodsb
  or	al,al
  jnz	sp_lp2
  jmp	short sp_lp1
sp_got:
  mov	edi,esi
  jmp	short sp_exit  
sp_err:
  xor	edi,edi
sp_exit:
  ret
;------------------------------------------------
; input: esi = ptr to text strings
;  
show_text_right:
  mov	[str_msg],esi
;
; find zero at end of message
;
str_lp:
  lodsb
  or	al,al
  jnz	str_lp
  dec	esi
  mov	[str_en],esi

  cmp	byte [crt_rows],0
  jne	str_10
  call	read_window_size
str_10:
  mov	al,[crt_columns]
  shr	al,1			;start in mid window
  add	al,3			;convert to 1 based
  mov	[str1],al		;total win columns
  mov	[str4],al		;starting column

  mov	al,[crt_rows]
  mov	[str2],al		;set max rows
  mov	esi,str_table
  call	crt_window
  ret
;-----------------------
  [section .data]

str_table:
         dd	30003734h	;page color
str_msg: dd	0		;ptr to text
str_en: dd	0		;end of all data for display
         dd	0		;scroll
str1:	db	0		;total win columns
str2:	db	0		;total win rows
str3:   db	1		;startng row
str4:	db	0		;starting column


;-----------------------------------------------
 [section .data]
;-----------------------------------------------

    
proj_name_input_table:
  dd	new_proj_msg2		;prompt message
  dd	todo_data_color		;color for prompt
proj_name_ptr:
  dd	parsed_project		;input buffer
  dd	18			;max string length
  dd	edit_entry_color	;color of entry area
  db	3			;row
proj_name_col:
  db	2			;column
  db	0			;terminator flag 


display_top_ptr	dd	fbuf		;buffer pointer
display_top_line dd	0		;line number at top of display
;
; menu line codes: 1=spacer  0=end of data
;
menu_line1:
  db 1,' New-proj ',1,' Openproj ',1,' Del-proj ',1,' Add-todo ',1,' Fwd ',1,' Back ',1,' Search ',1,' Help ',1,' Exit ',0
menu_line2:
  db 1,'    n     ',1,'    o     ',1,'    d     ',1,'     a    ',1,'  f  ',1,'   b  ',1,'   s    ',1,'   h  ',1,'   e  ',0
process_names:
  dd  new_proj,   open_proj,   del_proj,   add_todo,   page_fwd, page_back, search,       help,    exit_

last_todo_row	db	0

;------------------------------------------------
 [section .text]

%include "edit.inc"
 [section .text]
%include "exit.inc"
 [section .text]
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
; check locaton of click
;
  cmp	bh,1
  jne	me_05		;jmp if not click on project area
  jmp	me_40		;jmp if click on project area
me_05:
  mov	ah,[crt_rows]
  dec	ah
  cmp	bh,ah		;check if click on button row
  jb	me_06
  jmp	me_60		;jmp if click on button
me_06:
;
; click occured on todo item,  check column
;
  call	find_active	;find active todo start
  cmp	bl,11		;check if click on flag/code/date field
  jbe	me_10		;jmp if complete request
;
; click occured on todo body, call edit
;
  mov	ecx,edit_jump	;return edit_jump
  jmp	me_exit
;
; click occured on flag/code area
;
me_10:
  cmp	byte [mouse_button],0
  je	me_14
  mov	ecx,delete
  jmp	me_exit
me_14:
  mov	ecx,complete	;return "complete" ptr
  jmp	me_exit
;
; click on project row
;
me_40:
  mov	ecx,switch_projects
  jmp	me_exit	
;
; click on button row
;
me_60:
  mov	bl,1				;starting column
  mov	esi,menu_line1			;starting button text
  mov	edi,process_names		;look up table to process
  xor	ecx,ecx				;preload null process
me_62:
  inc	bl
  inc	esi
  cmp	bl,[mouse_col]			;match?
  je	me_70
  cmp	byte [esi],9
  jae	me_62				;jmp if normal char
me_64:
  cmp	esi,menu_line2			;check if outside button area
  jae	me_exit				;exit if beyond buttons
  add	edi,4				;move to next process
  jmp	me_62
me_70:
  mov	ecx,[edi]				;return ecx to caller
me_exit:      
  ret
;---------------
 [section .data]

mouse_col	db	0	;data from vt100 mouse reporting
mouse_row	db	0	;data from vt100 mouse report
mouse_button	db	0	;data from vt100 mouse report (read_keys)

 [section .text]
;--------------------------------------
; find active todo from click location
;  input:  mouse_col
;          mouse_row
;          [display_top_ptr]
;  output: [active_todo_ptr]
;
find_active:
  mov	esi,[display_top_ptr]		;get first todo
  mov	bh,2				;todo data starts on row 2
fa_lp1:
  cmp	bh,[mouse_row]
  je	fa_20				;jmp if row found
fa_lp2:
  cmp	word [esi],0a0ah		;check if end of todo
  je	fa_next				;jmp if end of todo
  inc	esi
  jmp	fa_lp2
fa_next:
  add	esi,2
  inc	bh
  jmp	fa_lp1
;
; we have found correct row
;
fa_20:
  mov	[active_todo_ptr],esi
  ret
  
;---------------------
; decode_key - look up processing for this key
;  input - kbuf - has char zero terminated
;  output - ecx = ptr to processing or zero if no match
;           eax,ebx modified
decode_key:
  mov	esi,key_table1
  call	key_decode1
  cmp	eax,alpha_key
  jnz	dk_exit
  mov	esi,key_table2
  call	key_decode2
  jnc	dk_exit
  mov	eax,alpha_key
dk_exit:
  mov	ecx,eax
  ret

alpha_key:
  xor	eax,eax
  ret

key_table1:
  dd alpha_key			;alpha key presss  
  
  db 1bh,0		;esc
  dd exit_	;01

  db 1bh,5bh,36h,7eh,0		;21 pad_pgdn
  dd page_fwd

  db 1bh,4fh,73h,0		;21 pad_pgdn
  dd page_fwd
  
  db 1bh,5bh,35h,7eh,0		;16 pad_pgup
  dd page_back
  
  db 1bh,4fh,79h,0		;16 pad_pgup
  dd page_back

  db 1bh,5bh,41h,0		;15 pad_up
  dd up_key

  db 1bh,4fh,41h,0		;15 pad_up
  dd up_key

  db 1bh,4fh,78h,0		;15 pad_up
  dd up_key

  db 1bh,5bh,42h,0		;20 pad_down
  dd down_key

  db 1bh,4fh,42h,0		;20 pad_down
  dd down_key

  db 1bh,4fh,72h,0		;20 pad_down
  dd down_key

  db 1bh,5bh,33h,7eh,0		;23 pad_del
  dd delete

  db 1bh,4fh,6eh,0		;23 pad_del
  dd delete
 
  db 0
  dd alpha_key		;unknown key press

;-----------------------

key_table2:
  db 'e'
  dd exit_

  db 'x'
  dd exit_

  db 'n'
  dd new_proj	;02

  db 'd'
  dd del_proj	;03

  db 'o'
  dd open_proj

  db 'a'
  dd add_todo	;04

  db 's'
  dd search	;07

  db 'h'
  dd help	;09

  db 'f'
  dd page_fwd	;10

  db 'b'
  dd page_back	;11

  db ' '
  dd complete

  db 0ah
  dd edit_jump

  db 0dh
  dd edit_jump

  db 0			;end of table
;
;------------------------------------------------------------------------------
 [section .text]


switch_projects:
  call	process_todos
  cmp	dword [file_end_ptr],fbuf
  je	skip_sort2			;jmp if zero entries
  call	sort_todos
skip_sort2:
  call	write_sorted_project
;
; now find with project name was clicked
;
  mov	esi,project_list
  mov	bl,3				;start scanning from column 3
me_41:
  cmp	bl,[mouse_col]
  jae	me_43				;jmp if click column found
  cmp	byte [esi],0			;check if separator char
  jbe	me_42
  inc	esi				;scan names
  inc	bl				;follow column scan
  jmp	me_41
;
; separator between names found
;
me_42:
  add	bl,2				;separator uses two display spaces
  inc	esi
  jmp	me_41
;
; column found, now scan back to beginning of name
;
me_43:
  cmp	byte [esi],0			;check for project separator
  je	me_44
  cmp	esi,project_list		;check if at start
  je	me_46
  dec	esi
  jmp	me_43
me_44:
  inc	esi
me_46:
  mov	[project_ptr],esi
;
; stuff name into parse buffer & read file
;
  mov	edi,parsed_project
me_47:
  lodsb
  stosb
  or	al,al
  jnz	me_47
  call	get_project_names		;read file
  mov	dword [selected_todo],fbuf
  mov	dword [display_top_ptr],fbuf
  mov	byte [exit_program_flg],2	;set restart mode
  ret

;----------------------------------
; write current project to disk
;
write_current_project:
  mov	edi,[project_ptr]
  cmp	byte [edi],0
  jz	wcp_exit		;jmp if no projects defined yet
  push	edi
  mov	edi,lib_buf
  mov	esi,home_path
  call	str_move
  pop	esi
  call	str_move
;
; entry for exit code
;
write_project:
  mov	ebx,lib_buf		;file name
  xor	edx,edx			;default permissions
  mov	ecx,fbuf		;data buffer
  mov	esi,[file_end_ptr]
  sub	esi,ecx			;compute write length
  call	block_write_all
wcp_exit:
  ret

;-----------------------------
; move todo from data file
;  inputs:  esi = ptr to start of todo
;           edi = storage point
; outputs: esi,edi unchanged
;          ecx = todo length
;          zero at end of todo
;           
move_todo:
  xor	ecx,ecx
  push	esi
  push	edi
  jmp	short mt_entry
mt_loop:
  cmp	word [esi],0a0ah	;check if at end
  je	mt_exit			;jmp if move done
mt_entry:
  movsb
  inc	ecx
  jmp	mt_loop
mt_exit:
  add	ecx,2
  mov	word [edi],0a0ah
  mov	byte [edi+2],0		;put zero at end  
  pop	edi
  pop	esi
  ret

;------------------------------------------------------------
; insert todo into buffer
;  input:  esi = new todo to add
;          edi =  destination
;          [file_end_ptr] - ptr to next available location
;
insert_todo:
  push	esi
;
; compute lenght of todo
;
  xor	ecx,ecx			;start count at zero
  cld
it_lp:
  cmp	word [esi],0a0ah
  je	it_lp_end
  inc	esi
  inc	ecx
  jmp	it_lp
it_lp_end:
  add	ecx,2
  pop	esi
  
;
; open hole for trial_todo_entry at -edi-
;
  push	ecx		;save lenght of todo
  push	esi 		;save todo pointer
  push	edi		;save destination
  mov	ebx,edi		;save insert point
  cmp	edi,[file_end_ptr]	;are we at end
  je	it_skip			;skip move if at end
  std
  mov	esi,[file_end_ptr]
  dec	esi		;move to last data byte
  mov	edi,esi
  add	edi,ecx		;add record_length to edi
  mov	ecx,esi
  sub	ecx,ebx		;compute lenght of move
  inc	ecx
  rep	movsb
  cld
;
; now move trail_todo_entry into hole
;
it_skip:
  pop	edi		;get insert point
  pop	esi		;get source ptr
  pop	ecx		;get record length
  add	dword [file_end_ptr],ecx
  rep	movsb
  ret
;------------------------------------------------------------
; remove current todo from fbuf
;  input:  esi = ptr to todo
; output:  todo stored at todo_temp1 with zero at end
;                         todo_temp2 
;
cut_todo:
  mov	edi,todo_temp1
  call	move_todo
  mov	edi,todo_temp2
  call	move_todo
;
; close the hole caused by removing a todo
;
  push	esi
  mov	edi,esi			;get starting point
  add	esi,ecx			;compute end of todo loc
  mov	ebx,ecx			;save lenght of todo
  mov	ecx,[file_end_ptr]
  sub	ecx,ebx
  sub	ecx,(fbuf -1)
  rep	movsb
  sub	dword [file_end_ptr],ebx
  pop	esi
  ret

;-----------------------------------------------------------
; set current year in template
;
update_todo_template:
  mov	eax,[year]		;get current year
  mov	edi,todo_template+year_field	;storage point for ascii
  mov	esi,4
  call	dword_to_l_ascii
  sub	eax,eax
  mov	ax,[month_number]
  mov	edi,todo_template + month_field
  mov	esi,2
  call	dword_to_l_ascii
  sub	eax,eax
  mov	ax,[day_of_month]
  mov	edi,todo_template + day_field
  mov	esi,2
  call	dword_to_l_ascii    
  ret
;------------------------------------------------------
highlight_selected:
  mov	bl,1			;start with line 1
  mov	esi,[display_top_ptr]
hs_lp:
  inc	bl
  cmp	esi,[selected_todo]
  je	hs_found
  call	next_todo
  jnc	hs_lp			;jmp if found
hs_found:
  add	esi,11
;
; move string to lib_buf
;
  mov	bh,[crt_columns]
  sub	bh,6
  mov	edi,lib_buf
hs_lp2:
  dec	bh
  jz	hs_done			;jmp if end of screen
  lodsb
  stosb
  cmp	al,0ah
  jne	hs_lp2
hs_done:
  mov	byte [edi-1],0
;
; display string
;
  mov	bh,bl		;row to -bh-
  mov	bl,9		;get column
  mov	eax,30003136h	;color
  mov	ecx,lib_buf
  call	crt_color_at
  ret  
;
;----------------------------------------------------------------------
  [section .data]
;------------------------------------------------------------------------
active_todo_ptr:
;;	dd	fbuf
selected_todo:	dd	fbuf

; colors = aaxxffbb  (aa-attribute ff-foreground  bb-background)
;   30-black 31-red 32-green 33-brown 34-blue 35-purple 36-cyan 37-grey
;   attributes 30-normal 31-bold 34-underscore 37-inverse
project_bar_color	dd	30003730h
selected_proj_button_color dd 	30003037h
proj_button_color	dd	31003037h

button_color		dd 	30003037h

todo_data_color		dd 	31003734h	;normal pending todo
todo_due_color		dd	31003134h	;due color

edit_color		dd	30003734h	;used for normal text
edit_field_color	dd	31003734h	;modifable/slectable field
edit_entry_color	dd	31003134h	;current selection
edit_button_color	dd	30003037h	;buttons and active edit field

exit_screen_color	dd 	31003334h


;----------------------------------------------------------  


exit_program_flg dd	0	;0=run 1=exit program 2=restart program 3=abort
;				;6=edit 7=find 8=block 9=funct 10=help
;

left_column	dd	0		;used to scroll window

file_end_ptr	dd	fbuf		;end of current todo file

next_page_ptr	dd	0	;set by display_todo to next page

mode	db	0	;0=summary  1=edit menu 2=click in edit menu

poll_tbl	dd	0	;stdin
		dw	-1	;events of interest
poll_rtn	dw	-1	;return from poll

todo_template	db	'_Y1yyyy0101     ',0ah,0ah,0

;---------------------------------------------------------

;--- unitialized data -------------------------------------

  [section .bss]
  [bits 32]

; align 4
;
;

;winsize: resb winsize_struc_size
;;winsize_sav	resd	1	;previous window size

year		resd	1
day_of_month	resd	1
month_number	resd	1
ascii_year	resd	1
ascii_month	resw	1
ascii_day	resw	1

ascii_number	resb	10
		
readfds		resd 1			;select data struc
timevalsec	resd 1			;lowest
timevalusec	resd 1			;most significant

home_path	resb	140

seg_end_ptr	resd	1			;end of segment pointer
;
; the following 3 buffers are shared as follows:
;   project_list - used by setup to read projects
;   todo_temp2 & todo_temp2 - stores current todo for calling edit_todo
;   sort_index - used by exit code to sort todo's before writing to disk
;
help_buf	resb	1000
sort_index	resb	1000
todo_temp1	resb	1000
todo_temp2	resb	1000
project_list	resb	1000		;list of project names

;
; fbuf is holding buffer for all todo's, it grows if needed and must be last
;
max equ 102400
text resb max
fbuf equ	(text+1)
seg_end	equ	text + max
