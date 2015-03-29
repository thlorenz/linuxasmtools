
;  extern menu_display
;  extern menu_decode

struc	menu_struc
.menu_line	resb	1	;menu display line number
.menu_columns	resb	1	;number of columns in menu
.menu_space_color resb	1	;color number for spaces
.menu_color_table resd	1	;ptr to color table
.menu_text	resd	1	;ptr to menu text line
.menu_process	resd	1	;ptr to process for each button
.menu_colors	resd	1	;ptr to color numbers for each button
.menu_keys	resd	1	;ptr to menu keys for each button
endstruc

;------------------------------------------------
display_menu:
  mov	esi,menu_line_ptrs
  call	menu_display
  ret
;------------------------------------------------
decode_menu:
  mov	esi,menu_line_ptrs
  call	menu_decode		;menu button pressed?
  ret
;------------------------------------------------
menu_setup:
  mov	ah,[crt_rows]
  mov	[menu_line4_ptrs],ah	;set row
  dec	ah
  mov	[menu_line3_ptrs],ah	;set row
  mov	al,[crt_columns]
  mov	[menu_line1_ptrs + menu_struc.menu_columns],al   
  mov	[menu_line2_ptrs + menu_struc.menu_columns],al   
  mov	[menu_line3_ptrs + menu_struc.menu_columns],al   
  mov	[menu_line4_ptrs + menu_struc.menu_columns],al
  ret   
;------------------------------------------------
  [section .data]
;-------------------------------------------------
; menu defiitions - define 4 menu lines
;
menu_line_ptrs:
  dd	menu_line1_ptrs	;pointer to menu line 1 definition
  dd	menu_line2_ptrs ;pointer to menu line 2 definition
  dd	menu_line3_ptrs ;pointer to menu line 3 definition
  dd	menu_line4_ptrs ;pointer to menu line 4 definition
  dd	0		;end of pointers
;-------
menu_line1_ptrs:
  db	1		;display at line number
  db	1		;window columns
  db	1		;color number for space between buttons
  dd	color_table	;color definitions
  dd	menu1_text	;menu text line
  dd	menu1_process	;process's to call for each button
  dd	menu1_colors	;colors associated with each button
  dd	menu1_keys	;keys associated with each button

menu_line2_ptrs:
  db	2		;line number
  db	1		;window columns
  db	1		;space color number
  dd	color_table
  dd	menu2_text
  dd	menu2_process
  dd	menu2_colors
  dd	menu2_keys

menu_line3_ptrs:
  db	3		;line number
  db	1		;window columns
  db	1		;space color number
  dd	color_table
  dd	menu3_text
  dd	menu3_process
  dd	menu3_colors
  dd	menu3_keys

menu_line4_ptrs:
  db	4		;line number
  db	1		;window columns
  db	1		;space color number
  dd	color_table
  dd	menu4_text
  dd	menu4_process
  dd	menu4_colors
  dd	menu4_keys
;------
;    hex color def: aaxxffbb  aa-attr ff-foreground  bb-background
;    30-blk 31-red 32-grn 33-brown 34-blue 35-purple 36-cyan 37-grey
;    attributes 30-normal 31-bold 34-underscore 37-inverse
color_table:
ct1:   	dd	30003730h	;color 1 grey on black - spaces, page color
ct2:   	dd	30003037h	;color 2 black on grey - button text color
ct3:    dd	30003437h	;color 3 blue on grey - highlight bar color
ct4:   	dd	30003037h	;color 4 black on grey
;------
;   menu text consists of 'space-counts' and text.  space-counts
;   are encoded as numbers from 1-8.  the end of text line has 'zero' char
;   The following  lines describe two button sets.  Each button set uses
;   two display lines.
menu1_text:
 db 1,'show   ',1,'show   ',1,'show   ',1,'show   ',4,'abort  ',1,'save   ',0
menu2_text:                                                                       
 db 1,'code(1)',1,'data(2)',1,'bss(3) ',1,'help(h)',4,'exit(a)',1,'exit(s)',0
menu3_text:                                                                       
 db 1,'code(c)',1,'data(d)',1,'label(l)',3,'undo   ',3,'goto  ',1,'goto  ',0
menu4_text:                                                                                
 db 1,' here  ',1,' here  ',1,' here   ',3,'last(u)',3,'top(t)',1,'end(e)',0

menu1_process:
menu2_process:
 dd show_code, show_data, show_bss, show_help, abort_exit, save_exit
menu3_process:
menu4_process:
 dd code_here, data_here, label_here,  undo_last, goto_top, goto_end
;-------
;colors for each button on line.  See color table above
menu1_colors:
menu2_colors:		;first color is for space, button color starts at +1
 db 2,2,2,2,2,2,2,2
menu3_colors:
menu4_colors:
 db 2,2,2,2,2,2,2,2,2
;-------
menu1_keys:
menu2_keys:
 db	'1',0	;show code
 db	'2',0	;show data
 db	'3',0	;show bss
 db	'h',0	;show help
 db	'a',0	;abort
 db	's',0	;save and exit
 db	0 ;end of keys
menu3_keys:
menu4_keys:
 db	'c',0	;code here
 db	'd',0	;data here
 db	'l',0	;label here
 db	'u',0	;undo
 db	't',0	;top of section
 db	'e',0	;end of section
 db	'f',0	;find address
 db	0 ;end of keys

;--------------------
  [section .text]

%include "menu_decode.inc"
%include "menu_display.inc"

  [section .text]


