
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
; NAME
; INPUTS
; OUTPUT
; NOTES
; * ----------------------------------------------

 extern crt_clear,exit_screen_color
 extern crt_open,crt_close
 extern crt_data
 extern env_stack
 extern key_mouse1
 extern mouse_enable
 extern crt_table
 extern kbuf
 extern key_decode1
 extern cursor_to_table
 extern enviro_ptrs
 extern env_home
 extern crt_columns
 extern crt_rows
 extern edit_file_in_box
 extern str_move

	[section .text]
	global	main, _start

_start:
main:
  call	crt_open
  call	env_stack
  call	mouse_enable		;turn the mouse on
lp2:
  mov	esi,select_menu
  call	crt_table		;display menu
  call	key_mouse1		;get user input

  cmp	byte [kbuf],-1		;check if mouse click
  je	h_mouse			;jmp if mouse click
  mov	esi,key_decode_table1
  call	key_decode1
  call	eax			;execute process
  jmp	lp1_end
;
; mouse click occured
;
h_mouse:
  mov	esi,select_menu
  mov	cl,[kbuf + 2]		;get cursor column
  mov	ch,[kbuf + 3]		;get cursor row
  call	cursor_to_table		;return table ptr in esi
  xor	eax,eax			;clear eax
h_ml:
  dec	esi
  mov	al,[esi]
  or	al,al
  jns	h_ml
  not	al
  shl	eax,2
  add	eax,m_table		;process list
  call	[eax]
lp1_end:
  cmp	byte [exit_flag],1
  jne	lp2			;loop back
help_exit:
  call	crt_close		;close the display and keyboard
  mov	eax,1			;exit function
  xor	ebx,ebx			;exit code
  int	80h
  ret
;---------------------------------------------------
exit_key:		;esc
  mov	byte [exit_flag],1
  ret
;---------------------------------------------------

alpha_key:		;ignore
  ret
;---------------------------------------------------
unknown_key_:		;ignore
  ret
;---------------------------------------------------
up_key:
  mov	esi,table_hot_points
  mov	edi,[current_hot_ptr]
  cmp	edi,esi
  je	up_exit
  mov	eax,[edi]		;get ptr to message
  mov	byte [eax],3		;deselect this entry
  sub	edi,4			;move up
  mov	[current_hot_ptr],edi	;store new hot pointer
  mov	eax,[edi]
  mov	byte [eax],4		;select this entry
up_exit:
  ret
;---------------------------------------------------
down_key:
  mov	edi,[current_hot_ptr]
  mov	esi,edi
  add	edi,4
  cmp	dword [edi],0		;check if at end of table
  je	down_exit
  mov	eax,[esi]
  mov	byte [eax],3		;deselect old entry
  mov	eax,[edi]
  mov	byte [eax],4		;select new entry
  mov	[current_hot_ptr],edi
down_exit:
  ret
;---------------------------------------------------
enter_key_:
  mov	eax,[current_hot_ptr]	;get table ptr
  sub	eax,table_hot_points
  add	eax,action_ptrs
  jmp	[eax]
  ret
action_ptrs:
  dd	exit_key
  dd	f1_key
  dd	f2_key
  dd	f3_key
  dd	f4_key
  dd	f5_key
;---------------------------------------------------
f1_key:
  mov	esi,config_tbl
  jmp	edit_table

;%ifdef asmfile
;config_tbl: db '/usr/share/asmmgr/configf.tbl',0
;%else
config_tbl: db '/usr/share/asmmgr/config.tbl',0
;%endif

;---------------------------------------------------
f2_key:
  mov	esi,top_buttons_tbl
  jmp	edit_table

;%ifdef asmfile
;top_buttons_tbl: db '/usr/share/asmmgr/top_buttonsf.tbl',0
;%else
top_buttons_tbl: db '/usr/share/asmmgr/top_buttons.tbl',0
;%endif

;---------------------------------------------------
f3_key:
;  mov	esi,project_tbl
;  jmp	edit_table
;project_tbl: db '/.asmide/mgr/project.tbl',0
;---------------------------------------------------
f4_key:
  mov	esi,open_button_tbl
  jmp	edit_table

open_button_tbl: db '/usr/bin/opener',0

;---------------------------------------------------
f5_key:
  mov	esi,view_button_tbl
  jmp	edit_table

view_button_tbl: db '/usr/bin/viewer',0

;------------------------------------------------------
; input: esi = ptr to table path  /.asmide/mgr/xxxxx
edit_table:
;  push	esi
  mov	edi,table_path
;  mov	ebx,[enviro_ptrs]
;  call	env_home
;  pop	esi  
  call	str_move
;fill in parameter block
  mov	al,[crt_columns]
  sub	al,2
  mov	[cols],al
  mov	al,[crt_rows]
  sub	al,2
  mov	[rows],al
  mov	byte [row],2
  mov	byte [col],2
;setup parameters for edit call
  mov	ebx,table_path
  mov	ecx,20000		;buffer size
  mov	esi,edit_block
  call	edit_file_in_box
  ret

;-----------------
  [section .data]
edit_block:
     dd	30003734h	;color
     dd	0		;used by editor
     dd	0		;used by editor
     dd	0		;initial scroll position
cols db 0		;total columns
rows db 0		;total rows
col  db 0		;upper left corner column for box
row  db 0		;upper left corner row
box  dd 30003636h	;if color here it forces box

  [section .text]  
;------------------------------------------------------
m_table:
  dd	f1_key	;-1 call name index
  dd	f2_key	;-2 access
  dd	f3_key	;-3 ascii
  dd	f4_key	;-4 asmmgr
  dd	f5_key	;-5 call number index
  dd	exit_key	;-6 file
;-------------------------------------------------------------
key_decode_table1:
  dd	alpha_key

  db   1bh,0			;esc
  dd   exit_key

    db 1bh,4fh,50h,0		;f1
  dd	f1_key
    db 1bh,4fh,51h,0		;f2
  dd	f2_key
    db 1bh,4fh,52h,0		;f3
  dd	f3_key
    db 1bh,4fh,53h,0		;f4
  dd	f4_key
    db 1bh,5bh,5bh,41h,0	;f1
  dd	f1_key
    db 1bh,5bh,5bh,42h,0	;f2
  dd	f2_key
    db 1bh,5bh,5bh,43h,0	;f3
  dd	f3_key
    db 1bh,5bh,5bh,44h,0	;f4
  dd	f4_key
    db 1bh,5bh,5bh,45h,0	;f5
  dd	f5_key
    db 1bh,5bh,31h,31h,7eh,0	;2 f1
  dd	f1_key
    db 1bh,5bh,31h,32h,7eh,0	;3 f2
  dd	f2_key
    db 1bh,5bh,31h,33h,7eh,0	;4 f3
  dd	f3_key
    db 1bh,5bh,31h,34h,7eh,0	;5 f4
  dd	f4_key
    db 1bh,5bh,31h,35h,7eh,0	;f5
  dd	f5_key
    db 1bh,5bh,41h,0		;pad_up
  dd	up_key
    db 1bh,4fh,41h,0		;pad_up
  dd	up_key
    db 1bh,4fh,78h,0		;pad_up
  dd	up_key
 
   db 1bh,5bh,42h,0		;pad_down
  dd	down_key
   db 1bh,4fh,42h,0		;pad_down
  dd	down_key
   db 1bh,4fh,72h,0		;pad_down
  dd	down_key
   
    db 0ah,0			;enter
  dd	enter_key_
    db 0dh,0			;enter
  dd   enter_key_
    db 1bh,4fh,4dh,0
  dd   enter_key_

  db   0
  dd   unknown_key_
;-------------------------------------------------------------------------------

struc window_def_
.page_color	resd	1	;window color
.display_ptr	resd	1	;top of display page
.end_ptr		resd	1	;end of file
.scroll_count	resd	1	;right/left window scroll count
.win_columns	resb	1	;window columns (1 based)
.win_rows	resb	1	;window rows (1 based)
.start_row	resb	1	;starting window row (1 based)
.start_col	resb	1	;starting window column (1 based)
.outline_color	resd	1
endstruc

;-------------------------------------------------------------------------------
  [section .data]    
;---------------
  db  -1	;trap to catch errant mice
select_menu:

%ifdef asmfile
mline01:   db  1,'AsmFile configuration is controlled by table settings',9
%else
mline01:   db  1,'AsmMgr configuration is controlled by table settings',9
%endif

mline02:   db  1,'Select table to edit or '
esc_       db  -6,4,'ESC',1,' to exit',9	;blank line
	   db  1,9
           db  1,9
mline03:   db  -1,3,'general settings   ',1,'(f1) ',9
mline04:   db  1,9
mline05:   db  -2,3,'define top buttons ',1,'(f2) ',9
mline06:   db  1,9
;mline07:   db  -3,3,'(unused selection) ',1,'(f3) ',9
;mline08:   db  1,9
;mline09:   db  -4,3,'open button actions',1,'(f4) ',9
;mline10:   db  1,9
;mline11:   db  -5,3,'view button actions',1,'(f5) ',9
;mline12:   db  1,9
  db  5,0	;end of table
table_end:

current_hot_ptr	dd	table_hot_points	;points to selected entry
table_hot_points:
  dd	esc_ +1
  dd	mline03 + 1
  dd	mline05 + 1
;  dd	mline07 + 1
;  dd	mline09 + 1
;  dd	mline11 + 1
  dd	0

 [section .bss]
exit_flag:	resb	1
table_path:	resb	100
