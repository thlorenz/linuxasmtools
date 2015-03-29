
; structure used to describe one window.  this
; structure is passed to most window functions
; and describe current state of window.  It also
; contains information for window requests.
;
struc win
;------------- items to next dash line set by caller --------------
.s_win_x	resw 1	;our window x position, pixel column
.s_win_y	resw 1	;our window y position, pixel row
.s_win_width	resw 1	;our window width
.s_win_height	resw 1	;our window height
.s_font		resd 1  ;font number
;                       ;font numbers ae: 8- 8x
;                                         9- 9x
;                                        10- 10x
;                                        11- 11x
;                                        12- 12x
;                                        13- 13x

.s_root		resd 1	;root window id set by window_pre
.s_root_width	resw 1  ;set by window_pre
.s_root_height	resw 1	;set by window_pre
.s_map_id	resd 1	;set by window_pre

.s_cid_0	resd 1	;xx00000 master - set by window_pre
.s_win_id	resd 1	;xx00001 window_id - set by window_pre
.s_cid_1	resd 1	;xx00002 color_id  - set by window_pre
.s_font_id	resd 1	;xx00003 font_id   - set by window_font

.s_char_width	resd 1	;set by window_pre
.s_char_height	resd 1  ;set by window_pre
.s_char_ascent	resd 1
.s_char_descent resd 1

.s_text_rows	resd 1	;set by window_create
.s_text_columns resd 1  ;set by window_create

win_struc_size:
endstruc


White	equ 00	;color codes, all set by window_create
Grey	equ 04
Skyblue	equ 08
Blue	equ 12
Navy	equ 16
Cyan	equ 20
Green	equ 24
Yellow	equ 28
Gold	equ 32
Tan	equ 36
Brown	equ 40
Orange	equ 44
Red	equ 48
Maroon	equ 52
Pink	equ 56
Violet	equ 60
Purple	equ 64
Black	equ 68
