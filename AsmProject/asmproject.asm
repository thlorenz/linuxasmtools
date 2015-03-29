
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
  [section .text]

  extern read_window_size
  extern mouse_enable
;  extern crt_type
  extern env_stack
  extern crt_rows,crt_columns
  extern install_signals
  extern crt_clear
  extern select_1up_list_left
  extern select_list_engine
  extern read_stdin
  extern enviro_ptrs
  extern dir_browse_left
  extern key_string1
  extern crt_color_at
  extern move_cursor
  extern reset_clear_terminal
;
; NAME
;  project - setup projects
; INPUTS
;  * no parameters are passed to file_browse
; OUTPUT
; NOTES
; * source file: project.asm
; * This file is a standalone ELF binary.
; * ----------------------------------------------
;*******
;  
%define stdout 0x1
	
 [section .text]

global	_start
global main

_start:
main:
  call	signal_install		;install sig_WINCH, (screen resize)
  call	env_stack
;  call	crt_type
  call	mouse_enable

restart:
  call	read_window_size
menu1_loop:
 mov	esi,menu1_msg
 call	show_text_right		;display hints
 mov	edi,buf_top		;work area for menu display
 mov	esi,menu1_buttons	;menu buttton text
 call	select_1up_list_left
;
;
; returns al= 0 ESC pressed
;             1 setup a new project
;             2 delete a project listing
;             3 edit an existing project
;             4 add existing project to our database
;             5 exit project setup
;
  xor	ebx,ebx
  mov	bl,al
  shl	ebx,2
  add	ebx,menu1_jumps
  call	[ebx]
  cmp	byte [window_resize_flag],1
  jne	menu1_loop
  mov	byte [window_resize_flag],0
  jmp	short restart

menu1_jumps:
  dd	browser_exit
  dd	new_project
  dd	delete_project
  dd	edit_project
  dd	add_existing_project
  dd	browser_exit
;
browser_exit:
;  mov	eax,[_norm_color]
;  call	crt_clear
;  mov	ax,0101h		;cursor position
;  call	move_cursor
  call	reset_clear_terminal
  mov	eax,1
  mov	ebx,0			;normal exit
  int	0x80			;exit

;-----------------------------------------------------------
new_project:
  call	get_project_name
  cmp	byte [project_name],0
  jz	np_exit			;exit if escape typed
  mov	eax,[_norm_color]
  call	crt_clear
  mov	esi,file_browse_msg
  call	show_text_right		;display hints
;
; browse file system to select directory
;
  mov	esi,buf_top
  call	dir_browse_left
;  output: ebx = ptr to location if eax positive
;          eax = 0 for success 
;                negative for error
  or	eax,eax
  js	np_exit		;exit if no directory selected
  call	prep_form_newp	;setup form for new project
  call	fill_form
  or	eax,eax
  js	np_exit
  call	project_setup
  mov	al,0			;enable open of database
  call	project_write_tbl	;update and close database
np_exit:
  ret
;-----------------------------------------------------------
delete_project:
  mov	esi,project_delete_msg
  call	show_text_right		;display hints
  call	project_select
  or	eax,eax
  js	dp_exit
;
  mov	eax,ebx			;move index ptr to eax
  xor	edi,edi			;no save
  call	database_extract
dp_exit:
  call	database_close
  ret
;-----------------------------------------------------------
edit_project:
  mov	esi,file_edit_msg
  call	show_text_right		;display hints
  call	project_select
  or	eax,eax
  jns	ep_10
  call	database_close
  jmp	short ep_exit
ep_10:
  call	fill_form
  or	eax,eax
  js	ep_exit
  call	project_setup
  mov	al,1			;database already open flag
  call	project_write_tbl	;update and close database
ep_exit:
  ret
;-----------------------------------------------------------
add_existing_project:
  call	get_project_name
  cmp	byte [default_path],0
  jz	aep_exit		;exit if escape typed
  mov	eax,[_norm_color]
  call	crt_clear
  mov	esi,add_project_msg
  call	show_text_right		;display hints
;
; browse file system to select directory
;
  mov	esi,buf_top
  call	dir_browse_left
;  output: ebx = ptr to location if eax positive
;          eax = 0 for success 
;                negative for error
  or	eax,eax
  js	aep_exit		;exit if no directory selected
  call	prep_form_existingp	;setup form for new project
  call	fill_form
  or	eax,eax
  js	aep_exit
  call	project_setup
  mov	al,0			;enable open of database
  call	project_write_tbl	;update and close database
aep_exit:
  ret
;----------------------------------------------------------
get_project_name:
  mov	ecx,20			;clear name buffer
  mov	edi,project_name
  xor	eax,eax
  rep	stosb

  mov	eax,[_norm_color]
  call	crt_clear
  mov	eax,[_norm_color]
  mov	ecx,get_name_msg
  mov	bl,1
  mov	bh,9
  call	crt_color_at
  mov	ebp,get_name_table
  call	key_string1		;read name to project_name 
  ret
;---------------
  [section .data]
get_name_table:
  dd	project_name
  dd	20		;max string length
  dd	_norm_color	;color
  db	10		;row
  db	2		;column
  db	0		;no cr/lf in string
  db	2		;initial cursor column

project_name	times 21 db 0
get_name_msg:	db 'Name of project (max length 20 characters without spaces)',0ah,'>',0  
  [section .text]

;-----------------------------------------------------------
; setup form for new project creation.
;  inputs;  project_name
;          ebx = ptr to path if eax positive
;          eax = 0 for success 
;
; output:  buf1 = project name
;          buf2 = project directory
;          buf3 = project path
;  
prep_form_newp:
  mov	[proj_path_ptr],ebx
;clear out current form contents 
  mov	edi,buf1
  call	clear			;clear name field
  mov	edi,buf2
  call	clear			;clear proj dir field
  mov	edi,buf3
  call	clear			;clear project path field
; move project name to buf1
  mov	esi,project_name
  mov	edi,buf1
  call	str_move
  mov	byte [edi],' '		;remove zero at end of path
; move project name to buf2
  mov	esi,project_name
  mov	edi,buf2
  call	str_move
  mov	byte [edi],' '		;remove zero at end of path
;move project path to buf3
  mov	esi,[proj_path_ptr]
  mov	edi,buf3
  call	str_move
  mov	byte [edi],' '
  ret

;-----------------------------------------------------------
; setup form for existing project.
;  inputs;  project_name
;          ebx = ptr to path if eax positive
;          eax = 0 for success 
;
; output:  buf1 = project name
;          buf2 = project directory
;          buf3 = project path
;  
prep_form_existingp:
  mov	[proj_path_ptr],ebx
;clear out current form contents 
  mov	edi,buf1
  call	clear			;clear name field
  mov	edi,buf2
  call	clear			;clear proj dir field
  mov	edi,buf3
  call	clear			;clear project path field
; move project name to buf1
  mov	esi,project_name
  mov	edi,buf1
  call	str_move
  mov	byte [edi],' '		;remove zero at end of path
; move project dir to buf2
  mov	esi,[proj_path_ptr]
pfe_lp1:
  lodsb
  or	al,al
  jnz	pfe_lp1			;scan to end of path
pfe_lp2:
  dec	esi
  cmp	byte [esi],'/'
  jne	pfe_lp2			;find start of dir
  mov	byte  [esi],0		;separate out dir
  mov	[zero_ptr],esi		;save truncate point
  inc	esi
  mov	edi,buf2
  call	str_move
  mov	byte [edi],' '		;remove zero at end of path
;move project path to buf3
  mov	esi,[proj_path_ptr]
  mov	edi,buf3
  call	str_move
  mov	byte [edi],' '
  mov	esi,[zero_ptr]
  mov	byte [esi],'/'		;restore '/'
  ret
;-------------------
  [section .data]
proj_path_ptr	dd	0
  [section .text]
;-------------------
; input: edi = form entry ptr
clear:
  mov	al,' '
clp:
  stosb
  cmp	byte [edi],' '	;end of field?
  jae	clp
  ret

;-----------------------------------------------------------
signal_install:
  mov	ebp,signal_table
  call	install_signals
  ret

signal_uninstall:
  mov	dword [sig_mod1],0
  call	signal_install
  mov	dword [sig_mod1],winch_signal
  ret

winch_signal:
  call	read_window_size
  mov	byte [window_resize_flag],1
  ret
;-----------------------------------------------
%include "proj_msg.inc"
%include "project_form.inc"
%include "project_setup.inc"
%include "project_write_tbl.inc"
%include "project_select.inc"
;------------------------------------------------

;----------
  [section .data]
window_resize_flag:  db  0
;----------
signal_table:
  db	28
sig_mod1:
  dd	winch_signal
  dd	0
  dd	0
  dd	0
  db	0		;end of install table

;------------------------

menu1_buttons:
 db 'setup a new project',0
 db 'delete a project listing',0
 db 'edit an existing',0ah,'project',0
 db 'add existing project',0ah,'to our database',0
 db 'exit project setup',0
 db 0

path1:  db '/home/jeff',0

  [section .bss]

buf_top: resb 80000		;used for file browse & selection display

default_path	resb	200 	;also holds project names for selection

dbuf	resb	20000		;holds project file


