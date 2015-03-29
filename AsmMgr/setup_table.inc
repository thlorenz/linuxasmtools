  [section .data]
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
button_color	equ	4	;used for unselected buttons
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
return_1	equ	-5	;exit program and return code 1
return_2	equ	-6	;exit program and return code 2
return_3	equ	-7	;exit program and return code 3
return_4	equ	-8	;exit program and return code 4
;--------- string codes to select def block ----
str_blk1	equ	-1	;string descriptive block #
str_blk2	equ	-2
str_blk3	equ	-3
str_blk4	equ	-4
str_blk5	equ	-5
str_blk6	equ	-6
str_blk7	equ	-7
str_blk8	equ	-8
str_blk9	equ	-9
str_blk10	equ	-10
str_blk11	equ	-11
str_blk12	equ	-12
str_blk13	equ	-13
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
; ----------- colors ---------------
; colors = aaxxffbb  (aa-attribute ff-foreground  bb-background)
;   30-black 31-red 32-green 33-brown 34-blue 35-purple 36-cyan 37-grey
;   attributes 30-normal 31-bold 34-underscore 37-inverse

edit_color		dd	30003734h	;used for normal text
edit_field_color	dd	31003734h	;modifable/slectable field
edit_entry_color	dd	31003336h	;current selection
edit_button_color	dd	30003436h	;buttons and active edit field
;norm_text_color	dd 30003734h ;used for inactive window
;			     ;grey-foreground=7 blue-backgound=4 0=norm attr
;bold_edit_color	dd 31003734h ;used for active window in edit mode
;			     ;grey-foreground=7 blue-backgound=4 0=bold attr
;bold_cmd_color	dd 31003334h ;used for active window in command mode
;			     ;grey-foreground=7 blue-backgound=4 0=bold attr
;high_text_color	dd 31003634h ;used for highlighting block
;			     ;grey-foreground=7 blue-backgound=4 0=inver attr
;asm_text_color	dd 31003234h ;used to highlight comments ";"
;			     ;cyan-foreground=6 blue-backgound=4 0=norm attr

dummy_process:	ret


  [section .text]
