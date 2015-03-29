
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
;
;>1 utility
;  Copy - delete files if no matching file
; INPUTS
;    usage: copy <delete_dir+mask> <compare dir>
;           where;
;                  <delete_dir+mask> = path with possible "*"
;                              examples: /home/dog/
;                                        "/home/doc/*"
;                                        "/home/cat*"
;                  <compare_dir> = directory with files
; OUTPUT
;    none
; NOTES
;   source file:  delete_if.asm
;   if a wild character "*" is used, it must be part
;   of file name (at end of path).
;   If a path ends with "/" the assumed file name is
;   "*" or all files.
;   If path does not start with "/" then the current dir
;   is assumed starting point.
;   The parameters with "*" must be quoted to avoid
;   confusing the shell.
;   Legal use of "*" is:   "file*"
;                          "*file"
;                          "/*"
;    
;<
; * ----------------------------------------------
;
;
  extern env_stack
  extern crt_clear

;  extern dir_walk
%include "dir_walk.inc"

  extern str_move
  extern get_current_path
  extern crt_str
  extern str_replace
  extern file_status_name

;  extern file_copy

  extern str_compare
  extern memory_init
  extern file_delete

%include "system.inc"

  global main,_start
main:
_start:
  cld
  mov	eax,[background_color]
  call	crt_clear
  call	env_stack
;parse inputs
  call	parse
  jc	copy_exit	;jmp if error
  call	build_del_dir_mask	;build from path and mask
  call	memory_init
  mov	[walk_buffer_ptr],eax  
;start walk
  mov	esi,delete_dir_path
  mov	ebx,delete_dir_file_mask
  mov	ch,2		;return files
  mov	cl,0		;recursion depth
;walk_it:
  mov	eax,[walk_buffer_ptr]
  mov	edx,delete_walk_process
  call	dir_walk
;check if delete flag set
copy_exit:
  mov	ebx,eax		;return status setup  
  mov	eax,1
  int	byte 80h

;-------------------------------------------------
;input: eax=ptr to full path with file
;       ecx=ptr to current match at end of path
;       [lib_buf] has stat struc
;output: eax=0 to continue
delete_walk_process:
  mov	esi,eax		;ptr to "compare_dir_path"
  mov	[saved_del_dir_path],eax
dwp_lp1:
  lodsb
  or	al,al
  jnz	dwp_lp1		;loop till end of path
dwp_lp2:
  dec	esi
  cmp	[esi],byte '/'
  jne	dwp_lp2		;loop till start of file name
  push	esi		;save ptr
;setup "from" path
  mov	esi,compare_dir_path
  mov	edi,current_compare_dir_path
  call	str_move
  pop	esi		;restore file
  call	str_move	;add file at end
;check if file exists
  mov	ebx,current_compare_dir_path
  call	file_status_name
  jns	dwp_exit
;"del" file  does not have "compare" mate, delete the "to" file
  mov	ebx,[saved_del_dir_path]
  call	file_delete
dwp_exit:
  xor	eax,eax		;set continue flag
  ret
;---------
  [section .data]
saved_del_dir_path: dd 0
  [section .text]
;---------
  [section .data]
delete_dir_ptr:	dd 0
asterisk_char	db '*',0
  [section .text]
;-------------------------------------------------
parse:
  mov	esi,esp		;get stack ptr
  lodsd			;get return address (ignore)
  lodsd			;number of parameters
  mov	ecx,eax
  dec	ecx
  jecxz	parse_errorj
  lodsd			;get our filename (ignore)
  lodsd			;get first parameter
  or	eax,eax
  jnz	pup_ck1		;jmp if parameter found
parse_errorj:
  jmp	parse_error
  lodsd			;get parameter ptr
;save delete path
pup_ck1:
  push	esi
  mov	esi,eax
  mov	edi,delete_dir_path
  call	str_move
  pop	esi
;save to path
  lodsd
  or	eax,eax
  jz	parse_error	;jmp if no destination file
  push	esi
  mov	esi,eax
  mov	edi,compare_dir_path
  call	str_move
  pop	esi
;it is a very common error to forget the "quotes" around parameters.
;this causes a file to be overwritten.. ouch.
;check if possible wild card expansion by shell here
  lodsd
  or	eax,eax
  jz	pup_ok		;jmp if expected end
  mov	ecx,err3_msg
  jmp	parse_error2
pup_ok:
  clc
  jmp	short parse_exit

;show state message
parse_error:
  mov	ecx,err1
parse_error2:
  call	crt_str
  stc
parse_exit:
  ret
;-------------------------------------------------
;input:  complete path at [delete_dir_path]
;operation: -check if wild card, if true set mask
;           -check if dir, if true set mask to *
;           -check if single file, if true set mask to file
;           -if none of above return error
build_del_dir_mask:
  mov	esi,delete_dir_path
  cmp	byte [esi],'/'		;full path
  je	bfm_10			;jmp if full path
;insert local path
  mov	ebx,buffer
  mov	ecx,500			;buffer size
  call	get_current_path	;fills in path
;move to end of path
  mov	esi,buffer
delete_dir_end:
  lodsb
  or	al,al
  jnz	delete_dir_end
  dec	esi
  mov	edi,esi
  mov	esi,delete_dir_path
;check if path starts with ../ ;
bfm_02:
  cmp	word [esi],'..'
  jne	bfm_05		;jmp if not ..
;move back one dir
  add	esi,3
bfm_lp1:
  dec	edi
  cmp	[edi],byte '/'
  je	bfm_02
  jmp	short bfm_lp1

bfm_05:
  cmp	byte [esi],'.'	;check for ./ ;
  jne	bfm_08		;jmp if not ./ ;
  add	esi,2		;move past ./ ;
bfm_08:
  mov	al,'/'
  stosb			;insert / ;
  call	str_move	;build full path in buffer
  mov	esi,buffer
  mov	edi,delete_dir_path
  call	str_move	;move full path to delete_dir_path
  mov	esi,delete_dir_path
;startng_path now has full path
bfm_10:
  call	wild_check	;esi points to
  mov	[delete_dir_wild_flag],al ;0=none 1=front 2=back 3=all
bfm_50: 
  mov	edi,delete_dir_file_mask
  call	str_move
  mov	[delete_dir_file_mask_end_ptr],edi
  ret
;-------------------------------------------------
;input: esi=path ptr
;retuns ptr to file name (esi)
; al = wild flag setting 0=none 1=front 2=back 3=all
; appends "*" if path ends with "/"
wild_check:
  mov	[wild_flag],byte 0
wc_lp1:
  lodsb
  or	al,al
  jz	wc_40		;jmp if at end
  cmp	al,'*'
  je	wc_10		;jmp if wild found
  cmp	al,'/'
  jne	wc_lp1
  inc	dword [slash_count]
  jmp	short wc_lp1
wc_10:
  mov	[wild_flag],byte 1
  jmp	short wc_lp1
;we are at end of path, check if wild
wc_40:
  cmp	[wild_flag],byte 0
  je	no_wild
;assume path ends with wild file
wc_50:
  dec	esi
  cmp	[esi],byte '/'
  jne	wc_50	;go back to '/'
  inc	esi	;move beyond '/'
  mov	al,2	;wild front flag
  cmp	[esi],byte '*' ;wild on front?
  jne	wild_exit	;jmp if wild at back
  mov	al,3		;wild all
  cmp	[esi+1],byte 0
  je	wild_exit	;jmp if wild all
  mov	al,1		;wild on front
  jmp	short wild_exit

no_wild:
  dec	esi
  cmp	byte [esi-1],'/'
  je	wild_append
;there is file at end of path, go to start of file
wc_60:
  dec	esi
  cmp	[esi],byte '/'
  jne	wc_60	;go back to '/'
  inc	esi	;move beyond '/'
  mov	al,0
  jmp	short wc_exit

wild_append:
  mov	byte [esi],'*'
  mov	byte [esi+1],0
  mov	al,3		;wild all
wild_exit:
       
wc_exit:
  mov	[esi-1],byte 0	;truncate path, esi=ptr to file
  ret
;--------------------------------
  [section .data]
slash_count	dd 0
wild_flag:	db 0
  [section .text]
;-------------------------------------------------

;********************************************************************
;********************************************************************

  [section .data]
background_color dd 30003730h
;content_flag	db 0	;1=copy if contents dif
;time_flag	db 0	;1=copy if date newer
;size_flag	db 0	;1=copy if size chane
;force_flag	db 1	;default = always copy
;recurse_flag	db 1	;recurse dirs
delete_flag	db 0	;delete if not present at delete_dir_path
append_flag	db 0	;0=no append 1=append request 2=append active
overwrite_flag	db 0	;0=not overwriting 1=current file will overwrite
overwrite_tail_top	db 0	;must be infront of overwrite_ignore_tail
overwrite_ignore_tail	times 20 db 0 ;if non-zero, ignore overwriting tail match
attribute_flag	db 0	;0=preserve attributes 1=default attributes
saved_attributes dd 0	;attributes of existing file, + extra to zero register

err1: db 0ah,'Usage: delete_if <delete_path_mask> <compare_dir>',0ah,0
err2_msg:
      db 0ah,'Error -input file not found',0h,0
walk_buffer_ptr	dd 0
err3_msg:
      db 0ah,'Error - parameters found after second file name',0ah
      db     'Did you forget to put quotes around files with astricks?',0ah
      db     'wildcard mask -> delete_if "path*.gz  path"',0ah,0
;------------------------------------------------------------------
  [section .bss]
delete_dir_path	resb 250
delete_dir_file_mask	resb 100
delete_dir_file_mask_end_ptr resd 1	;end of mask string
delete_dir_wild_flag	resb 1		;0-no 1=front 2=back 3=all

compare_dir_path		resb 250
compare_dir_wild_flag	resb 1		;0=no 1=front 2=back 3=all
current_compare_dir_path: resb 250

;buffer is used in startup as work buf
buffer:	resb	8096


