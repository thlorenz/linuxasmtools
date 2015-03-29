
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
;----------- event.asm ----------------------------
;
; demo program for events.
;
  extern env_stack
  extern window_pre
  extern str_move
  extern window_create
  extern window_write_line
  extern window_clear
  extern window_kill
  extern window_id_color
  extern x_key_translate
  extern x_mouse_decode
  extern lib_buf
  extern x_get_input_focus
  extern window_event_decode
  extern window_event_enable
  extern window_write_lines

  extern _white,_blue,_skyblue
  extern _pink,_black,_maroon
  extern _navy,_yellow

%include "../include/window.inc"
;---------------------
;>1 demo
;  event - demonstrate typical event driven program
; INPUTS
;  none
;
; OUTPUT:
;  events are shown as they occur and buttons
;  can be clicked to describe each event.
;              
; NOTES
;   source file: /demo/event.asm
;<
; * ----------------------------------------------
  
  global main,_start
main:
_start:
  call	env_stack
  mov	ebp,win_block
  mov	eax,the_buffer
  mov	edx,the_buffer_size
  mov	ecx,Blue	;window background color
  mov	ebx,10		;font#
  call	window_pre	;get initial conditions
  jns	win_10
  jmp	error_exit
win_10:
  mov	ax,[ebp+win.s_root_width]
  mov	[wc_block+4],ax	;set width
  mov	ax,[ebp+win.s_root_height]
  mov	[wc_block+6],ax	;set height
  mov	esi,wc_block
  
  call	window_create
  jns	win_11
  jmp	error_exit
win_11:
  call	display_init
  call	display_all	

  mov	ebx,1+2+4+8000h		;(1)keypress (2)keyrelease (4)buttonpress
  call	window_event_enable
;
  xor	edi,edi		;no command
  mov	eax,process_lst
  call	window_event_decode

  mov	eax,[norm_bcolor]		;use default color
  call	window_clear
;
;------- close window -----------------
;
  call	window_kill
  jmp	short done
;----------------------------
error_exit:
;000:>:0x0013:32: Reply to GetInputFocus: revert-to=PointerRoot(0x01) focus=0x02e00001
done:
  call	x_get_input_focus
  mov	eax,1
  int	byte 80h

;------------------------------------------------------------------------------
;event occurance comes here

error:              ;0
  ret

commandDone:        ;1
  ret

keypress:           ;2
  call	event_color
  inc	dword [keyPress_display_cnt]
  call	keyPress_display
  ret

keyRelease:         ;3
  call	event_color
  inc	dword [keyRelease_display_cnt]
  call	keyRelease_display
  ret

buttonPress:        ;4
 inc	dword [buttonPress_display_cnt]
 mov	esi,button_decode_table
 call	x_mouse_decode 
 jz	bp_skip		;jmp if no button pressed
 push	eax
 call	display_init
 call	display_all
 call	event_color
 pop	eax
 call	eax
 jmp	buttonPress_done
bp_skip:
 call	buttonPress_display
buttonPress_done:
 ret

buttonRelease:      ;5
 ret
motionNotify:       ;6
 ret
enterNotify:        ;7
 ret
leaveNotify:        ;8
 ret
focusIn:            ;9
 ret
focusOut:           ;10
 ret
keymapNotify:       ;11
 ret
expose:             ;12
 call	display_restore
 inc	dword [expose_display_cnt]
 call	event_color
 call	expose_display
 ret
graphicsExpose:     ;13
 ret
noExpose:           ;14
 ret
visibilityNotify:   ;15
 ret
createNotify:       ;16
 ret
destroyNotify:		;17
 ret
unmapNotify:		;18
 ret
mapNotify:		;19
 ret
mapRequest:		;20
 ret
reparentNotify:		;21
 ret
configureNotify:		;22
 ret
configureRequest:	;23
 ret
gravityNotify:		;24
 ret
resizeRequest:		;25
 ret
circulateNotify:		;26
 ret
circulateRequest:	;27
 ret
propertyNotify:		;28
 ret
selectionClear:		;29
 ret
selectionRequest:	;30
 ret
selectionNotify:		;31
 ret
colormapNotify:		;32
 ret
clientMessage:		;33
 ret
mappingNotify:		;34
 ret
;------------------------------------------------------------------------------
;clicking on a button comes here

error_clicked:              ;0
  call	display_restore
  call	error_display
  mov	eax,error_display_txt
  call	show_paragraph
  ret

commandDone_clicked:        ;1
  call	display_restore
  call	commandDone_display
  mov	eax,commandDone_display_txt
  call	show_paragraph
  ret

keyPress_clicked:           ;2
  call	display_restore
  call	keyPress_display
  mov	eax,keyPress_display_txt
  call	show_paragraph
  ret

keyRelease_clicked:         ;3
  call	display_restore
  call	keyRelease_display
  mov	eax,keyRelease_display_txt
  call	show_paragraph
  ret

buttonPress_clicked:        ;4
  call	display_restore
  call	buttonPress_display
  mov	eax,buttonPress_display_txt
  call	show_paragraph
  ret

buttonRelease_clicked:      ;5
  call	display_restore
  call	buttonRelease_display
  mov	eax,buttonRelease_display_txt
  call	show_paragraph
 ret
motionNotify_clicked:       ;6
  call	display_restore
  call	motionNotify_display
  mov	eax,motionNotify_display_txt
  call	show_paragraph
 ret
enterNotify_clicked:        ;7
  call	display_restore
  call	enterNotify_display
  mov	eax,enterNotify_display_txt
  call	show_paragraph
 ret
leaveNotify_clicked:        ;8
  call	display_restore
  call	leaveNotify_display
  mov	eax,leaveNotify_display_txt
  call	show_paragraph
 ret
focusIn_clicked:            ;9
  call	display_restore
  call	focusIn_display
  mov	eax,focusIn_display_txt
  call	show_paragraph
 ret
focusOut_clicked:           ;10
  call	display_restore
  call	focusOut_display
  mov	eax,focusOut_display_txt
  call	show_paragraph
 ret
keymapNotify_clicked:       ;11
  call	display_restore
  call	keymapNotify_display
  mov	eax,keymapNotify_display_txt
  call	show_paragraph
 ret
expose_clicked:             ;12
  call	display_restore
  call	expose_display
  mov	eax,expose_display_txt
  call	show_paragraph
 ret
graphicsExpose_clicked:     ;13
  call	display_restore
  call	graphicsExpose_display
  mov	eax,graphicsExpose_display_txt
  call	show_paragraph
 ret
noExpose_clicked:           ;14
  call	display_restore
  call	noExpose_display
  mov	eax,noExpose_display_txt
  call	show_paragraph
 ret
visibilityNotify_clicked:   ;15
  call	display_restore
  call	visibilityNotify_display
  mov	eax,visibilityNotify_display_txt
  call	show_paragraph
 ret
createNotify_clicked:       ;16
  call	display_restore
  call	createNotify_display
  mov	eax,createNotify_display_txt
  call	show_paragraph
 ret
destroyNotify_clicked:		;17
  call	display_restore
  call	destroyNotify_display
  mov	eax,destroyNotify_display_txt
  call	show_paragraph
 ret
unmapNotify_clicked:		;18
  call	display_restore
  call	unmapNotify_display
  mov	eax,unmapNotify_display_txt
  call	show_paragraph
 ret
mapNotify_clicked:		;19
  call	display_restore
  call	mapNotify_display
  mov	eax,mapNotify_display_txt
  call	show_paragraph
 ret
mapRequest_clicked:		;20
  call	display_restore
  call	mapRequest_display
  mov	eax,mapRequest_display_txt
  call	show_paragraph
 ret
reparentNotify_clicked:		;21
  call	display_restore
  call	reparentNotify_display
  mov	eax,reparentNotify_display_txt
  call	show_paragraph
 ret
configureNotify_clicked:		;22
  call	display_restore
  call	configureNotify_display
  mov	eax,configureNotify_display_txt
  call	show_paragraph
 ret
configureRequest_clicked:	;23
  call	display_restore
  call	configureRequest_display
  mov	eax,configureRequest_display_txt
  call	show_paragraph
 ret
gravityNotify_clicked:		;24
  call	display_restore
  call	gravityNotify_display
  mov	eax,gravityNotify_display_txt
  call	show_paragraph
 ret
resizeRequest_clicked:		;25
  call	display_restore
  call	resizeRequest_display
  mov	eax,resizeRequest_display_txt
  call	show_paragraph
 ret
circulateNotify_clicked:		;26
  call	display_restore
  call	circulateNotify_display
  mov	eax,circulateNotify_display_txt
  call	show_paragraph
 ret
circulateRequest_clicked:	;27
  call	display_restore
  call	circulateRequest_display
  mov	eax,circulateRequest_display_txt
  call	show_paragraph
 ret
propertyNotify_clicked:		;28
  call	display_restore
  call	propertyNotify_display
  mov	eax,propertyNotify_display_txt
  call	show_paragraph
 ret
selectionClear_clicked:		;29
  call	display_restore
  call	selectionClear_display
  mov	eax,selectionClear_display_txt
  call	show_paragraph
 ret
selectionRequest_clicked:	;30
  call	display_restore
  call	selectionRequest_display
  mov	eax,selectionRequest_display_txt
  call	show_paragraph
 ret
selectionNotify_clicked:		;31
  call	display_restore
  call	selectionNotify_display
  mov	eax,selectionNotify_display_txt
  call	show_paragraph
 ret
colormapNotify_clicked:		;32
  call	display_restore
  call	colormapNotify_display
  mov	eax,colormapNotify_display_txt
  call	show_paragraph
 ret
clientMessage_clicked:		;33
  call	display_restore
  call	clientMessage_display
  mov	eax,clientMessage_display_txt
  call	show_paragraph
 ret
mappingNotify_clicked:		;34
  call	display_restore
  call	mappingNotify_display
  mov	eax,mappingNotify_display_txt
  call	show_paragraph
 ret

intro_clicked:
  call	display_restore
  call	intro_button_display
  mov	eax,intro_button_display_txt
  call	show_paragraph
 ret

design_clicked:
  call	display_restore
  call	design_button_display
  mov	eax,design_button_display_txt
  call	show_paragraph
 ret

exit_clicked:
  call	display_restore
  call	exit_button_display
  mov	eax,80000000h	;force normal exit
 ret
;--------------------------------------------------------------
;input eax=text ptr
show_paragraph:
  mov	[ptext],eax

  mov	ebx,[para_fcolor]
  mov	ecx,[para_bcolor]
  call	window_id_color

  mov	edx,para_block
  call	window_write_lines
  ret

;-------------
  [section .data]
para_block:
        dd 7  ;number of rows in area
        dd 80 ;number of columns in area
        dd 18 ;starting row
        dd 1  ;starting column
ptext:  dd 0  ;text block ptr, lines end with 0ah,
  [section .text]

;------------------------------------------------
display_restore:
  mov	ebx,[norm_fcolor]
  mov	ecx,[norm_bcolor]
  call	window_id_color
  mov	eax,1
  call	window_clear
  mov	ebx,[but_fcolor]
  mov	ecx,[but_bcolor]
  call	window_id_color
  call	display_all
  ret
;------
event_color:
  mov	eax,[but_sel_bcolor]
  mov	[but_cur_bcolor],eax
  mov	eax,[but_sel_fcolor]
  mov	[but_cur_fcolor],eax
  ret
;------
button_color:
  mov	eax,[but_bcolor]
  mov	[but_cur_bcolor],eax
  mov	eax,[but_fcolor]
  mov	[but_cur_fcolor],eax
  ret
;------
  [section .data]

font_string: db '10x20',0

string1: db 'Press any key'
string1_len equ $ - string1

process_lst:
           dd  error              ;0
           dd  commandDone        ;1
           dd  keypress           ;2
           dd  keyRelease         ;3
           dd  buttonPress        ;4
           dd  buttonRelease      ;5
           dd  motionNotify       ;6
           dd  enterNotify        ;7
           dd  leaveNotify        ;8
           dd  focusIn            ;9
           dd  focusOut           ;10
           dd  keymapNotify       ;11
           dd  expose             ;12
           dd  graphicsExpose     ;13
           dd  noExpose           ;14
           dd  visibilityNotify   ;15
           dd  createNotify       ;16
           dd  destroyNotify		;17
           dd  unmapNotify		;18
           dd  mapNotify		;19
           dd  mapRequest		;20
           dd  reparentNotify		;21
           dd  configureNotify		;22
           dd  configureRequest	;23
           dd  gravityNotify		;24
           dd  resizeRequest		;25
           dd  circulateNotify		;26
           dd  circulateRequest	;27
           dd  propertyNotify		;28
           dd  selectionClear		;29
           dd  selectionRequest	;30
           dd  selectionNotify		;31
           dd  colormapNotify		;32
           dd  clientMessage		;33
           dd  mappingNotify		;34

  [section .bss]
 align 4

the_buffer resb 24000
the_buffer_size equ $ - the_buffer

win_block: resb win_struc_size

 [section .text]

  extern dword_to_lpadded_ascii
  extern window_clear_area
  extern byteto_hexascii

;------------------ event_display.inc --------------------------------


;--------- event_display.inc -------------

display_init:
  mov	eax,[_blue]
  mov	[norm_bcolor],eax
  mov	eax,[_white]
  mov	[norm_fcolor],eax

  mov	eax,[_skyblue]
  mov	[but_bcolor],eax
  mov	[but_cur_bcolor],eax
  mov	eax,[_black]
  mov	[but_fcolor],eax
  mov	[but_cur_fcolor],eax

  mov	eax,[_pink]
  mov	[but_sel_bcolor],eax
  mov	eax,[_maroon]
  mov	[but_sel_fcolor],eax

  mov	eax,[_navy]
  mov	[para_bcolor],eax
  mov	eax,[_yellow]
  mov	[para_fcolor],eax

  mov	ebx,[but_cur_fcolor]
  mov	ecx,[but_cur_bcolor]
  call	window_id_color

  ret

display_all:
  call  error_display      ;0
  call  commandDone_display        ;1
  call  keyPress_display           ;2
  call  keyRelease_display         ;3
  call  buttonPress_display        ;4
  call  buttonRelease_display      ;5
  call  motionNotify_display       ;6
  call  enterNotify_display        ;7
  call  leaveNotify_display        ;8
  call  focusIn_display            ;9
  call  focusOut_display           ;10
  call  keymapNotify_display       ;11
  call  expose_display             ;12
  call  graphicsExpose_display     ;13
  call  noExpose_display           ;14
  call  visibilityNotify_display   ;15
  call  createNotify_display       ;16
  call  destroyNotify_display		;17
  call  unmapNotify_display		;18
  call  mapNotify_display		;19
  call  mapRequest_display		;20
  call  reparentNotify_display		;21
  call  configureNotify_display		;22
  call  configureRequest_display	;23
  call  gravityNotify_display		;24
  call  resizeRequest_display		;25
  call  circulateNotify_display		;26
  call  circulateRequest_display	;27
  call  propertyNotify_display		;28
  call  selectionClear_display		;29
  call  selectionRequest_display	;30
  call  selectionNotify_display		;31
  call  colormapNotify_display		;32
  call  clientMessage_display		;33
  call  mappingNotify_display		;34
  call  intro_button_display
  call	design_button_display
  call	exit_button_display
  call	clear_message_area
  ret

error_display:              ;0
  mov	eax,[error_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,error_display_but
  call	str_move		;move button name
;display button
  mov	ecx,02			;display column
  mov	edx,01			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
  ret

commandDone_display:        ;1
  mov	eax,[commandDone_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,commandDone_display_but
  call	str_move		;move button name
;display button
  mov	ecx,17			;display column
  mov	edx,01			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
  ret

keyPress_display:           ;2
  mov	eax,[keyPress_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,keyPress_display_but
  call	str_move		;move button name
;check if key event in lib_buf
  cmp	byte [lib_buf],2
  jne	keyPress_50
  mov	ecx,lib_buf		;get adr of pkt
  call	x_key_translate
  push	eax
  mov	al,ah			;get flags
  call	byteto_hexascii
  mov	al,' '
  stosb
  pop	eax			;resore flag & char
  test	ah,80h			;is this printable
  jnz	printable
;non printable code or ascii
  call	byteto_hexascii
  jmp	short keyPress_50
printable:
  push	eax
  mov	al,22h			;"char
  stosb
  pop	eax
  stosb
  mov	al,22h
  stosb
keyPress_50:
;display button
  mov	ecx,34			;display column
  mov	edx,01			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line

;  extern hex_dump_stdout
;  extern write_char_to_stdout

;  mov	ecx,32
;  mov	esi,lib_buf
;  call	hex_dump_stdout
;  mov	al,0ah
;  call	write_char_to_stdout

  ret

keyRelease_display:         ;3
  mov	eax,[keyRelease_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,keyRelease_display_but
  call	str_move		;move button name
;check if key event in lib_buf
  cmp	byte [lib_buf],3
  jne	keyR_50
  mov	ecx,lib_buf		;get adr of pkt
  call	x_key_translate
  push	eax
  mov	al,ah			;get flags
  call	byteto_hexascii
  mov	al,' '
  stosb
  pop	eax			;resore flag & char
  test	ah,80h			;is this printable
  jnz	printable1
;non printable code or ascii
  call	byteto_hexascii
  jmp	short keyR_50
printable1:
  push	eax
  mov	al,22h			;"char
  stosb
  pop	eax
  stosb
  mov	al,22h
  stosb
keyR_50:
;display button
  mov	ecx,50			;display column
  mov	edx,01			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
  ret

buttonPress_display:        ;4
  mov	eax,[buttonPress_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,buttonPress_display_but
  call	str_move		;move button name
;display button
  mov	ecx,68			;display column
  mov	edx,01			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

buttonRelease_display:      ;5
  mov	eax,[buttonRelease_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,buttonRelease_display_but
  call	str_move		;move button name
;display button
  mov	ecx,02			;display column
  mov	edx,03			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

motionNotify_display:       ;6
  mov	eax,[motionNotify_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,motionNotify_display_but
  call	str_move		;move button name
;display button
  mov	ecx,17			;display column
  mov	edx,03			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

enterNotify_display:        ;7
  mov	eax,[enterNotify_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,enterNotify_display_but
  call	str_move		;move button name
;display button
  mov	ecx,34			;display column
  mov	edx,03			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret
leaveNotify_display:        ;8
  mov	eax,[leaveNotify_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,leaveNotify_display_but
  call	str_move		;move button name
;display button
  mov	ecx,50			;display column
  mov	edx,03			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

focusIn_display:            ;9
  mov	eax,[focusIn_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,focusIn_display_but
  call	str_move		;move button name
;display button
  mov	ecx,68			;display column
  mov	edx,03			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

focusOut_display:           ;10
  mov	eax,[focusOut_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,focusOut_display_but
  call	str_move		;move button name
;display button
  mov	ecx,02			;display column
  mov	edx,05			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

keymapNotify_display:       ;11
  mov	eax,[keymapNotify_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,keymapNotify_display_but
  call	str_move		;move button name
;display button
  mov	ecx,17			;display column
  mov	edx,05			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

expose_display:             ;12
  mov	eax,[expose_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,expose_display_but
  call	str_move		;move button name
;display button
  mov	ecx,34			;display column
  mov	edx,05			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

graphicsExpose_display:     ;13
  mov	eax,[graphicsExpose_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,graphicsExpose_display_but
  call	str_move		;move button name
;display button
  mov	ecx,50			;display column
  mov	edx,05			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

noExpose_display:           ;14
  mov	eax,[noExpose_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,noExpose_display_but
  call	str_move		;move button name
;display button
  mov	ecx,68			;display column
  mov	edx,05			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

visibilityNotify_display:   ;15
  mov	eax,[visibilityNotify_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,visibilityNotify_display_but
  call	str_move		;move button name
;display button
  mov	ecx,02			;display column
  mov	edx,07			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

createNotify_display:       ;16
  mov	eax,[createNotify_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,createNotify_display_but
  call	str_move		;move button name
;display button
  mov	ecx,17			;display column
  mov	edx,07			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

destroyNotify_display:		;17
  mov	eax,[destroyNotify_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,destroyNotify_display_but
  call	str_move		;move button name
;display button
  mov	ecx,34			;display column
  mov	edx,07			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

unmapNotify_display:		;18
  mov	eax,[unmapNotify_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,unmapNotify_display_but
  call	str_move		;move button name
;display button
  mov	ecx,50			;display column
  mov	edx,07			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

mapNotify_display:		;19
  mov	eax,[mapNotify_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,mapNotify_display_but
  call	str_move		;move button name
;display button
  mov	ecx,68			;display column
  mov	edx,07			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

mapRequest_display:		;20
  mov	eax,[mapRequest_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,mapRequest_display_but
  call	str_move		;move button name
;display button
  mov	ecx,02			;display column
  mov	edx,09			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

reparentNotify_display:		;21
  mov	eax,[reparentNotify_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,reparentNotify_display_but
  call	str_move		;move button name
;display button
  mov	ecx,17			;display column
  mov	edx,09			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

configureNotify_display:		;22
  mov	eax,[configureNotify_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,configureNotify_display_but
  call	str_move		;move button name
;display button
  mov	ecx,34			;display column
  mov	edx,09			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

configureRequest_display:	;23
  mov	eax,[configureRequest_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,configureRequest_display_but
  call	str_move		;move button name
;display button
  mov	ecx,50			;display column
  mov	edx,09			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

gravityNotify_display:		;24
  mov	eax,[gravityNotify_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,gravityNotify_display_but
  call	str_move		;move button name
;display button
  mov	ecx,68			;display column
  mov	edx,09			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

resizeRequest_display:		;25
  mov	eax,[resizeRequest_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,resizeRequest_display_but
  call	str_move		;move button name
;display button
  mov	ecx,02			;display column
  mov	edx,11			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

circulateNotify_display:		;26
  mov	eax,[circulateNotify_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,circulateNotify_display_but
  call	str_move		;move button name
;display button
  mov	ecx,17			;display column
  mov	edx,11			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

circulateRequest_display:	;27
  mov	eax,[circulateRequest_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,circulateRequest_display_but
  call	str_move		;move button name
;display button
  mov	ecx,34			;display column
  mov	edx,11			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

propertyNotify_display:		;28
  mov	eax,[propertyNotify_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,propertyNotify_display_but
  call	str_move		;move button name
;display button
  mov	ecx,50			;display column
  mov	edx,11			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

selectionClear_display:		;29
  mov	eax,[selectionClear_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,selectionClear_display_but
  call	str_move		;move button name
;display button
  mov	ecx,68			;display column
  mov	edx,11			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

selectionRequest_display:	;30
  mov	eax,[selectionRequest_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,selectionRequest_display_but
  call	str_move		;move button name
;display button
  mov	ecx,02			;display column
  mov	edx,13			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

selectionNotify_display:		;31
  mov	eax,[selectionNotify_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,selectionNotify_display_but
  call	str_move		;move button name
;display button
  mov	ecx,17			;display column
  mov	edx,13			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret
colormapNotify_display:		;32
  mov	eax,[colormapNotify_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,colormapNotify_display_but
  call	str_move		;move button name
;display button
  mov	ecx,34			;display column
  mov	edx,13			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

clientMessage_display:		;33
  mov	eax,[clientMessage_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,clientMessage_display_but
  call	str_move		;move button name
;display button
  mov	ecx,50			;display column
  mov	edx,13			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

mappingNotify_display:		;34
  mov	eax,[mappingNotify_display_cnt]	;get event occurance count
  mov	edi,button_build_buf
  mov	cl,2			;number of bytes to store
  mov	ch,'0'			;pad char
  push	ebp
  call	dword_to_lpadded_ascii	;store event count
  pop	ebp
  mov	al,'-'
  stosb				;store separator
  mov	esi,mappingNotify_display_but
  call	str_move		;move button name
;display button
  mov	ecx,68			;display column
  mov	edx,13			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
 ret

intro_button_display:
  mov	edi,button_build_buf
  mov	esi,intro_button_display_but
  call	str_move		;move button name
;display button
  mov	ecx,17			;display column
  mov	edx,15			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
  ret

design_button_display:
  mov	edi,button_build_buf
  mov	esi,design_button_display_but
  call	str_move		;move button name
;display button
  mov	ecx,34			;display column
  mov	edx,15			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
  ret

exit_button_display:
  mov	edi,button_build_buf
  mov	esi,exit_button_display_but
  call	str_move		;move button name
;display button
  mov	ecx,50			;display column
  mov	edx,15			;display row
  mov	esi,button_build_buf	;ptr to display string
  sub	edi,esi			;compute string length
  call	window_write_line	;display line
  ret

clear_message_area:
  mov	ebx,[para_fcolor]
  mov	ecx,[para_bcolor]
  call	window_id_color

  mov	eax,1		;column
  mov	ebx,18		;row
  mov	ecx,[ebp+win.s_text_columns]
  mov	edx,[ebp+win.s_text_rows]
  sub	edx,17
  jns	do_clear
  mov	edx,1
do_clear:
  mov	esi,1		;force current color
  call	window_clear_area  
  ret
;--------------------
  [section .data]
norm_bcolor:    dd 0	;normal display background color
norm_fcolor:	dd 0	;nommal display foreground color

but_bcolor:	dd 0	;inactive button background color
but_fcolor:	dd 0	;inactive button foreground color

but_sel_bcolor:	dd 0	;pressed button background color
but_sel_fcolor:	dd 0	;pressed button foreground color

but_cur_bcolor:	dd 0	;current display background color
but_cur_fcolor:	dd 0	;current display foreground color

para_bcolor:	dd 0	;pargraph background color
para_fcolor:	dd 0	;paragaph foreground color


button_build_buf: times 20 db 0

;%include "event_data.inc"

;----------------- event_data.inc --------------------------

  [section .data]


error_display_cnt:              ;0
  dd 0	;counter
error_display_but:              ;0
  db 'error',0
error_display_txt:              ;0
  db 'The x server sends 17 different error types of error',0ah
  db 'events.  Each error event is 32 bytes long and',0ah
  db 'starts with zero byte, followed by error type byte',0ah
  db 0

commandDone_display_cnt:        ;1
  dd 0	;counter
commandDone_display_but:        ;1
  db 'commandDone',0
commandDone_display_txt:        ;1
 db 'Commands sent to the  x server may have a reply.  All replies are',0ah
 db 'of type ',22h,'commandDone',22h,'.  Replies can be any length, but',0ah
 db 'start with a code of 1 signifying it is a commandDone.',0

keyPress_display_cnt:           ;2
  dd 0	;counter
keyPress_display_but:           ;2
  db 'keyDn=',0
keyPress_display_txt:           ;2
 db 'If enabled, the key press event generates a 32 byte packet each',0ah
 db 'time a key is pressed.  The packet starts with a code (2) byte and',0ah
 db 'describes the key pressed.  It is easy to generate this event by',0ah
 db 'pressing a key.  The keyPress button will show: cc-keyPress xx yy',0ah
 db 'Where: cc = event counter  xx=flags  yy=key code or char',0ah
 db '     flags are: 80=ascii 10=numlock 08-alt 04-ctrl 02-caplock 01-shift',0


keyRelease_display_cnt:         ;3
  dd 0	;counter
keyRelease_display_but:         ;3
  db 'keyUp=',0
keyRelease_display_txt:         ;3
 db 'This event is generated each time a key is released.  See KeyPress',0ah
 db 'event for related information.  To generate this event now, press',0ah
 db 'any key.',0

buttonPress_display_cnt:        ;4
  dd 0	;counter
buttonPress_display_but:        ;4
  db 'buttonDown',0
buttonPress_display_txt:        ;4
  db 'ButtonPress events are generated whenever a mouse button is pressed.',0

buttonRelease_display_cnt:      ;5
  dd 0	;counter
buttonRelease_display_but:      ;5
  db 'buttonUp',0
buttonRelease_display_txt:      ;5
 db 'ButtonRelease events are generated whenever a mouse button is released.',0

motionNotify_display_cnt:       ;6
  dd 0	;counter
motionNotify_display_but:       ;6
  db 'motion',0
motionNotify_display_txt:       ;6
 db 'MotionNotify events are generated whenever the mouse pointer moves',0
 db 'If the motion does not begin or end in the focused window, this event',0ah
 db 'is not generated',0

enterNotify_display_cnt:        ;7
  dd 0	;counter
enterNotify_display_but:        ;7
  db 'enter',0
enterNotify_display_txt:        ;7
 db 'If pointer motion or window hierarchy change causes the pointer to enter',0ah
 db 'a different window, EnterNotify us generated.',0

leaveNotify_display_cnt:        ;8
  dd 0	;counter
leaveNotify_display_but:        ;8
  db 'leave',0
leaveNotify_display_txt:        ;8
 db 'If pointer motion or window heirachy change causes the ponter to leave',0ah
 db 'a window, LeaveNotify events are created.',0


focusIn_display_cnt:            ;9
  dd 0	;counter
focusIn_display_but:            ;9
  db 'focusIn',0
focusIn_display_txt:            ;9
 db 'FocusIn events are generated when the input focus changes',0

focusOut_display_cnt:           ;10
  dd 0	;counter
focusOut_display_but:           ;10
  db 'focusOut',0
focusOut_display_txt:           ;10
  db 'FocusOut events are generated when the input foucs changes',0

keymapNotify_display_cnt:       ;11
  dd 0	;counter
keymapNotify_display_but:       ;11
  db 'keymap',0
keymapNotify_display_txt:       ;11
 db 'The value is a bit vector as described in QueryKeymap. This',0ah
 db 'event is reported to clients selecting KeymapState on a win-',0ah
 db 'dow and is generated immediately after every EnterNotify and',0ah
 db 'FocusIn.',0

expose_display_cnt:             ;12
  dd 0	;counter
expose_display_but:             ;12
  db 'expose',0
expose_display_txt:             ;12
 db 'Expose is generated when a window is uncovered',0

graphicsExpose_display_cnt:     ;13
  dd 0	;counter
graphicsExpose_display_but:     ;13
  db 'graphicExpose',0
graphicsExpose_display_txt:     ;13
 db 'This event is reported to a client using a graphics context',0ah
 db 'with graphics-exposures selected and is generated when a',0ah
 db 'destination region could not be computed due to an obscured',0ah
 db 'or out-of-bounds source region.',0

noExpose_display_cnt:           ;14
  dd 0	;counter
noExpose_display_but:           ;14
  db 'noExpose',0
noExpose_display_txt:           ;14
 db 'This event is reported to a client using a graphics context',0ah
 db 'with graphics-exposures selected and is generated when a',0ah
 db 'graphics request that might produce GraphicsExposure events',0ah
 db 'does not produce any.  The drawable specifies the',0ah
 db 'destination used for the graphics request.',0

visibilityNotify_display_cnt:   ;15
  dd 0	;counter
visibilityNotify_display_but:   ;15
  db 'visibility',0
visibilityNotify_display_txt:   ;15
 db 'This event is reported to clients selecting VisibilityChange',0ah
 db 'on the window.	In the following, the state of the window is',0ah
 db 'calculated ignoring all of the windows subwindows.  When a',0ah
 db 'window changes state from partially or fully obscured or not',0ah
 db 'viewable to viewable and completely unobscured, an event',0ah
 db 'with Unobscured is generated.',0

createNotify_display_cnt:       ;16
  dd 0	;counter
createNotify_display_but:       ;16
  db 'create',0
createNotify_display_txt:       ;16
 db 'This event is reported to clients selecting SubstructureNo-',0ah
 db 'tify on the parent and is generated when the window is',0ah
 db 'created.  The arguments are as in the CreateWindow request.',0ah,0

destroyNotify_display_cnt:		;17
  dd 0	;counter
destroyNotify_display_but:		;17
  db 'destroy',0
destroyNotify_display_txt:		;17
 db 'This event is reported to clients selecting StructureNotify',0ah
 db 'on the window and to clients selecting SubstructureNotify on',0ah
 db 'the parent.  It is generated when the window is destroyed.',0ah
 db 'The event is the window on which the event was generated,',0ah
 db 'and the window is the window that is destroyed.',0ah,0

unmapNotify_display_cnt:		;18
  dd 0	;counter
unmapNotify_display_but:		;18
  db 'unmap',0
unmapNotify_display_txt:		;18
 db 'This event is reported to clients selecting StructureNotify',0ah
 db 'on the window and to clients selecting SubstructureNotify on',0ah
 db 'the parent.  It is generated when the window changes state',0ah
 db 'from mapped to unmapped.',0

mapNotify_display_cnt:		;19
  dd 0	;counter
mapNotify_display_but:		;19
  db 'map',0
mapNotify_display_txt:		;19
 db 'This event is reported to clients selecting StructureNotify',0ah
 db 'on the window and to clients selecting SubstructureNotify on',0ah
 db 'the parent.  It is generated when the window changes state',0ah
 db 'from unmapped to mapped.',0

mapRequest_display_cnt:		;20
  dd 0	;counter
mapRequest_display_but:		;20
  db 'mapRequest',0
mapRequest_display_txt:		;20
 db 'This event is reported to the client selecting SubstructureRedirect',0ah
 db 'on the parent and is generated when a MapWindow request is issued on',0ah
 db 'an unmapped window with an overrideredirect attribute of False.',0

reparentNotify_display_cnt:		;21
  dd 0	;counter
reparentNotify_display_but:		;21
  db 'reparent',0
reparentNotify_display_txt:		;21
 db 'This event is reported to clients selecting SubstructureNotify',0ah
 db 'on either the old or the new parent and to clients selecting',0ah
 db 'StructureNotify on the window.  It is generated when the window',0ah
 db 'is reparented.',0

configureNotify_display_cnt:		;22
  dd 0	;counter
configureNotify_display_but:		;22
  db 'configure',0
configureNotify_display_txt:		;22
 db 'This event is reported to clients selecting StructureNotify',0ah
 db 'on the window and to clients selecting SubstructureNotify on',0ah
 db 'the parent.  It is generated when a ConfigureWindow request',0ah
 db 'actually changes the state of the window.',0

configureRequest_display_cnt:	;23
  dd 0	;counter
configureRequest_display_but:	;23
  db 'configReq',0
configureRequest_display_txt:	;23
 db 'This event is reported to the client selecting SubstructureRedirect',0ah
 db 'on the parent and is generated when a ConfigureWindow request',0ah
 db 'is issued on the window by some other client.',0

gravityNotify_display_cnt:		;24
  dd 0	;counter
gravityNotify_display_but:		;24
  db 'gravity',0
gravityNotify_display_txt:		;24
 db 'This event is reported to clients selecting SubstructureNotify',0ah
 db 'on the parent and to clients selecting StructureNotify on the',0ah
 db 'window. It is generated when a window is moved because of a',0ah
 db 'change in size of the parent.',0

resizeRequest_display_cnt:		;25
  dd 0	;counter
resizeRequest_display_but:		;25
  db 'resize',0
resizeRequest_display_txt:		;25
 db 'This event is reported to the client selecting ResizeRedirect',0ah
 db 'on the window and is generated when a ConfigureWindow',0ah
 db 'request by some other client on the window attempts to',0ah
 db 'change the size of the window.	The width and height are the',0ah
 db 'requested inside size, not including the border.',0

circulateNotify_display_cnt:		;26
  dd 0	;counter
circulateNotify_display_but:		;26
  db 'circulate',0
circulateNotify_display_txt:		;26
 db 'This event is reported to clients selecting StructureNotify',0ah
 db 'on the window and to clients selecting SubstructureNotify on',0ah
 db 'the parent.  It is generated when the window is actually',0ah
 db 'restacked from a CirculateWindow request.',0

circulateRequest_display_cnt:	;27
  dd 0	;counter
circulateRequest_display_but:	;27
  db 'circReq',0
circulateRequest_display_txt:	;27
 db 'This event is reported to the client selecting SubstructureRedirect',0ah
 db 'on the parent and is generated when a CirculateWindow request',0ah
 db 'is issued on the parent and a window actually needs to be restacked.',0

propertyNotify_display_cnt:		;28
  dd 0	;counter
propertyNotify_display_but:		;28
  db 'property',0
propertyNotify_display_txt:		;28
 db 'This event is reported to clients selecting PropertyChange',0ah
 db 'on the window and is generated with state NewValue when a',0ah
 db 'property of the window is changed using ChangeProperty or',0ah
 db 'RotateProperties, even when adding zero-length data using',0ah
 db 'ChangeProperty and when replacing all or part of a property',0ah
 db 'with identical data using ChangeProperty or RotateProperties.',0

selectionClear_display_cnt:		;29
  dd 0	;counter
selectionClear_display_but:		;29
  db 'selectClr',0
selectionClear_display_txt:		;29
 db 'This event is reported to the current owner of a selection',0ah
 db 'and is generated when a new owner is being defined by means',0ah
 db 'of SetSelectionOwner.  The timestamp is the last-change time',0ah
 db 'recorded for the selection.  The owner argument is the window',0ah
 db ' that was specified by the current owner in its',0ah
 db 'SetSelectionOwner request.',0

selectionRequest_display_cnt:	;30
  dd 0	;counter
selectionRequest_display_but:	;30
  db 'selectReq',0
selectionRequest_display_txt:	;30
 db 'This event is reported to the owner of a selection and is',0ah
 db 'generated when a client issues a ConvertSelection request.',0ah
 db 'The owner argument is the window that was specified in the',0ah
 db 'SetSelectionOwner request.  The remaining arguments are as',0ah
 db 'in the ConvertSelection request.',0

selectionNotify_display_cnt:		;31
  dd 0	;counter
selectionNotify_display_but:		;31
  db 'selection',0
selectionNotify_display_txt:		;31
 db 'This event is generated by the server in response to a',0ah
 db 'ConvertSelection request when there is no owner for the',0ah
 db 'selection.',0

colormapNotify_display_cnt:		;32
  dd 0	;counter
colormapNotify_display_but:		;32
  db 'colormap',0
colormapNotify_display_txt:		;32
 db 'This event is reported to clients selecting ColormapChange',0ah
 db 'on the window.',0

clientMessage_display_cnt:		;33
  dd 0	;counter
clientMessage_display_but:		;33
  db 'clientMsg',0
clientMessage_display_txt:		;33
 db 'This event is only generated by clients using SendEvent.',0

mappingNotify_display_cnt:		;34
  dd 0	;counter
mappingNotify_display_but:		;34
  db 'mappingN',0
mappingNotify_display_txt:		;34
 db 'This event is sent to all clients.  There is no mechanism to',0ah
 db 'disable this event.',0

intro_button_display_cnt:
  dd 0	;counter
intro_button_display_but:
  db 'help',0
intro_button_display_txt:
 db 'Events are reported as they occur, and in many instances must',0ah
 db 'be created by an external program.  One exception is the key press',0ah
 db 'event.  Press any key to see a keypress event.',0ah
 db 'To see a description of any event, click its button.',0

design_button_display_cnt:
  dd 0	;counter
design_button_display_but:
  db 'design',0
design_button_display_txt:
 db 'The x server socket interface encourages programs that work',0ah
 db 'somewhat asyncronusly.  This means events can happen at any time',0ah
 db 'and the program must be ready to respond.  Also, it may be necessary',0ah
 db 'to redraw windows anytime a Expose event occurs.  This program',0ah
 db 'demonstrates the use of library functions to create a typical program',0

exit_button_display_cnt:
  dd 0	;counter
exit_button_display_but:
  db 'exit',0
exit_button_display_txt:
  db 0				;no  text


;-----------------------------------------
;mouse event decode table

button_decode_table:

error_button:
 db 02 ;starting column
 db 09 ;ending column
 db 01 ;starting row
 db 01 ;ending row
 dd error_clicked

commandDone_button:
 db 17
 db 31
 db 01
 db 01
 dd commandDone_clicked

keyPress_button:
 db 34
 db 44
 db 01
 db 01
 dd keyPress_clicked

keyRelease_button:
 db 50
 db 62
 db 01
 db 01
 dd keyRelease_clicked

buttonPress_button:
 db 68
 db 80
 db 01
 db 01
 dd buttonPress_clicked

buttonRelease_button:
 db 02
 db 16
 db 03
 db 03
 dd buttonRelease_clicked

motionNotify_button:
 db 17
 db 31
 db 03
 db 03
 dd motionNotify_clicked

enterNotify_button:
 db 34
 db 43
 db 03
 db 03
 dd enterNotify_clicked

leaveNotify_button:
 db 50
 db 59
 db 03
 db 03
 dd leaveNotify_clicked

focusIn_button:
 db 68
 db 77
 db 03
 db 03
 dd focusIn_clicked

focusOut_button:
 db 02
 db 11
 db 05
 db 05
 dd focusOut_clicked

keymapNotify_button:
 db 17
 db 30
 db 05
 db 05
 dd keymapNotify_clicked

expose_button:
 db 34
 db 42
 db 05
 db 05
 dd expose_clicked

graphicsExpose_button:
 db 50
 db 64
 db 05
 db 05
 dd graphicsExpose_clicked

noExpose_button:
 db 68
 db 79
 db 05
 db 05
 dd noExpose_clicked

visibilityNotify_button:
 db 02
 db 15
 db 07
 db 07
 dd visibilityNotify_clicked

createNotify_button:
 db 17
 db 30
 db 07
 db 07
 dd createNotify_clicked

destroyNotify_button:
 db 34
 db 45
 db 07
 db 07
 dd destroyNotify_clicked

unmapNotify_button:
 db 50
 db 66
 db 07
 db 07
 dd unmapNotify_clicked

mapNotify_button:
 db 68
 db 75
 db 07
 db 07
 dd mapNotify_clicked

mapRequest_button:
 db 02
 db 11
 db 09
 db 09
 dd mapRequest_clicked

reparentNotify_button:
 db 17
 db 32
 db 09
 db 09
 dd reparentNotify_clicked

configureNotify_button:
 db 34
 db 45
 db 09
 db 09
 dd configureNotify_clicked

configureRequest_button:
 db 50
 db 65
 db 09
 db 09
 dd configureRequest_clicked

gravityNotify_button:
 db 68
 db 78
 db 09
 db 09
 dd gravityNotify_clicked

resizeRequest_button:
 db 02
 db 11
 db 11
 db 11
 dd resizeRequest_clicked

circulateNotify_button:
 db 17
 db 32
 db 11
 db 11
 dd circulateNotify_clicked

circulateRequest_button:
 db 34
 db 47
 db 11
 db 11
 dd circulateRequest_clicked

propertyNotify_button:
 db 50
 db 64
 db 11
 db 11
 dd propertyNotify_clicked

selectionClear_button:
 db 68
 db 78
 db 11
 db 11
 dd selectionClear_clicked

selectionRequest_button:
 db 02
 db 15
 db 13
 db 13
 dd selectionRequest_clicked

selectionNotify_button:
 db 17
 db 32
 db 13
 db 13
 dd selectionNotify_clicked

colormapNotify_button:
 db 34
 db 45
 db 13
 db 13
 dd colormapNotify_clicked

clientMessage_button:
 db 50
 db 64
 db 13
 db 13
 dd clientMessage_clicked

mappingNotify_button:
 db 68
 db 78
 db 13
 db 13
 dd mappingNotify_clicked

intro_button:
 db 17
 db 21
 db 15
 db 15
 dd intro_clicked

design_button:
 db 34
 db 39
 db 15
 db 15
 dd design_clicked

exit_button:
 db 50
 db 55
 db 15
 db 15
 dd exit_clicked

  [section .bss]

wc_block: resw 1	;x loc
	  resw 1	;y
	  resw 1	;width
	  resw 1	;height
