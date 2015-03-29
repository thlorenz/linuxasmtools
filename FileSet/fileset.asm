
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
;****f* asmedit/a_status *
; NAME
;>1 plugin
;  fileset - status display and set for files
; INPUTS
;    usage:  fileset <file>
;            file can have full path or just file
;            name.  File can also be directory
;    fileset presents an interactive form showing
;    file status and highlighted areas for change.
;    The mouse or keyboard can be used to select
;    items for change.       
; OUTPUT
;    Optionally the file permissions, owner, and
;    group can be modiried.     
; NOTES
;   source file: fileset.asm
;<
; * ----------------------------------------------
;*******

 extern crt_clear,exit_screen_color
 extern mouse_enable
 extern env_stack
 extern str_move
 extern file_simple_read
 extern dword_to_ascii
 extern str_search
 extern raw2ascii
 extern ascii_to_dword
 extern crt_str
 extern draw_box
 extern get_string
 extern crt_window
 extern term_type
 extern reset_clear_terminal

	[section .text]
	global	main, _start

_start:
main:
  call	env_stack
  call	browse_setup
  call	clear_console
  call	mouse_enable
  call	get_groups
  or	eax,eax
  js	abort
  call	parse
  call	get_status
main_loop:
  call	stuff_owner_group
  call	stuff_file_type
  call	stuff_file_length
  call	stuff_file_dates
  call	set_flags

  mov	esi,box
  call	draw_box
  mov	ebp,form_block
  call	form2_show



ignore_lp:
  mov	ebp,form_block
  call	form2_input	;out eax=neg error, 0=unknown else eax=process
  or	eax,eax
  jz	main_loop	;rediplay request
  js	key_lookup	;jmp if unknown key
  jnz	do_call
key_lookup:
  mov	esi,key_table
  call	key_decode3	;out: eax=process or zero
  or	eax,eax
  jz	main_loop	;unknown key
do_call:
  call	eax		;do request
  cmp	[done_flag],byte 0
  je	main_loop
abort:
;  mov	eax,30003730h
;  call	crt_clear
;  mov	ax,0101h
;  call	move_cursor
  call	reset_clear_terminal
  mov	eax,1
  int	80h
;------------------------
  [section .data]
key_table:
  db 1bh,0
  dd abort

  db 3,0			;ctrl-c
  dd abort

  db    0			;end of table

  [section .text]
;---------------------------------------------------------------------
browse:
  mov	ebx,buf1
  mov	ecx,129			;size of pathx
  mov	eax,183			;get cwd
  int	80h
  mov	esi,wrk_buf_ptr		;get struc ptr
  call	browse_dir
;if eax=0 the ebx is full path ptr
  or	eax,eax
  jnz	b_exit			;exit if no entry
  mov	esi,ebx
  mov	edi,buf1
  call	str_move
  call	text_buf1		;make buf1 all text
b_exit:
  ret

;  *  S_IRUSR  00400   owner has read permission
;  *  S_IWUSR  00200   owner has write permission
;  *  S_IXUSR  00100   owner has execute permission
;  *  S_IRWXG  00070   mask for group permissions
;  *  S_IRGRP  00040   group has read permission
;  *  S_IWGRP  00020   group has write permission
;  *  S_IXGRP  00010   group has execute permission
;  *  S_IRWXO  00007   mask for permissions for others (not in group)
;  *  S_IROTH  00004   others have read permission
;  *  S_IWOTH  00002   others have write permisson
;  *  S_IXOTH  00001   others have execute permission

read_owner:
  xor	[st_mode],word 400q  
  ret
write_owner:
  xor	[st_mode],word 200q  
  ret
execute_owner:
  xor	[st_mode],word 100q  
  ret
read_group:
  xor	[st_mode],word 040q  
  ret
write_group:
  xor	[st_mode],word 020q  
  ret
execute_group:
  xor	[st_mode],word 010q  
  ret
read_other:
  xor	[st_mode],word 004q  
  ret
write_other:
  xor	[st_mode],word 002q  
  ret
execute_other:
  xor	[st_mode],word 001q  
  ret

;  *  S_ISUID  0004000 set UID bit
;  *  S_ISGID  0002000 set GID bit (see below)
;  *  S_ISVTX  0001000 sticky bit (see below)
uid:
  xor	[st_mode],word 4000q  
  ret
gid:
  xor	[st_mode],word 2000q  
  ret
sticky:
  xor	[st_mode],word 1000q  
  ret

hard_link:
  mov	eax,[highlight]
  mov	bl,3	;column
  mov	bh,18	;row
  mov	ecx,hl_msg1
  call	crt_color_at
;clear input buffer
  mov	edi,file_path_only
  xor	eax,eax
  mov	ecx,300
  rep	stosb
;read file name
  mov	ebp,hard_string
  call	get_string

  cmp	[file_path_only],byte '/'	;full path provided?
  je	create_hl
;append current dir
  call	dir_current	;eax=size ebx=path
  mov	edi,work_buf
  mov	esi,ebx
  call	str_move
;  mov	ecx,eax
;  rep	movsb
  mov	al,'/'
  stosb
  mov	esi,file_path_only
  jmp	short hl_move
;put zero at end and move to work_buf
create_hl:
  mov	esi,file_path_only
hl_move:
  lodsb
  stosb
  or	al,al
  jz	do_hard		;jmp if zero found
  cmp	al,' '
  jne	hl_move		;loop till name moved
  mov	[esi-1],byte 0
  jmp	short do_hard
;work_buf has name for haad link
do_hard:
;insert zero in current file at (buf1)
  cmp	byte [buf1],' '
  je	hard_exit	;eixt if no file
  call	asciiz_buf1	;convert buf1 to asciiz
;make hard link
  mov	eax,9	;make link
  mov	ebx,buf1
  mov	ecx,work_buf
  int	byte 80h
  call	text_buf1
hard_exit:
  ret
;-----
  [section .data]
hl_msg1: db 'Enter alternate name for current file',0
hard_string:
  dd	file_path_only
  dd	300	;buffer size
  dd	select_color
  db	19	;row
  db	3	;column
  db	0	;flags
  db	3	;initial cursor column
  dd	55	;window size

  [section .text]
;--------------------
symlink_:
  mov	eax,[highlight]
  mov	bl,3	;column
  mov	bh,18	;row
  mov	ecx,hl_msg2
  call	crt_color_at
;clear input buffer
  mov	edi,file_path_only
  xor	eax,eax
  mov	ecx,300
  rep	stosb
;read file name
  mov	ebp,hard_string
  call	get_string

  cmp	[file_path_only],byte '/'	;full path provided?
  je	create_sl
;append current dir
  call	dir_current	;eax=size ebx=path
  mov	edi,work_buf
  mov	esi,ebx
  call	str_move
;  mov	ecx,eax
;  rep	movsb
  mov	al,'/'
  stosb
  mov	esi,file_path_only
  jmp	short sl_move
;put zero at end and move to work_buf
create_sl:
  mov	esi,file_path_only
sl_move:
  lodsb
  stosb
  or	al,al
  jz	do_syml		;jmp if zero found
  cmp	al,' '
  jne	sl_move		;loop till name moved
  mov	[esi-1],byte 0
  jmp	short do_syml
;work_buf has name for haad link
do_syml:
;insert zero in current file at (buf1)
  cmp	byte [buf1],0
  je	sym_exit	;eixt if no file
  call	asciiz_buf1
;make hard link
  mov	eax,83	;make symlink
  mov	ebx,buf1
  mov	ecx,work_buf
  int	byte 80h
  call	text_buf1	;restore text buf1
sym_exit:
  ret
;-----------
  [section .data]
hl_msg2: db 'enter name for symlink to current file',0
  [section .text]
;------------

apply:
  call	asciiz_buf1
; set owner and group
; buf1 has new uid name, buf2 has new group name
; -owners- is passwd buffer and -groups- is group file
; move first (uid) name to temp area
  mov	esi,buf2
  mov	edi,new_name
ac_mv1:
  lodsb
  stosb
  cmp	al,' '
  jne	ac_mv1
  dec	edi
  mov	byte [edi],0	;put zero at end
; lookup this uid name
  mov	edi,owners
  mov	esi,new_name
  call	lookup_name	;returns uid or -1
  or	eax,eax
  js	ac_skip1	;jump if error
  mov	[bin_uid],eax
; buf1 has new uid name, buf2 has new group name
; -owners- is passwd buffer and -groups- is group file
; move (gid) name to temp area
  mov	esi,buf3
  mov	edi,new_name
ac_mv2:
  lodsb
  stosb
  cmp	al,' '
  jne	ac_mv2
  dec	edi
  mov	byte [edi],0	;put zero at end
; lookup this uid name
  mov	edi,groups
  mov	esi,new_name
  call	lookup_name	;returns uid or -1
  or	eax,eax
  js	ac_skip1	;jump if error
  mov	[bin_gid],eax
; call kernel to set new uid+uid name
  mov	eax,182
  mov	ebx,buf1
  mov	ecx,[bin_uid]
  mov	edx,[bin_gid]
  int	80h
ac_skip1:
;write mode must be last, it appears setting
;owner/group resets the st_mode state?
  call	write_mode
  call	text_buf1
  call	get_status
  ret
;-----------------------
write_mode:
  xor	ecx,ecx
  mov	cx,[st_mode]
  mov	ebx,buf1
  mov	eax,15
  int	80h				;set flags
  ret
;-----------------------
  [section .data]
bin_uid:	dd	0
bin_gid:	dd	0
new_name:
  times 20 db 0
  [section .text]  
;---------------------------------------------------------------------

help:
  mov	esi,help_block
  call	crt_window
  call	read_stdin
  ret
;----------
  [section .data]
help_block:
  dd	30003730h	;color for page
  dd	help_msg	;message ptr
  dd	help_msg_end	;end of msg
  dd	0		;scroll
  db	60		;window columns
  db	20		;window rows
  db	1		;starting row
  db	1		;starting column
  [section .text]

;--------------------------------------------------------------------
quit:
  mov	[done_flag],byte 1
  ret
;----
  [section .data]
done_flag: db 0
  [section .text]


;---------------------------------------------------------------------
set_flags:
  mov	dx,[st_mode]
  mov	esi,flag_table
sf_lp:
  lodsd			;get flags
  or	eax,eax		;get if end of table
  jz	sf_exit		;exit if done
  and	eax,edx
; eax = 0 if not set eax = bit if set
  lodsd			;get color location
  jz	sf_notset
;  cmp	esi,fspecial
;  ja	sf_lp
  mov	byte [eax+2],'X'
  jmp	short sf_lp
sf_notset:
;  cmp	esi,fspecial
;  ja	sf_lp
  mov	byte [eax+2],' '
  jmp	short sf_lp
sf_exit:
  ret
;
; each pair in table = chmod flag bit , table loc of color
; normal color = button_color = 4
; bit set color = selected_color = 3
;
flag_table:
  dd	0400q,line12_a	;owner read
  dd	0040q,line12_b	;group read
  dd	0004q,line12_c	;other read
  dd	0200q,line13_d	;owner write
  dd	0020q,line13_e	;group write
  dd	0002q,line13_f	;other write
  dd	0100q,line14_g	;owner execute
  dd	0010q,line14_h	;group execute
  dd	0001q,line14_i	;other execute
fspecial:
  dd	4000q,line15_j	;UID
  dd	2000q,line15_k	;GID
  dd	1000q,line15_l	;sticky
  dd	0		;end of table
;---------------------------------------------------------------------
stuff_file_dates:
  mov	eax,[st_atime]	;get file time
  mov	edi,line07_t2	;destination for ascii
  mov	ebx,date_format	;format
  call	raw2ascii
  mov	dword [edi],'    ' ;blank end

  mov	eax,[st_mtime]	;get file time
  mov	edi,line08_t3	;destination for ascii
  mov	ebx,date_format	;format
  call	raw2ascii
  mov	dword [edi],'    ' ;blank end

  mov	eax,[st_ctime]	;get file time
  mov	edi,line06_t1	;destination for ascii
  mov	ebx,date_format	;format
  call	raw2ascii
  mov	dword [edi],'    ' ;blank end
  ret

date_format: db '6- 2, 0  3:4:58 9',0
;---------------------------------------------------------------------
stuff_file_length:
  mov	eax,[st_size]
  mov	edi,length_insert
  call	dword_to_ascii
  ret
;---------------------------------------------------------------------
; move type to "type_insert"
stuff_file_type:
  xor	eax,eax
  mov	ax,[st_mode]	;get mode flags
  and	ax,170000q	;isolate data
  shr	eax,10
  add	eax,type_index
  mov	esi,[eax]	;get ptr to type text
  mov	edi,type_insert
  call	str_move
  mov	byte [edi],' '	;put space at end
  ret

;----
  [section .data]
type_index:
  dd	t00
  dd	t01
  dd	t02
  dd	t03
  dd	t04
  dd	t05
  dd	t06
  dd	t07
  dd	t10
  dd	t11
  dd	t12
  dd	t13
  dd	t14
  dd	t15
  dd	t16
  dd	t17

t00 db 'type 00',0
t01 db 'fifo',0
t02 db 'char dev',0
t03 db 'type 03',0
t04 db 'dir',0
t05 db 'type 05',0
t06 db 'block dev',0
t07 db 'type 07',0
t10 db 'file',0
t11 db 'type 11',0
t12 db 'symlink',0
t13 db 'type 13',0
t14 db 'socket',0
t15 db 'type 15',0
t16 db 'type 16',0
t17 db 'type 17',0

  [section .text]
;---------------------------------------------------------------------
; input:  st_uid = bin word with owner id
;         st_gid = bin word with group id
;         buffer -> owners
;         buffer -> groups
; output: ascii_uid (asciiz) number
;         ascii_gid (asciiz) number
;         uid_name
;         gid_name
;         display stuff -> buf1 (terminated with byte >9
;                          buf2 (terminated with byte >9
stuff_owner_group:
  xor	eax,eax
  mov	ax,[st_uid]
  mov	edi,ascii_uid
  call	dword_to_ascii
  mov	byte [edi],0	;put  zero at end
; convert gid to ascii
  xor	eax,eax
  mov	ax,[st_gid]
  mov	edi,ascii_gid
  call	dword_to_ascii
  mov	byte [edi],0	;put  zero at end
; look up uid name in buffer
  mov	esi,ascii_uid	;ascii uid
  mov	edi,owners	;buffer from file /etc/passwd
  mov	edx,uid_name	;storage location for name (asciiz)
  call	lookup_id
; look up gid name in buffer
  mov	esi,ascii_gid	;ascii gid
  mov	edi,groups	;buffer from file /etc/groups
  mov	edx,gid_name	;storage location for name
  call	lookup_id 
; stuff uid in display form
  mov	esi,uid_name
  mov	edi,buf2
  call	fill_form
;
  mov	esi,gid_name
  mov	edi,buf3
  call	fill_form
  ret
  
  [section .bss]
ascii_uid: resb 8		;uid number
ascii_gid: resb 8		;gid number
uid_name:  resb 20		;uid name
gid_name:  resb 20		;gid name
  [section .text]
;---------------------------
; input edi = buffer to search
;       esi = ptr to match string (uid/gid name)
; output: eax = id or -1 if not found
lookup_name:
  mov	[buffer_start],edi
  mov	[match_str],esi
kp_looking:
  mov	esi,[match_str]
  call	str_search
  jc	lx_exit2	;exit if no match
; esi=end match str edi=end matched str edx=start matching ebx=start matched
kp_bk:
  inc	edi		;move fwd to ":"
  cmp	word [edi],':x'
  jne	kp_looking	;jmp if still searching
kp_found:
  add	edi,3		;move to UID/GID numeric ascii
  mov	dword [storage_loc],ascii_num
  mov	esi,edx		;get ptr to matched string
  call	move_match
  mov	esi,ascii_num
  call	ascii_to_dword
  mov	eax,ecx
  jmp	short lx_exit1
lx_exit2:
  mov	eax,-1		;signal no match
lx_exit1:
  ret

  [section .data]
match_str	dd 0
ascii_num: db 0,0,0,0,0
  [section .text]
;---------------------------
;  inputs: esi = ascii_uid	;ascii uid
;          edi = owners	;buffer from file /etc/passwd
;          edx = uid_name	;storage location for name (asciiz)
lookup_id:
  mov	[buffer_start],edi
  mov	[storage_loc],edx		;save storage location
keep_looking:
  push	esi		;save search string
  call	str_search
  pop	esi		;restore start of search string
  jc	ln_exit		;exit if no match
  inc	edi		;move fwd in search buf, (for keep_looking)
  cmp	word [ebx -2],'x:'
  jne	keep_looking
  cmp	byte [edi],':'
  jne	keep_looking
; we have found match, scan back to start of line
ln_lp2:
  cmp	edi,[buffer_start]
  je	move_match
  cmp	byte [edi -1],0ah
  je	move_match
  dec	edi
  jmp	ln_lp2
;----------   entry from lookup_id lookup_name
move_match:
  mov	esi,edi
  mov	edi,[storage_loc]
ln_lp3:
  lodsb
  stosb
  cmp	al,':'
  jne	ln_lp3
  mov	byte [edi -1],0
ln_exit:
  ret
  
  [section .bss]
buffer_start: resd 1
storage_loc: resd  1
  [section .text]

;---------------------------
; move asciiz string into form field
;  input esi = source string
;        edi = form storage location
fill_form:
  cmp	byte [edi],9
  jbe	ff_exit		;exit if at end
  mov	al,' '
  cmp	byte [esi],0
  je	ff_20		;jmp if at end of input data
  lodsb
ff_20:
  stosb
  jmp	fill_form
ff_exit:
  ret

    
;---------------------------------------------------------------------
get_status:
  xor	eax,eax
;clear the stat buffer
  mov	edi,status_buf
  mov	ecx,status_buf_end - status_buf
  rep	stosb	;clear the buffer
  call	asciiz_buf1
;read file status
  mov	eax,107
  mov	ebx,buf1
  mov	ecx,status_buf	;use lib_buf for fstat buffer
  int	80h
  or	eax,eax
  js	fe_fail		;jmp if file does not exist
; check if symlink
  mov	ax,[st_mode]
  and	eax,120000q
  cmp	eax,120000q
  jne	fe_exit1
; get link path
  mov	eax,85
  mov	ebx,buf1
  mov	ecx,symlink_path
  mov	edx,300
  int	80h
  or	eax,eax
  jns	fe_exit1	;jmp if success
fe_fail:
  or	eax,byte -1
  jmp	short fe_exit2
fe_exit1:
  xor	eax,eax		;signal no errors
fe_exit2:
  call	text_buf1
  ret

;------------------
  [section .bss]

symlink_path	resb	300

status_buf:
st_dev: resd 1
st_ino: resd 1
st_mode: resw 1
st_nlink: resw 1
st_uid: resw 1
st_gid: resw 1
st_rdev: resd 1
st_size: resd 1
st_blksize: resd 1
st_blocks: resd 1
st_atime: resd 1
__unused1: resd 1
st_mtime: resd 1
__unused2: resd 1
st_ctime: resd 1
__unused3: resd 1
__unused4: resd 1
__unused5: resd 1
status_buf_end:
;  ---  stat_struc_size


;  *  The following flags are defined for the st_mode field
;  *  -
;  *  S_IFMT   0170000 bitmask for the file type bitfields
;  *  S_IFSOCK 0140000 socket
;  *  S_IFLNK  0120000 symbolic link
;  *  S_IFREG  0100000 regular file
;  *  S_IFBLK  0060000 block device
;  *  S_IFDIR  0040000 directory
;  *  S_IFCHR  0020000 character device
;  *  S_IFIFO  0010000 fifo
;  *  S_ISUID  0004000 set UID bit
;  *  S_ISGID  0002000 set GID bit (see below)
;  *  S_ISVTX  0001000 sticky bit (see below)
;  *  S_IRWXU  00700   mask for file owner permissions
;  *  S_IRUSR  00400   owner has read permission
;  *  S_IWUSR  00200   owner has write permission
;  *  S_IXUSR  00100   owner has execute permission
;  *  S_IRWXG  00070   mask for group permissions
;  *  S_IRGRP  00040   group has read permission
;  *  S_IWGRP  00020   group has write permission
;  *  S_IXGRP  00010   group has execute permission
;  *  S_IRWXO  00007   mask for permissions for others (not in group)
;  *  S_IROTH  00004   others have read permission
;  *  S_IWOTH  00002   others have write permisson
;  *  S_IXOTH  00001   others have execute permission
  [section .text]

;---------------------------------------------------------------------
; inputs: none
; output: if eax negative = error else the following
;         owners buffer data terminated by zero
;                format: jeff:X:501:501:jumk:/home/jeff:/bin/bash
;                        owner:passwd:UID:GID:junk:path:shell
;         group buffer data terminated by zero
;                format: jeff:x:501:--
;                        group:passwd:GID:
;
get_groups:
  mov	ebx,owner_path
  mov	ecx,owners
  mov	edx,2000
  call	file_simple_read
  or	eax,eax
  js	gg_exit
  add	ecx,eax
  mov	byte [ecx],0	;terminate file

  mov	ebx,group_path
  mov	ecx,groups
  mov	edx,2000
  call	file_simple_read
  or	eax,eax
  js	gg_exit
  add	ecx,eax
  mov	byte [ecx],0	;terminate file
gg_exit:
  ret

owner_path: db '/etc/passwd',0
group_path: db '/etc/group',0

  [section .data]
owners times 2000 db 0
groups times 2000 db 0
  [section .text]

;---------------------------------------------------------------------
; input: esp
; output: buf1
;         file_path_only
parse:
;get local directory from kernel
  mov	eax,183
  mov	ebx,file_path_only
  mov	ecx,300		;max length
  int	80h

  mov	esi,esp
  lodsd			;get retrun ptr
  lodsd			;get parameter count
  cmp	eax,2
  jne	parse_exit	;jmp if wrong count
  lodsd			;get ptr to our name
  lodsd			;get filename ptr
  cmp	byte [eax],'/'	;check if full path
  je	parse_full_in	;jmp if full path provided
;move file name to local buffer
;builld full path from path + name
  push	eax
  mov	edi,buf1
  mov	esi,file_path_only
  call	str_move
  mov	al,'/'
  stosb
  pop	esi
  call	str_move
  jmp	short parse_exit
;full path entered
parse_full_in:
  mov	esi,eax
  mov	edi,buf1
  call	str_move		;save full path
parse_exit:
  ret
;---------------------------------------------------------------
;On debian if we boot and start console, the font
;setup does not support graphics characters. It
;works after a reset.  On x terminals graphics
;characters work ok, and doing a reset may ring
;the bell, so we avoid resets on xterm's.
clear_console:
  call	read_window_size
  cmp	[term_type],byte 2	;console?
  jne	cc_exit			;exit if not console
  mov	ecx,clr_str
  call	crt_str
cc_exit:
  ret
;----
  [section .data]
clr_str: db 1bh,'c',0
  [section .text]
;---------------------------------------------------------------
browse_setup:
;setup memory for allocation
  mov	eax,45
  xor	ebx,ebx		;request memory allocation adr
  int	byte 80h
  mov	[wrk_buf_ptr],eax
  mov	esi,wrk_buf_ptr	;get ptr to structure
  cmp	byte [crt_rows],0
  jne	dbl_20			;jmp if row data available
  call	read_window_size
dbl_20:
  mov	al,[crt_columns]
  shr	al,1
  mov	[win_clumns],al

  add	al,2
  shr	al,1
  mov	[win_loc_column],al

  xor	eax,eax
  mov	al,[crt_rows]
  sub	al,2
  mov	[win_rws],al

  mov	[win_loc_row],byte 2
  ret
;------------------------------------------------------------
asciiz_buf1:
  mov	esi,buf1
  mov	ecx,200
insert_zero_loop:
  lodsb
  cmp	al,' '
  je	set_zero	;jmp if space found
  loop	insert_zero_loop
set_zero:
  dec	esi
  mov	[esi],byte 0
  ret
;------------------------------------------------------------
text_buf1:
;replace all zero's with spaces
  mov	esi,buf1
  xor	ecx,ecx
  mov	cl,[string1_def+str_def.wsize]
tb_loop:
  lodsb
  or	al,al
  jnz	tb_tail
  mov	[esi-1],byte ' '
tb_tail:
  loop	tb_loop
  ret

%include "form2_show.inc"
%include "form2_input.inc"
%include "browse_dir.inc"
;----------------------------

 [section .data]

box	dd	30003037h	;box color
	db	1		;starting row
	db	1		;starting column
	db	24		;rows
	db	62		;columns

;--------------------

eol	equ	0ah

;    eax = aaxxffbb aa-attr ff-foreground  bb-background
;    30-blk 31-red 32-grn 33-brn 34-blu 35-purple 36-cyan 37-gry
;    attributes 30-normal 31-bold 34-underscore 37-inverse
win_rows_	equ	23
win_columns_	equ	61

form_block:
 db win_rows_	;ending row
 db win_columns_  ;ending column
 db 2	;starting row
 db 2	;startng column
 dd fileset_form	;form def ptr
 dd index_top ;top def list
 dd index_top+4 ;active/selected list index
select_color:
 dd 30003136h	;color 1 selected_string color/field
 dd 30003336h	;color 2 unselected string/field color
 dd 30003037h	;color 3 normal window color
 dd 30003634h	;color 4 button color
highlight:
 dd 30003437h	;color 5 highlight color (plug in info)

fileset_form:
 db 3,' FileSet - display & set attributes of file:',0ah

 db eol

 db ' '
browse_mod: db 4,'BROWSE',3,' ',4,-1	;string def 1
 db 3,0ah

 db 'File type: ',5
type_insert:
 db '              ',3,0ah

 db 'File length: ',5
length_insert: times 10 db ' '
 db 3,0ah


line06: db 'Last Update: ',5
line06_t1: times 40 db ' '
	db 3,0ah

line07: db 'Last Access: ',5
line07_t2: times 40 db ' '
	db 3,eol

line08: db 'Last Statm : ',5
line08_t3: times 40 db ' '
	db 3,eol

line09: db eol

line10: db '         |  OWNER(o)    |  GROUP(r)    |   OTHER      |',eol

line11:
        db 3
buf1_header_start:
	db '         |',4
buf1_header_end:
	db -2,3
buf2_header_start:
        db '|',4
buf2_header_end:
	db -3,3
	   db '|              |'
	db eol

	db '-------------------------------------------------------',eol

line12: db 'read     |   '
	db '    '
line12_a: db 4,' X ',3,'    |  '
	db '    '
line12_b: db 4,' X ',3,'     |  '
	db '    '
line12_c: db 4,' X ',3,'     |  ',eol

line13: db 'write    |   '
	db '    '
line13_d: db 4,' X ',3,'    |  '
	db '    '
line13_e: db 4,' X ',3,'     |  '
	db '    '
line13_f: db 4,' X ',3,'     |  ',eol

line14: db 'execute  |   '
	db '    '
line14_g: db 4,' X ',3,'    |  '
	db '    '
line14_h: db 4,' X ',3,'     |  '
	db '    '
line14_i: db 4,' X ',3,'     |  ',eol

line15: db 'ID       | (uid) '
line15_j: db 4,' X ',3,'    | (gid)'
line15_k: db 4,' X ',3,'     | stick'
line15_l: db 4,' X ',3,'     |  ',eol

 db eol
 db eol
 db eol

 db '(keyboard - up/down/tab select fields, <enter> executes)',0ah
 db '(mouse - left click any entry field)',0ah

 db ' '
hard_stuff db 4,'hard link',3,' '
symlink_stuff db 4,'symlink',3,' '
apply_stuff db 4,'apply  changes',3,' '
help_stuff db 4,'help',3,' '
quit_stuff db 4,'exit',3,' ',eol

 db 0	;end of form

; string definitions must be in order (-1,-2,-3,etc.)
; the string buffers can be anywhere, but not between
; string definitions.

;struc str_def
;.srow		resb 1	;row
;.scol		resb 1	;col
;.scur		resb 1	;cursor column
;.scroll		resb 1	;scroll counter
;.wsize		resb 1	;columns in string window
;.bsize		resd 1	;size of buffer, (max=127)
;.buf		resd 1	;ptr to buffer
;str_def_size:
;endstruc

index_top:
 dd	browse_def
 dd	string1_def
 dd	string2_def
 dd	string3_def
 dd	read_owner_def
 dd	read_group_def
 dd	read_other_def
 dd	write_owner_def
 dd	write_group_def
 dd	write_other_def
 dd	execute_owner_def
 dd	execute_group_def
 dd	execute_other_def
 dd	uid_def
 dd	gid_def
 dd	sticky_def
 dd	hard_link_def
 dd	symlink_def
 dd	apply_def
 dd	help_def
 dd	quit_def
 dd	0		;end  of index

browse_def:
 db 2 ;2=button 3=toggle
 db 4 ;row
 db 2 ;column
 db 0 ;toggle mod column (type 3 only)
 db 0 ;character for "on" (type 3 only)
 db 6 ;size of item (used for mouse decode)
 dd browse_mod
 dd browse ;process to handle this

string1_def:	;input path
 db -1
 db 4	;row
 db 10	;column
 db 10	;current cursor posn
 db 0	;scroll
 db win_columns_ - 11  ;window size
 dd buf1_end - buf1 ;buf size
 dd buf1
 
string2_def:	;owner
 db -2
 db 12	;row
 db 12	;column
 db 12	;current cursor posn
 db 0	;scroll
 db 14  ;window size
 dd buf2_end - buf2 ;buf size (max=127)
 dd buf2

string3_def:	;group
 db -3
 db 12	;row
 db 27	;column
 db 27	;current cursor posn
 db 0	;scroll
 db 14  ;window size
 dd buf3_end - buf3 ;buf size (max=127)
 dd buf3

read_owner_def:
 db 3 ;2=button 3=toggle
 db 14 ;row
 db 19 ;column
 db 0
 db 'X' ;character for "on" (type 3 only)
 db 3 ;size of item (used for mouse decode)
 dd line12_a
 dd read_owner ;process to handle this

read_group_def:
 db 3 ;2=button 3=toggle
 db 14;row
 db 33;column
 db 0
 db 'X' ;character for "on" (type 3 only)
 db 3 ;size of item (used for mouse decode)
 dd line12_b
 dd read_group ;process to handle this

read_other_def:
 db 3 ;2=button 3=toggle
 db 14;row
 db 47 ;column
 db 0
 db 'X' ;character for "on" (type 3 only)
 db 3 ;size of item (used for mouse decode)
 dd line12_c
 dd read_other ;process to handle this

write_owner_def:
 db 3 ;2=button 3=toggle
 db 15 ;row
 db 19 ;column
 db 0 ;toggle mod column (type 3 only)
 db 'X' ;character for "on" (type 3 only)
 db 3 ;size of item (used for mouse decode)
 dd line13_d
 dd write_owner ;process to handle this

write_group_def:
 db 3 ;2=button 3=toggle
 db 15 ;row
 db 33 ;column
 db 0
 db "X" ;character for "on" (type 3 only)
 db 3 ;size of item (used for mouse decode)
 dd line13_e
 dd write_group ;process to handle this

write_other_def:
 db 3 ;2=button 3=toggle
 db 15;row
 db 47 ;column
 db 0 ;toggle mod column (type 3 only)
 db "X" ;character for "on" (type 3 only)
 db 3 ;size of item (used for mouse decode)
 dd line13_f
 dd write_other ;process to handle this

execute_owner_def:
 db 3 ;2=button 3=toggle
 db 16 ;row
 db 19;column
 db 0
 db "X"  ;character for "on" (type 3 only)
 db 3 ;size of item (used for mouse decode)
 dd line14_g
 dd execute_owner ;process to handle this

execute_group_def:
 db 3 ;2=button 3=toggle
 db 16;row
 db 33;column
 db 0
 db "X" ;character for "on" (type 3 only)
 db 3 ;size of item (used for mouse decode)
 dd line14_h
 dd execute_group ;process to handle this

execute_other_def:
 db 3 ;2=button 3=toggle
 db 16 ;row
 db 47 ;column
 db 0
 db "X" ;character for "on" (type 3 only)
 db 3 ;size of item (used for mouse decode)
 dd line14_i
 dd execute_other ;process to handle this

uid_def:
 db 3 ;2=button 3=toggle
 db 17 ;row
 db 19 ;column
 db 0 ;toggle mod column (type 3 only)
 db "U" ;character for "on" (type 3 only)
 db 3 ;size of item (used for mouse decode)
 dd line15_j
 dd uid ;process to handle this

gid_def:
 db 3 ;2=button 3=toggle
 db 17;row
 db 33;column
 db 0
 db "G" ;character for "on" (type 3 only)
 db 3 ;size of item (used for mouse decode)
 dd line15_k
 dd gid ;process to handle this

sticky_def:
 db 3 ;2=button 3=toggle
 db 17;row
 db 47;column
 db 0
 db "S" ;character for "on" (type 3 only)
 db 6 ;size of item (used for mouse decode)
 dd line15_l
 dd sticky ;process to handle this

hard_link_def:
 db 2 ;2=button 3=toggle
 db 23;row
 db 3 ;column
 db 0 ;toggle mod column (type 3 only)
 db 0 ;character for "on" (type 3 only)
 db 9 ;size of item (used for mouse decode)
 dd hard_stuff
 dd hard_link ;process to handle this

symlink_def:
 db 2 ;2=button 3=toggle
 db 23 ;row
 db 13 ;column
 db 0 ;toggle mod column (type 3 only)
 db 0 ;character for "on" (type 3 only)
 db 7 ;size of item (used for mouse decode)
 dd symlink_stuff
 dd symlink_ ;process to handle this

apply_def:
 db 2 ;2=button 3=toggle
 db 23 ;row
 db 21;column
 db 0 ;toggle mod column (type 3 only)
 db 0 ;character for "on" (type 3 only)
 db 13 ;size of item (used for mouse decode)
 dd apply_stuff
 dd apply ;process to handle this

help_def:
 db 2 ;2=button 3=toggle
 db 23 ;row
 db 36 ;column
 db 0 ;toggle mod column (type 3 only)
 db 0 ;character for "on" (type 3 only)
 db 4 ;size of item (used for mouse decode)
 dd help_stuff
 dd help ;process to handle this

quit_def:
 db 2 ;2=button 3=toggle
 db 23 ;row
 db 41 ;column
 db 0 ;toggle mod column (type 3 only)
 db 0 ;character for "on" (type 3 only)
 db 4 ;size of item (used for mouse decode)
 dd quit_stuff
 dd quit ;process to handle this



buf1:
 times 200 db " "
buf1_end:

buf2:
 db 'samo           '
buf2_end:

buf3:
 db 'jeff           '
buf3_end:
;
; data block for browse_dir
;
wrk_buf_ptr:        dd 0	;pointer to .bss area for allocation
dirclr             dd 31003734h	;color of directories in list
linkclr            dd 30003634h       ;color of symlinks in list
selectclr          dd 30003436h       ;color of select bar
fileclr            dd 30003734h	;normal window color, and list color
win_loc_row     db 1       ;top row number for window
win_loc_column  db 1	;top left column number
win_rws:            db 0	;number of rows in our window
win_clumns:         db 0	;number of columns
box_flg	     db 1	;0=no box 1=box
start_path_ptr    dd buf1	;path to start browsing
execlr           dd 30003234h ;green
devclr           dd 30003334h ;red
miscclr          dd 30003034h ;black
input_struc_size equ $ - wrk_buf_ptr

file_path_only: times 300 db 0
work_buf:	times 300 db 0


help_msg:
incbin "help.inc"
help_msg_end:	db 0

  [section .bss]
allocated:
