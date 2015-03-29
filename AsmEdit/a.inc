;---- configuration data for a.ini file -----------------
;
top_of_a_ini:
version	dd	920	;change this evertime file is modified

config_data db 0ah,' a.ini editor config file - DO NOT EDIT ',0ah
;-------------------------------------------------------
active_window	dd 0	;0=single-a               1=single (window b)
;                        2=horizontal-a (top)     3=horizontal-b (bottom)
;                        4=vertical-a (left)      5=vertical-b (right)
;--------------------------------------------------------
; active template
;
active_template:
file_location	db	0	;0=uninitialized 1=in memory 2=in temp file
file_change	db	20h	;20h=unchanged "*"=changed
file_end_ptr	dd	0	;pointer to last char+1
file_path	times 300 db (0)	;file name
file_tmp_name	db	'/tmp/asmedit.tmp.'
file_tmp_name_stuff db '1',0
tag_a	dd	0
tag_b	dd	0
tag_c	dd	0
tag_d	dd	0
file_attributes dw	0
; buffer/block data.
blockbegin dd	0	;beginning of block
blockend   dd	0	;end of block
showblock  dd	0	;used if display of block needed
show_asm   dd	1	;used if display of asm highlighting active
asm_comment_char db	';'
;
win_type	db	0	;(matches active_window)
editbuf_cursor_ptr dd	0	;pointer to cursor data in fbuf
editbuf_cursor_line_ptr dd 0	;ponter to start of line with cursor
cursor_linenr	dd	1	;line number of cursor
crt_top_ptr	dd	0	;top line ptr
crt_top_linenr	dd	1	;line number for top crt diplayed line
crt_left_column dd	0	;column number for left win edge (scroll)
crt_cursor	dd	0101h	;row/col for display cursor
status_line_row	db	0	;column for status line
win_loc_col	db	1	;column of upper left corner
win_loc_row	db	1	;row of upper left corner
win_columns	db	80	;total column
win_rows	db	24	;total rows
;-------------------------------------------------------------

insert_overtype dd	1	;insert/overtype mode, 1=insert
key_mode dd	0		;0=cmd 1-edit 2=hlp 3=set
mouse_mode dd	0		;0=idle 1=main 2=quit 3=wn 4=jmp 5=misc
;
; margins for paragraphing
;
left_margin	db	1
right_margin	db	65
;				;6=edit 7=find 8=block 9=funct
case_mask	dd	0dfh	;set to 0xdf to ignore case
backup_flag	db	1	;1=do backups
confirm_flag	db	1	;1=ask for confirmation.

web_browser	db	'lynx',0
                times   16  db 0	;max entry 20 characters

email_client	db	'kmail',0
		times	15  db 0	;max entry 20 characters

who_knows	db	'opener'
		times   14 db 0

end_of_a_ini:
a_ini_size	equ	end_of_a_ini - top_of_a_ini
