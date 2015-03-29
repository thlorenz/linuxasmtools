  extern form
  extern crt_clear
  extern env_exec
  extern file_status_name
  extern str_move
  extern env_home

  [section .text]


fill_form:
  mov	eax,[_norm_color]
  call	crt_clear
  call	tools_to_form
  mov	esi,table_pointers
  call	form
  ret
;-----------------------
our_process:		;called by form
  ret
  
;---------------------------------------------------------------------
tools_to_form:
  mov	esi,tool_table
ttf_lp:
  mov	ebp,esi
ttf_lp1:			;find color ptr
  lodsb
  or	al,al
  jnz	ttf_lp1			;loop till zero at end of name

  mov	ebx,[enviro_ptrs]
  push	esi
  call	env_exec		;search for executable
  pop	esi
  lodsd				;get color ptr
  jc	ttf_skip		;jmp if file not found
  mov	byte [eax],2		;file found, change color
ttf_skip:
  cmp	byte [esi],0		;end of table?
  jnz	ttf_lp			;jmp if more data

;check for asmlib
  mov	ebx,asmlib
  call	file_status_name
  js	ttf_exit		;exit if asmlib not found
  mov	byte [line23],2
ttf_exit:
  ret

asmlib: db '/usr/lib/asmlib.a',0
;------------------
tool_table:
  db	'as',0
  dd	line06

  db	'nasm',0
  dd	line07

  db	'yasm',0
  dd	line08

  db	'fasm',0
  dd	line09

  db	'gdb',0
  dd	line12

  db	'kdbg',0
  dd	line13

  db	'insight',0
  dd	line14

  db	'insight_',0
  dd	line14

  db	'asmbug',0
  dd	line15

  db	'ld',0
  dd	line17

  db	'ar',0
  dd	line18

  db	'make',0
  dd	line19

  db	'sed',0
  dd	line20

  db	'bash',0
  dd	line21

  db	'install',0
  dd	line22

  db	'asmedit',0
  dd	line24

  db	'asmref',0
  dd	line25


  db	0		;end of table

;---------------------------------------------------------------------
; the following data statements define a form for user input.
; One screen of data is displayed and filled in by user.
; Routine form_engine is called to process the display_tbl
;
; A form uses one screen.  It is defined by normal ascii
; text with embedded control characters.  The control characters
; are:
;    0 - end of table          5 - blank rest of screen
;    1 - color normal          6 - string, block# follows
;    2 - color field           7 - key, key# follows
;    3 - color active field    8 - process, process# follows
;    4 - color button          9 - end of line (eol)
;
; For more information see equates.
;
; As the user types or moves the mouse to fill out the
; form, all data is stored in the form.  Upon exit the
; form can be scanned by caller to obtain the data.
;
; string data will be stored in the table as entered.
; button selection is indicated by color code.  When selected
; the code "3" will indicate this button was selected.
;
; table codes use negative byte values in secondary
; fields, thus, ascii characters in range of 80h+ are not available
; as text.
;----------------------------------------------------------------------

; ----------  embedded codes --------
norm_color	equ	1	;normal text
field_color	equ	2
selected_color	equ	3	;used for selected buttons
button_color_	equ	4	;used for unselected buttons
blank_rows	equ	5	;blank all rows to bottom of screen
string		equ	6	;string block# follows, block1 is -1
key		equ	7	;key# follows, alt keys alt-a is -1
process		equ	8	;process# follows, process1 = -1
eol		equ	9	;end of data for this line.

; ---------- keys ------------------
alt_a		equ	-1	;code for key alt-a
alt_b		equ	-2
alt_c		equ	-3
alt_d		equ	-4
alt_e		equ	-5
alt_f		equ	-6
alt_g		equ	-7
alt_h		equ	-8
alt_i		equ	-9
alt_j		equ	-10
alt_k		equ	-11
alt_l		equ	-12
alt_m		equ	-13
alt_n		equ	-14
alt_o		equ	-15
alt_p		equ	-16
alt_q		equ	-17
alt_r		equ	-18
alt_s		equ	-19
alt_t		equ	-20
alt_u		equ	-21
alt_v		equ	-22
alt_w		equ	-23
alt_x		equ	-24
alt_y		equ	-25
alt_z		equ	-26

; --------- process numbers -------------------
process_string	equ	-1	;string entry, call string handler
process_button	equ	-2	;select button, call single button process
process_buttons	equ	-3	;select only this button on this line, process
null_process	equ	-4	;do nothing
return_0	equ	-5	;exit program and return code 0
return_1	equ	-6	;exit program and return code 1
;  etc.

;--------- string codes to select def block ----
str_blk1	equ	-1	;string descriptive block #
str_blk2	equ	-2
str_blk3	equ	-3
str_blk4	equ	-4
str_blk5	equ	-5
; etc.

;------- order of codes --------
; the codes are optional and can be combined to define
; a button or string.  When combined they must be in the
; following order:
;
;    string code - key code - process code - color - text - eol
;
;------ button example ------------
; db 7,-14	;use alt-n key for this button
; db 8,-2	;this button toggles, does not react with other buttons on line
; db 4		;use button color
; db "button"	;text for button is -button-
; db 1		;switch back to normal color to end button
;
;***********************************************************************
; the form table is next
;***********************************************************************

 [section .data]

; table pointers ---------

table_pointers:
	dd	our_process		;called each display cycle
	dd	color_table		;colors
	dd	string_block1		;strings
	dd	display_tbl		;display table

; ----------- colors ---------------
; colors = aaxxffbb  (aa-attribute ff-foreground  bb-background)
;   30-black 31-red 32-green 33-brown 34-blue 35-purple 36-cyan 37-grey
;   attributes 30-normal 31-bold 34-underscore 37-inverse

color_table:
_norm_color		dd	30003734h	;used for normal text
_field_color		dd	31003734h	;modifable/slectable field
_selected_color		dd	31003336h	;current selection
_button_color_		dd	30003436h	;buttons and active edit field

;---------------------------------------------------------------------
; Each string entry field needs a descriptor block.  The codes 6,-1
; specify block #1
;
string_block1:
buf1_ptr	dd	buf1	;buffer ptr
field_len1	dd	buf1_len			;allocate extra byte in form for handlers
color_ptr1	dd	_selected_color
blk1_row	db	1
blk1_column	db	buf1_column 
blk1_flag	db	0
blk1_cursor	db	buf1_column

string_block2:
buf2_ptr	dd	buf2	;buffer ptr
field_len2	dd	buf2_len			;allocate extra byte in form for handlers
color_ptr2	dd	_selected_color
blk2_row	db	2
blk2_column	db	buf2_column
blk2_flag	db	0
blk2_cursor	db	buf2_column

string_block3:
buf3_ptr	dd	buf3	;buffer ptr
field_len3	dd	buf3_len			;allocate extra byte in form for handlers
color_ptr3	dd	_selected_color
blk3_row	db	3
blk3_column	db	buf3_column
blk3_flag	db	0
blk3_cursor	db	buf3_column

string_block4:
buf4_ptr	dd	buf4	;buffer ptr
field_len4	dd	buf4_len			;allocate extra byte in form for handlers
color_ptr4	dd	_selected_color
blk4_row	db	7
blk4_column	db	buf4_column
blk4_flag	db	0
blk4_cursor	db	buf4_column

string_block5:
buf5_ptr	dd	buf5	;buffer ptr
field_len5	dd	buf5_len			;allocate extra byte in form for handlers
color_ptr5	dd	_selected_color
blk5_row	db	9
blk5_column	db	buf5_column
blk5_flag	db	0
blk5_cursor	db	buf5_column

		times 16 db 0	;block 3
;		times 16 db 0	;4
;		times 16 db 0	;5
;		times 16 db 0	;6
;		times 16 db 0	;7
;		times 16 db 0	;8
;		times 16 db 0	;9
;		times 16 db 0	;10
;		times 16 db 0	;11
;		times 16 db 0	;12
;		times 16 db 0	;13
;		times 16 db 0	;14
;		times 16 db 0	;15
;		times 16 db 0	;16
;		times 16 db 0	;17
;		times 16 db 0	;18
;		times 16 db 0	;block 19
;		times 16 db 0	;20

;----------------------------------------------------------------
; The screen form follows.
	   db process,null_process,eol	;null process definition to trap errant mice
display_tbl:

line01: db norm_color
buf1_header_start:
	db 'Project Name '
buf1_header_end:
	db string,str_blk1,process,process_string,button_color_
buf1: 	times 30 db ' '
buf1_end:
buf1_len  equ	(buf1_end - buf1)
	db norm_color
buf1_column equ (buf1_header_end - buf1_header_start) +1
	db eol

line02: db norm_color
buf2_header_start:
	db 'Project Dir  '
buf2_header_end:
	db string,str_blk2,process,process_string,button_color_
buf2: 	times 30 db ' '
buf2_end:
buf2_len  equ	(buf2_end - buf2) -1
	db norm_color
buf2_column equ (buf2_header_end - buf2_header_start) +1
	db eol

line03: db norm_color
buf3_header_start:
	db 'Project Path '
buf3_header_end:
	db string,str_blk3,process,process_string,button_color_
buf3: 	times 60 db ' '
buf3_end:
buf3_len  equ	(buf3_end - buf3) -1
	db norm_color
buf3_column equ (buf3_header_end - buf3_header_start) +1
	db eol

line04: db norm_color
 db '___________________________________________________________________________',eol

line05: db 'Assemblers found',norm_color,'  ',eol
line06: db norm_color,' as',norm_color,'              ',eol

buf4_header_start:
line07: db norm_color,' nasm',norm_color,'             '
	db 'Prefered Assembler '
buf4_header_end:
	db string,str_blk4,process,process_string,button_color_
buf4: 	times 10 db ' '
buf4_end:
buf4_len  equ	(buf4_end - buf4) -1
	db norm_color
buf4_column equ (buf4_header_end - buf4_header_start) -1
	db eol

line08: db norm_color,' yasm',norm_color,'            ',eol

buf5_header_start:
line09: db norm_color,' fasm',norm_color,'             '
	db 'Prefered Debugger '
buf5_header_end:
	db string,str_blk5,process,process_string,button_color_
buf5: 	times 10 db ' '
buf5_end:
buf5_len  equ	(buf5_end - buf5) -1
	db norm_color
buf5_column equ (buf5_header_end - buf5_header_start) -1
	db	eol

line10: db eol

line11: db 'Debuggers found',norm_color,'   '
	db 'Create makefile?           ',key,alt_a,process,process_buttons
make1:	db button_color_,'YES (alt-a)',norm_color,' ',key,alt_b,process,process_buttons
make2:  db selected_color,'NO (alt-b)',norm_color,eol

line12: db norm_color,' gdb',norm_color,'             ',eol

line13: db norm_color,' kdbg',norm_color,'             '
	db 'Create Source template?    ',key,alt_c,process,process_buttons
src1:	db button_color_,'YES (alt-c)',norm_color,' ',key,alt_d,process,process_buttons
src2:   db selected_color,'NO (alt-d)',norm_color,eol

line14: db norm_color,' insight',norm_color,'        ',eol

line15: db norm_color,' asmbug',norm_color,'              '
	db 'Create local debug script? ',key,alt_e,process,process_buttons
bug1:	db button_color_,'YES (alt-e)',norm_color,' ',key,alt_f,process,process_buttons
bug2:   db selected_color,'NO (alt-f)',norm_color,eol

line16: db 'Other tools',norm_color,'      ',eol

line17: db norm_color,' ld',norm_color,'              ',eol
line18: db norm_color,' ar',norm_color,'              ',eol
line19: db norm_color,' make',norm_color,'             ',eol
line20: db norm_color,' sed',norm_color,'             ',eol
line21: db norm_color,' bash',norm_color,'             ',eol
line22: db norm_color,' install',norm_color,'          ',eol
line23: db norm_color,' AsmLib',norm_color,'           ',eol
line24: db norm_color,' AsmEdit',norm_color,'           ',eol
line25: db norm_color,' AsmRef',norm_color,'           ',eol
line26: db eol
line27: db eol
line28: db norm_color,' ESC=abort      <F1>=save and exit',eol
	db	blank_rows	;clear to end of screen
	db	0		;end of table

;--------------------------------------------
path_buf: times 200 db 0

 [section .text]
