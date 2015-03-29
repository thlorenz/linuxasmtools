
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
;  Copy - copy files if
; INPUTS
;    usage: copy <switches> <in_file_mask> <out_file_mask>
;           where; <switches> = -c copy if content change
;                               -t copy if time/date change
;                               -s copy if size change
;                               -f copy always (default)
;                               -d delete if
;                               -n xxx  no overwrite of files with xxx tail 
;                  <in_file> = path with possible "*"
;                              examples: /home/dog/
;                                        "/home/doc/*"
;                                        "/home/cat*"
;                  <out_file> = path with possible "*"
; OUTPUT
;    none
; NOTES
;   source file:  copy.asm
;   file paths can end with file or "/" for directory.
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
%include "file_copy.inc"

  extern str_compare
  extern memory_init
  extern file_delete
  extern block_open_read
  extern block_open_append
  extern file_write

%include "system.inc"
%include "file_compare.inc"

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
  call	build_from_mask	;build from path and mask
  call	build_to_mask
  jc	copy_exit	;exit if dir illegal
  call	memory_init
  mov	[walk_buffer_ptr],eax  
;start walk
  mov	esi,from_path
  mov	ebx,from_file_mask
  mov	ch,2		;return files
  mov	cl,0		;recursion depth
;  cmp	[recurse_flag],byte 0
;  je	walk_it		;jmp if no recursion
;  mov	cl,99		;set max recursion level
;walk_it:
  mov	eax,[walk_buffer_ptr]
  mov	edx,walk_process
  call	dir_walk
;check if delete flag set
  cmp	[delete_flag],byte 0 ;delete?
  je	copy_exit	;jmp if no delete
;setup to walk to path for delete
  mov	esi,to_path
walk2_lp:
  lodsb
  or	al,al
  jnz	walk2_lp	;loop till end of path
walk2_lp2:
  dec	esi
  cmp	[esi],byte '/'
  jne	walk2_lp2
;we have found "to" path tail
  mov	[esi],byte 0	;terminate dir path
  inc	esi		;move to start of file
  mov	ebx,esi		;ebx=file mask
  mov	esi,to_path	;esi=dir to walk
  mov	eax,[walk_buffer_ptr]
  mov	edx,delete_walk_process
  mov	ch,2		;return files
  mov	cl,0		;recursion depth
  call	dir_walk
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
  mov	esi,eax		;ptr to "to_path"
  mov	[saved_to_path],eax
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
  mov	esi,from_path
  mov	edi,current_from_path
  call	str_move
  pop	esi		;restore file
  call	str_move	;add file at end
;check if file exists
  mov	ebx,current_from_path
  call	file_status_name
  jns	dwp_exit
;"to" file  does not have "from" mate, delete the "to" file
  mov	ebx,[saved_to_path]
  call	file_delete
dwp_exit:
  xor	eax,eax		;set continue flag
  ret
;---------
  [section .data]
saved_to_path: dd 0
  [section .text]
;-------------------------------------------------
;input: eax=ptr to full path with file
;       ecx=ptr to current match at end of path
;       [lib_buf] has stat struc
;output: eax=0 to continue
walk_process:
  mov	[force_flag],byte 1	;default state = do copy
  mov	[from_ptr],eax
  call	find_plug_string
  mov	esi,to_path
  mov	edi,current_to_path
  call	str_move
  cmp	[to_wild_flag],byte 0	;normal file?
  je	wp_10			;jmp if normal file
;replace "*" with plug
  mov	eax,plug_string
  mov	esi,asterisk_char	;asterisk
  mov	edi,current_to_path
  call	str_replace
;check if target file exists
wp_10:
  mov	[overwrite_flag],byte 0
  mov	ebx,current_to_path
  call	file_status_name	;get file status
  jns	wp_15			;jmp if file found
  jmp	do_copy3		;jmp if file not found
wp_15:
  mov	ebx,[ecx+stat_struc.st_size]
  mov	[size_to_file],ebx
  mov	ebx,[ecx+stat_struc.st_ctime]
  mov	[time_to_file],ebx
  mov	[overwrite_flag],byte 1	;this is overwrite of file
;check user flags
;check if size flag specified
  cmp	[size_flag],byte 1
  jne	wp_40			;jmp if no size check
  mov	ebx,[from_ptr]		;get from file name
  call	file_status_name
  jns	wp_20			;jmp if file found
;error -from- file not found
  mov	ecx,err2_msg
  call	crt_str
wp_err_exitj:
  jmp	wp_err_exit  
wp_20:
  mov	eax,[ecx+stat_struc.st_size] ;get size -from-
  cmp	eax,[size_to_file]
  jne	do_copy2		;jmp if size mismatch
  mov	[force_flag],byte 0	;disable forced copy
;check if time flag specified
wp_40:  
  cmp	[time_flag],byte 1	;time check?
  jne	wp_60			;jmp if no time check
  mov	[force_flag],byte 0	;disable forced copy
  mov	eax,[ecx+stat_struc.st_ctime] ;get time -from-
  cmp	eax,[time_to_file]
  jb	do_copy2		;jmp if -from- newer
  mov	[force_flag],byte 0	;disable forced copy
;check if content flag specified
wp_60:  
  cmp	[content_flag],byte 1
  jne	do_copy			;jmp if no content check
;compare files
  call	compare_files
  je	wp_exitj		;exit if files compare
  js	wp_err_exitj		;exit if open/read error
  jmp	short do_copy2
wp_exitj:
  jmp	wp_exit
do_copy:
  cmp	[force_flag],byte 0
  je	wp_exitj		;exit if copy disabled
do_copy2:
  cmp	[overwrite_flag],byte 0
  je	do_copy3	;jmp if not overwriting
  cmp	[overwrite_ignore_tail],byte 0
  je	do_copy3	;jmp if all files can overwrite
;check if this file is to be skipped
  mov	esi,current_to_path
overwrite_lp1:
  lodsb
  or	al,al
  jnz	overwrite_lp1	;find end
  mov	edi,esi
  mov	esi,overwrite_ignore_tail
overwrite_lp2:
  lodsb
  or	al,al
  jnz	overwrite_lp2
  sub	esi,byte 2	;move to start of data
  sub	edi,byte 2	;move to start of data
;now check if match
  std
overwrite_cmp_lp:
  cmp	[esi],byte 0	;done
  je	copy_return	;jmp if match
  cmpsb
  je	overwrite_cmp_lp
  cld
do_copy3: 
  call	check_copy	;check if legal copy
  jc	wp_err_exit
;get "from" file attributes and save
  mov	ebx,[from_ptr]
  call	file_status_name
  js	wp_err_exit	;exit if file not found
  mov	bx,[ecx+stat_struc.st_mode]
  cmp	[attribute_flag],byte 0
  jne	copy_setup	;jmp if default attributes wanted
  mov	[saved_attributes],bx
copy_setup:
;  mov	ch,1		;full path for input
;  mov	cl,1		;full path for target
  mov	ebx,[from_ptr]
  mov	edx,current_to_path
  cmp	[append_flag],byte 0
  je	non_append
  call	append_copy
  jmp	short copy_return
non_append:
  mov	eax,[saved_attributes]	;get attributes
  call	file_copy
copy_return:
  cld			;needed due to overwrite cmp loop  
  or	eax,eax
  js	wp_err_exit
wp_exit:
  xor	eax,eax		;flag normal continue
wp_err_exit:		;eax=non zero if error
  ret
;---------
  [section .data]
from_ptr:	dd 0
size_to_file	dd 0
time_to_file	dd 0
asterisk_char	db '*',0
  [section .text]
;-------------------------------------------------
;append_copy - copy and append to "to" path
;input: ebx = from path
;       edx = to path
;       [append_flag] = 1=start 2=inprocess
;output: eax = negative if error
append_copy:
  push	edx			;save -to- path
;
; open (from)
;
  call	block_open_read
  pop	ebx			;restore "to" path
  js	ac_exit1		;exit if error
  mov	[ac_from_handle],eax
;
; open destination
;
  cmp	[append_flag],byte 1
  jne	ac_loop
  mov	[append_flag],byte 2	;set inprocess state
; open append file
  xor	edx,edx		;file perissions
  call	block_open_append
  js	ac_exit1
  mov	[ac_to_handle],eax
;
; read block
;
ac_loop:
  mov	ebx,[ac_from_handle]
  mov	edx,4096		;buffer size
  mov	ecx,buffer
  call	file_read
  js	ac_exit 		;exit if error
  jz	ac_exit			;jmp if all data written
;
; write block
;
  mov	ebx,[ac_to_handle]
  mov	edx,eax			;get size of last read
  mov	ecx,buffer
  call	file_write
  jmp	short ac_loop
;
ac_exit:
ac_exit2:
  mov	ebx,[ac_from_handle]
  call	file_close
ac_exit1:
  ret

  [section .data]
ac_from_handle	dd	0
ac_to_handle	dd	0
  [section .text]

  ret
;-------------------------------------------------
; check if copying to self
; check if copy to directory
;input: [from_ptr]
;       current_to_path
;output: jc if error and message displayed
;        jne if ok
check_copy:
  mov	esi,[from_ptr]
  mov	edi,current_to_path
  call	str_compare
  je	cc_err1
  mov	ebx,current_to_path
  call	file_status_name	;get file status
  js	cc_exit1		;exit if file/dir does not exist
  test	[ecx+stat_struc.st_mode],word 40000q	;directory?
  jz	cc_exit1		;jmp if not directory
;error, copying to dir
  mov	ecx,cc_msg2
  jmp	short cc_err
cc_err1:
  mov	ecx,cc_msg1
cc_err:
  call	crt_str
  stc
  jmp	short cc_exit
cc_exit1:
  clc
cc_exit:
  ret
;--------------
  [section .data]
cc_msg1: db 0ah,'Error, copying file to self',0ah,0
cc_msg2: db 0ah,'Error, copying file to dir',0ah,0
  [section .text]
;-------------------------------------------------
;input: current_to_path
;       [from_ptr]
;output: 0=(jz) compared ok
;        neg = error
;        +   = compare fail
;buffers: from_compare_buf
;         to_compare_buf
compare_files:
  mov	ebx,current_to_path
  mov	edx,[from_ptr]
  mov	eax,from_compare_buf
  mov	ecx,to_compare_buf
  call	file_compare
  ret
;-------------------------------------------------
;input:
;  ecx=ptr to filename
;output:
;  plug_string - built  
find_plug_string:
  xor	eax,eax
  mov	al,[from_wild_flag]
  shl	eax,2		;make dword index
  add	eax,jtable
  jmp	[eax]		;jmp to processing
;--
all_wild_file:	;3
  mov	esi,ecx
  jmp	short save_plug
;--
back_wild_file: ;2
  mov	esi,ecx		;get ptr to file
  mov	edi,from_file_mask
bwf_lp:
  cmpsb
  je	bwf_lp		;loop till "*"
  dec	esi
  jmp	short save_plug
;--
front_wild_file: ;1
  mov	esi,ecx		;get match file
fwf_lp:
  lodsb
  or	al,al
  jnz	fwf_lp		;loop till end of match
;now work back till "*"
  dec	esi		;move back to 0
  mov	edi,[from_file_mask_end_ptr]
  std
bak_lp:
  cmpsb
  je	bak_lp
  cld
;we have found "*" esi=end of plug  ecx=start of plug
  push	ecx		;save start
  sub	esi,ecx	;compute length of plug
  mov	ecx,esi		;ecx = length
  add	ecx,byte 2	;adjust
  pop	esi		;restore start
move_plug:
  mov	edi,plug_string
  rep	movsb
  mov	al,0
  stosb			;put zero at end of plug
  jmp	short fps_exit
;--
normal_file:	;0
  mov	[plug_string],byte 0 ;force null plug
  cmp	[to_wild_flag],byte 0 ;did dest. have "*"
  je	fps_exit	;exit if no wild card found
;assume "to" filename same as "from"
  mov	esi,ecx		;from filename
save_plug:
  mov	edi,plug_string
  call	str_move
fps_exit:
  ret

;-------------
  [section .data]
jtable: dd normal_file
        dd front_wild_file
        dd back_wild_file
        dd all_wild_file
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
pup_loop:
  lodsd			;get parameter ptr
  or	eax,eax
  jnz	pup_ck1		;jmp if parameter found
  cmp	[to_path],eax ;check if filename entered
  jz	parse_errorj	;jmp if no filename (state display)
  jmp	pup_ok
pup_ck1:
  cmp	word [eax],'-c'	;-compare?
  jne	pup_ck2
  mov	[content_flag],byte 1 ;enable x server window list
  jmp	short pup_loop  
pup_ck2:
  cmp	word [eax],'-t'	;-t time/date?
  jne	pup_ck3
  mov	[time_flag],byte 1
  jmp	short pup_loop

pup_ck3:
  cmp	word [eax],'-s'	;-s size?
  jne	pup_ck4
  mov	[size_flag],byte 1
  jmp	short pup_loop
pup_ck4:
  cmp	word [eax],'-h'	;-h help?
  jne	pup_ck5
  jmp	short parse_error
pup_ck5:
  cmp	word [eax],'-d'	;-d delete?
  jne	pup_ck6
  mov	[delete_flag],byte 1
  jmp	short pup_loop
pup_ck6:
  cmp	word [eax],'-n'	;-n no overwrite
  jne	pup_ck7
  lodsd			;get next parameter
  push	esi
  mov	esi,eax
  mov	edi,overwrite_ignore_tail
  call	str_move
  pop	esi
  jmp	short pup_loop
pup_ck7:
  cmp	word [eax],'-a'	;-a attribute default
  jne	pup_ck8
  mov	[attribute_flag],byte 1
  jmp	pup_loop

pup_ck8:
;save from path
  push	esi
  mov	esi,eax
  mov	edi,from_path
  call	str_move
  pop	esi
;save to path
  lodsd
  or	eax,eax
  jz	parse_error	;jmp if no destination file
  push	esi
  mov	esi,eax
  mov	edi,to_path
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
;output:  carry set if error
;
build_to_mask:
  mov	esi,to_path
  cmp	byte [esi],'/'
  je	to_10			;jmp if full path
;insert local path
  mov	ebx,buffer
  mov	ecx,500
  call	get_current_path
;move to end of path
  mov	esi,buffer
to_end:
  lodsb
  or	al,al
  jnz	to_end
  dec	esi
  mov	edi,esi
  mov	esi,to_path
;check if path starts with ../ ;
to_02:
  cmp	word [esi],'..'
  jne	to_05		;jmp if not ..
;move back one dir
  add	esi,3
to_lp1:
  dec	edi
  cmp	[edi],byte '/'
  je	to_02
  jmp	short to_lp1

to_05:
  cmp	byte [esi],'.'	;check for ./  ;
  jne	to_08		;jmp if not ./ ;
  add	esi,2		;move past ./  ;
to_08:
  mov	al,'/'
  stosb			;insert /
  call	str_move	;build full path in buffer
  mov	esi,buffer
  mov	edi,to_path
  call	str_move	;move full path to to_path
  mov	esi,to_path
;startng_path now has full path
to_10:
  call	wild_check	;esi points to
  mov	[to_wild_flag],al ;0=none 1=front 2=back 3=all
;check if to path exists
  push	esi
  push	eax
  mov	ebx,to_path
  call	file_status_name
  pop	eax
  pop	esi
  jns	path_exists
  mov	ecx,to_path_err
  call	crt_str
  stc
  jmp	to_exit1	

path_exists:
  mov	[esi-1],byte '/' ;restore '/' 
;append file mask to end of -to- path
  shl	al,2
  or	al,[from_wild_flag] ;make decode value
; 00 = from 0 none  +  to 0 none
; 01 = from 1 front +  to 0 none
; 02 = from 2 back  +  to 0 none
; 03 = from 3 all   +  to 0 none
; 00 = from 0 none  +  to 1 front
; 01 = from 1 front +  to 1 front
; 02 = from 2 back  +  to 1 front
; 03 = from 3 all   +  to 1 front
; 00 = from 0 none  +  to 2 back
; 01 = from 1 front +  to 2 back
; 02 = from 2 back  +  to 2 back
; 03 = from 3 all   +  to 2 back
; 00 = from 0 none  +  to 3 all 
; 01 = from 1 front +  to 3 all 
; 02 = from 2 back  +  to 3 all 
; 03 = from 3 all   +  to 3 all 
  xor	ebx,ebx
  mov	bl,al		;get decode value
  shl	ebx,2		;make dword index
  add	ebx,to_decode
  jmp	[ebx]

;----
  [section .data]
to_decode: dd none_none		;0
           dd front_none	;1
           dd back_none		;2
	   dd all_none		;3
	   dd none_front	;4
	   dd front_front	;5
	   dd back_front	;6
	   dd all_front		;7
	   dd none_back		;8
	   dd front_back	;9
	   dd back_back		;10
	   dd all_back		;11
	   dd none_all		;12
	   dd front_all  	;13
	   dd back_all 		;14
	   dd all_all		;15
  [section .text]
;----
;
; code to adjust to_path.  esi points to
; zero at end of to_path.
;
none_none:	;0   dog > cat
  mov	esi,to_path
  mov	edi,current_to_path
  call	str_move
  jmp to_exit


front_none:	;1
  jmp	short all_none

back_none:	;2
  jmp	short all_none

all_none:	;3
  mov	[append_flag],byte 1	;initiate append
  jmp	short none_none

none_front:	;4
  mov	eax,from_file_mask
  mov	esi,asterisk_char	;asterisk
  mov	edi,current_to_path
  call	str_replace
  jmp	to_exit

front_front:	;5
  jmp	none_none
  
back_front:	;6
  jmp	none_none

all_front:	;7
  jmp	none_none

none_back:	;8
 cmp	[esi],byte "*"
 je	nb_got		;jmp if "*" found
 inc	esi
 jmp	short none_back ;loop till "*" found
nb_got:		;esi points at "*" in to_path
 mov	edi,esi
 mov	esi,from_file_mask
 call	str_move
 mov	al,0
 stosb
 jmp	to_exit

front_back:	;9
  jmp	none_none

back_back:	;10
  jmp	none_none

all_back:	;11
  jmp	none_none

;if we copy file to itself, the result is a null file.
;if we change directories this operation is ok.
;check if directory switch
none_all:	;12
  call	new_dir_check
  jne	to_exit		;jmp if dir change
  mov	[esi],word "-"
  mov	[esi+1],byte 0
  jmp	to_exit
  
front_all:	;13
  jmp	to_exit

back_all:	;14
  jmp	to_exit

all_all:	;15
  call	new_dir_check
  jne	to_exit		;jmp if dir change
  jmp	none_all 

to_exit:
  clc
to_exit1:
  ret
;--------
  [section .data]
to_path_err:	db 0ah,'Error - destination dir does not exist',0ah,0
  [section .text]
;-------------------------------------------------
;input: from_path = just path, no file at end
;       to_path = path+file
;       esi = ptr to file at end of to_path 
;output: set flag for je/jne
new_dir_check:
  push	esi
  mov	[esi-1],byte 0	;zap "/" at end of to_path
  mov	esi,to_path
  mov	edi,from_path
  call	str_compare	;set je/jne flag
  pop	esi
  mov	[esi-1],byte '/' ;restore '/' at end of to_path
  ret
;-------------------------------------------------
;input:  complete path at [from_path]
;operation: -check if wild card, if true set mask
;           -check if dir, if true set mask to *
;           -check if single file, if true set mask to file
;           -if none of above return error
build_from_mask:
  mov	esi,from_path
  cmp	byte [esi],'/'		;full path
  je	bfm_10			;jmp if full path
;insert local path
  mov	ebx,buffer
  mov	ecx,500			;buffer size
  call	get_current_path	;fills in path
;move to end of path
  mov	esi,buffer
from_end:
  lodsb
  or	al,al
  jnz	from_end
  dec	esi
  mov	edi,esi
  mov	esi,from_path
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
  mov	edi,from_path
  call	str_move	;move full path to from_path
  mov	esi,from_path
;startng_path now has full path
bfm_10:
  call	wild_check	;esi points to
  mov	[from_wild_flag],al ;0=none 1=front 2=back 3=all
bfm_50: 
  mov	edi,from_file_mask
  call	str_move
  mov	[from_file_mask_end_ptr],edi
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
content_flag	db 0	;1=copy if contents dif
time_flag	db 0	;1=copy if date newer
size_flag	db 0	;1=copy if size chane
force_flag	db 1	;default = always copy
;recurse_flag	db 1	;recurse dirs
delete_flag	db 0	;delete if not present at from_path
append_flag	db 0	;0=no append 1=append request 2=append active
overwrite_flag	db 0	;0=not overwriting 1=current file will overwrite
overwrite_tail_top	db 0	;must be infront of overwrite_ignore_tail
overwrite_ignore_tail	times 20 db 0 ;if non-zero, ignore overwriting tail match
attribute_flag	db 0	;0=preserve attributes 1=default attributes
saved_attributes dd 0	;attributes of existing file, + extra to zero register

err1: db 0ah,'Usage: copy <switch> <from> <to>',0ah
      db     '   where: <switch> = -c copy if contents dif',0ah
      db     '                     -d copy if date dif',0ah
      db     '                     -s copy if size dif',0ah
      db     '                     -h help display',0ah,0
err2_msg:
      db 0ah,'Error -input file not found',0h,0
walk_buffer_ptr	dd 0
err3_msg:
      db 0ah,'Error - parameters found after second file name',0ah
      db     'Did you forget to put quotes around files with astricks?',0ah
      db     'wildcard copy -> copy "file1* file2*"',0ah,0
;------------------------------------------------------------------
  [section .bss]
from_path	resb 250
from_file_mask	resb 100
from_file_mask_end_ptr resd 1	;end of mask string
from_wild_flag	resb 1		;0-no 1=front 2=back 3=all

to_path		resb 250
to_wild_flag	resb 1		;0=no 1=front 2=back 3=all
current_from_path:		;used by -d delete option
current_to_path resb 250

plug_string	resb 50

;buffer is used in startup as work buf
buffer:
from_compare_buf resb	4096
to_compare_buf	 resb	4096


