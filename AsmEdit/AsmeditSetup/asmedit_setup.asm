
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
;>1 plugin
; asmedit_setup - menu style setup for AsmEdit
; INPUTS
;    usage:  asmedit_setup
;            The displayed form can be updated using
;            mouse clicks, or arrow keys to select
;            fields.  All fields also have single
;            key select codes (alt-x).
; OUTPUT
;    The configuration file at $HOME/.a.ini is
;    updated.
; NOTES
;   source file: asmedit_setup.asm
;   if $HOME/.a.ini does not exist it will be  
;   created.
;<
; * ----------------------------------------------
;*

 extern crt_clear
 extern crt_open,crt_close
 extern crt_data
 extern	exit_screen_color,status_color
 extern build_homepath
 extern dir_status
 extern file_status_name
 extern	str_move
 extern mouse_enable
 extern crt_str
 extern crt_table
 extern key_mouse1
 extern kbuf
 extern cursor_to_table 
 extern file_list_copy,file_copy
 extern dir_create
 extern crt_rows
 extern key_string1
 extern form
 extern dword_to_l_ascii
;extern file_write_close
 extern block_write_home_all
 extern ascii_to_dword
 extern file_read_all
 extern env_home

global	main
global _start

	[section .text]

_start:
main:
  cld
  call	crt_open
  call	mouse_enable
  mov	eax,[exit_screen_color]
  call	crt_clear
;
; get env and parameters
;
  mov	esi,esp
  lodsd				;get parameter count
  cmp	eax,2
  jb	env_lp			;jmp if no parameters
  lodsd				;get ptr to program name
env_lp:
  lodsd
  or	eax,eax
  jnz	env_lp
  mov	[env_ptr],esi
;
; check if a.ini exits
;
ac_02:
  mov	ebx,esi			;enviro_ptrs
  mov	edi,tmp_path
  call	env_home
  mov	al,'/'
  stosb
  mov	esi,a_ini_write
  call	str_move

  mov	ebx,tmp_path
  call	file_status_name
  js	ac_84			;jmp if a.ini not found
;
; -------------
; setup to fill in config form
;
ac_80:
;
; setup to read the a.ini file
;
  mov	ebp,a_ini_write		;file name
  mov	ecx,top_of_a_ini	;buffer
  mov	edx,a_ini_size
  mov	al,2			;file at $HOME/.a/a.ini
  mov	ebx,[env_ptr]
  call	file_read_all		
; js	error_handler
;
; setup to fill in form
;
ac_84:
  call	stuff_form_data		;move data from a.ini to form
;
; display edit screen
;
  mov	eax,[exit_screen_color]
  call	crt_clear
  mov	esi,table_pointers
  call	form
;
; extract data from form and update a.ini
;
  call	extract_form_data	;move data from form to a.ini
;
; write updated a.ini
;
  mov	ebx,a_ini_write		;file name
  mov	ecx,top_of_a_ini	;data to write
  mov	esi,a_ini_size		;length of write
;  mov	esi,0ah			;write to $HOME or full path if given
  mov	edx,666q		;attributes  
;  mov	ebp,[env_ptr]
  call	block_write_home_all

ac_exit:
  mov	ebx,0
ac_exit2:
  push	ebx
  mov	eax,[exit_screen_color]
  call	crt_clear
  call	crt_close
  pop	ebx
  mov	eax,1
  int	80h		;exit  

;-------------------------------------------------------------------
; stuff_form_data - move data from a.ini to form
;  inputs:  [table_pointers] (see display_table.inc)
;           (see a.inc) file a.ini
;
stuff_form_data:
  mov	al,[mouse_mode]			;0=no menu 1=main menu 9=ide
  cmp	al,0
  je	mm_1
  cmp	al,1
  je	mm_2
  mov	byte [dt_b1],selected_color
  jmp	short sf_key_mode
mm_1:
  mov	byte [dt_b3],selected_color
  jmp	short sf_key_mode
mm_2:
  mov	byte [dt_b2],selected_color
;
; check key_mode
;
sf_key_mode:
  cmp	byte [key_mode],1		;check if edit mode
  je	edit_mode
  mov	byte [dt_bc1],selected_color
  jmp	short sf_ins_modes
edit_mode:
  mov	byte [dt_bc2],selected_color
;
; check insert_overtype
;
sf_ins_modes:
  cmp	byte [insert_overtype],1	;check if insert
  je	sfd_insert
;
; default mode is overtype
;
  mov	byte [dt_bc3],button_color	;deselect insert
  mov	byte [dt_bc4],selected_color	;select overtype
  jmp	sfd_10
;
; default mode is insert
;
sfd_insert:
  mov	byte [dt_bc3],selected_color	;select insert
  mov	byte [dt_bc4],button_color	;deselect overtype  
;
; check case_mask
;
sfd_10:
  cmp	byte [case_mask],0dfh
  je	ignore_case
  mov	byte [dt_yc4],selected_color
  jmp	short sfd_12
ignore_case:
  mov	byte [dt_yc3],selected_color
;
; fill in backup state
;
sfd_12:
  cmp	byte [backup_flag],1
  je	backup_enabled
  mov	byte [dt_yc6],selected_color
  jmp	sfd_16
backup_enabled:
  mov	byte [dt_yc5],selected_color
;
; fill in left margin
;
sfd_16:
  xor	eax,eax
  mov	al,[left_margin]
  mov	edi,buf4
  mov	esi,2
  call	dword_to_l_ascii
  call	blank_fend
;
; fill in right margin
;
  xor	eax,eax
  mov	al,[right_margin]
  mov	edi,buf5
  mov	esi,2
  call	dword_to_l_ascii
  call	blank_fend
;
; move browser string
;
sfd_20:
  mov	esi,web_browser			;source, terminated with zero
  mov	edi,buf08			;destination terminated with space
  call	move_to_table
  call	blank_fend			;blank end of field
;
; move email client string
;
  mov	esi,email_client
  mov	edi,buf06
  call	move_to_table
  call	blank_fend
;
; move other to table
;
  mov	esi,who_knows
  mov	edi,buf3
  call	move_to_table
  call	blank_fend
;
; fill in confirm state
;
  cmp	byte [confirm_flag],1
  je	confirm_enabled
  mov	byte [dt_no],selected_color
  jmp	sfd_56
confirm_enabled:
  mov	byte [dt_yes],selected_color
sfd_56:
  ret

;-------------------------------------------------------------------
; inputs:  esi = a.ini string terminated by space
;          edi = table field, terminated by space and then 01-09
;
move_to_table:
  cmp	byte [edi],9
  jbe	mtt_exit		;exit if at end of table area
  lodsb
  cmp	al,0
  je	mtt_exit		;exit if at end of a.ini string
  cmp	al,' '
  je	mtt_exit		;exit if space in name
  stosb
  jmp	move_to_table
mtt_exit:
  ret
;-------------------------------------------------------------------
; extract_form_data - move form data to a.ini file
;  inputs:  [table_pointers] (see display_table.inc)
;           file a.ini (see a.inc)
;
extract_form_data:
  mov	al,9				;keyboard mode
  cmp	byte [dt_b1],selected_color
  je	efd_set0
  mov	al,1
  cmp	byte [dt_b2],selected_color
  je	efd_set0
  mov	al,0
efd_set0:
  mov	[mouse_mode],al

  mov	al,0				;preload overtype mode
  cmp	byte [dt_bc4],selected_color
  je	efd_set1			;jmp if overtype mode
  mov	al,1				;insert code
efd_set1:
  mov	[insert_overtype],al
;
  mov	al,0				;preload CMD mode
  cmp	byte [dt_bc1],selected_color
  je	efd_set2			;jmp if CMD mode
  mov	al,1				;edit mode
efd_set2:
  mov	[key_mode],al

  mov	al,0ffh				;use case flag
  cmp	byte [dt_yc3],selected_color
  jne	efd_set3
  mov	al,0dfh
efd_set3:
  mov	[case_mask],al

  mov	esi,buf4			;left margin
  call	ascii_to_dword
  cmp	cl,0
  jne	efd_ok1				;jmp if left margin ok
  mov	cl,1
efd_ok1:
  mov	[left_margin],cl

  mov	esi,buf5			;right margin
  call	ascii_to_dword
  mov	[right_margin],cl
;
; get browser name from form
;
  mov	esi,buf06			;0-9 terminated
  mov	edi,web_browser			;zero terminated
  call	move_name
;
; get email client name
;
  mov	esi,buf08
  mov	edi,email_client
  call	move_name

  mov	esi,buf3
  mov	edi,who_knows
  call	move_name

  mov	al,1				;confirm exit
  cmp	byte [dt_yes],selected_color
  je	exd_set3
  mov	al,0				;no confirm exit
exd_set3:
  mov	[confirm_flag],al
  ret

;------------------------------------------------------------------
; move_name 
;
move_name:
  cmp	byte [esi],9
  jbe	mn_done
  movsb
  jmp	move_name
mn_done:
  xor	eax,eax
  stosb				;put zero at end
  ret

;-------------------------------------------------------------------
; blank end of field after asciiz move completes
;  inputs: edi = ptr past last zero stored
;
blank_fend:
  mov	al,' '		;preload blanking space
bf_lp:
  cmp	byte [edi],9
  jbe	bf_exit		;exit if at end of field
  stosb			;zap zero at end of string
  jmp	bf_lp
bf_exit:
  ret
;-------------------------------------------------------------------
; move_string - move asciiz string
;  inputs:  esi=input ptr to asciiz string
;           edi= output buf 
; output: edi points at zero (end of asciiz string)
;
move_asciiz:
move_string:
  cld
ms_loop:
  lodsb
  stosb
  or	al,al
  jnz	ms_loop	;loop till done
  dec	edi
  ret

;--------------------------------------------------------
  [section .data]

a_ini_write: db '.a.ini',0

%include "../a.inc"

%include "table_display.inc"

;--------------------------------------------------------
  [section .bss]

env_ptr:	resd	1	;ptr to stack env pointers
tmp_path	resd	100	;path buffer
fbuf		resb	20000


