
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
  extern show_box
  extern crt_line
  extern lib_buf
  extern select_list_setup
  extern crt_rows,crt_columns
  extern cursor_hide
  extern cursor_unhide
  extern read_stdin
  extern kbuf
  extern crt_clear
  extern key_decode1

  [section .text]

%include "select_list_struc.inc"
;----------------------------------------------------------------------------------------
;>1 widget
; select_list_engine - display a list and wait for selection
;
;    usage: This function reqires some setup which can be  avoided
;           by calling the functions:
;
;           select_1up_list_full - 1 column of lists using full screen
;           select_2up_list_full - 2 columns of lists using full screen
;           select_1up_list_left - 1 column of lists using left half of screen
;           select_2up_list_left - 2 columns of lists using left half of screen
;           select_1up_list_right - 1 column of lists using right half of screen
;           select_2up_list_right - w columns of lists using right half of screen
;
;           The above functions use defaults for colors and other parameters.
;           If finer control is needed then the select_list_engine must be
;           used (setup is described in the following paragraphs).
;
;           WARNING: This function isn't difficult to setup, but it will
;                    crash if parameters are wrong or if input data can
;                    not be modified as needed.  It is recomended that
;                    this documentation be read carefully.
;
;    introduction:
;          The caller must set up a general table describing the
;          selection list window and also descriptions of the
;          individual buttons.  Defaults exist for many parameters
;          and other parameters may be calculated on the fly.
;          All this is described by the following tables.
;        
;   INPUTS
;   ------
;
;   ebp = ptr to the following struc
;
;struc sl
;.button_groups	resb	1	;number of groups (button columns) calculated from button defs
;.buttons_per_column resb 1	;number of buttons in each column, calculated from button defs.
;.win_columns	resb	1	;size of our select window (columns) 0=use default, see note 1
;                                window sizes are for contents, a one character frame is added.
;                                Default is full screen.  
;.win_rows	resb	1	;size of our select window (rows) 0=use default, see note 1
;                                Default size for win_rows is full screen.
;.win_left_column resb	1	;win location, left column, 1+,  see note 2, 0=use default
;                                Default for win_left_olullmn is 1, left column.
;.win_top_row	resb	1	;win location, top row, 1+, see note 2 , 0=use default
;                                Default for win_top_row is 1, top of screen.
;.box_color	resd	1	;color of box, -1=no box 0=default (see color format below)
;.win_color	resd	1	;color of select window, 0=default
;.button_size_columns resb 1	;all buttons are same length, calculated from button defs,
;                                the largest text string +2 is button length.
;.button_size_rows    resb 1	;all buttons are same size, calculated from button defs,
;                                the button with largest number of lines is size for all buttons.
;                                Lines end with 0ah and last line ends with a zero byte.
;.button_separation_columns   resb 1 ;number of rows between buttons, 0=default of 0
;.button_separation_rows   resb 1 ;number of rows between buttons, 0=default of 0
;endstruc
;
;  note 1: the window size includes a one character boarder or edge.  Useful area = size -2
;  note 2: the box location is given for data inside box, the boarder will expand box by 1
;
; button definitions follow next:
;  all buttons in a column (group) must be defined together.  If two columns
;  are used, the second column is defined after column 1, etc.
;
;struc button
;.button_group		resb 1	;1=button column #1
;.button_color		resd 1	;button unselected color, 0=use defaullt
;.button_selected_color  resd 1	;button selected color (if -1, can't select, 0=default)
;.button_text		resb 1  ;variable length text goes here, multi line text has 0ah
;   (text field ends with 0 and may be following by another button defination or another
;    zero.  When two zeros are together it indicates the end of button definitions)
;endstruc
;
;   note: colors are defined as hex values in a dword as follows:
;      color = aaxxffbb  (aa-attribute ff-foreground  bb-background)
;        30-black 31-red 32-green 33-brown 34-blue 35-purple 36-cyan 37-grey
;      attributes 30-normal 31-bold 34-underscore 37-inverse
;
;   note: headers and descriptive entries can be created by using buttons
;         that have same color as background and setting them no-select.
;
;   note: If multiple columns of buttons are defined, all columns must have
;         the same number of buttons.  Holes can be created by setting color
;         to non-button state and setting button non-selectable, but the area
;         must have a definition.
;
;   OUTPUT
;   ------
;
;    eax = return code
;
;          When selected, the buttons return a code
;          describing its position.
;          Positions are encoded in two bytes in eax
;          as ah=group number,  al=row number.  These
;          are not physical row and columns, they are
;          button positions.  the frist button is 1,1.
;          The button below it is 1,2.
;
;                1,1             2,1
;
;                1,2             2,2
;
;          If a error is found eax will contain -1.
;
;          ESC key press returns eax=0
;
;   The input struc's and button definitons may be modified and defaults
;   filled in.  If this input set is to be reused the values may need to
;   be refreshed or adjusted.  WARNING, the input data area must be
;   writable and not in a code segment.
;
;<
;-------------------------------------------------------------------------             
  global select_list_engine	
select_list_engine:
;  xor	eax,eax
;  mov	[topdisplay_button],al
;  mov	[topdisplay_button_state],al
;  mov	[topvirtualrow],al
;  mov	[edgevirtualcolumn],eax
;
; the setup function fills in all defaults, our job is to
; display the window, scroll around, and process inputs.
; First, we need to build some pointers.
;
  call	build_pointers		;ebp = ptr to input data
  mov	eax,[ptrs2button_defs]    ;select the top left
  cmp	byte [eax+button.button_selected_color],-1 ;is this button disabled?
  jne	sls_01			;jmp if top left button can be selected
  mov	eax,[ptrs2button_defs+4];select next button  
sls_01:
  mov	[selected_button_ptr],eax ;  button initially
  mov	al,2			;ask setup to fill in any defaults needed
  call	select_list_setup	;fill in defaults and values
  call	box_area		;input=ebp (ptr to input data)
  call	cursor_hide
main_loop:
  call	display_buttons		;
  call	read_stdin	;get key
  cmp	byte [kbuf],-1	;mouse?
  je	got_mouse
;a key was pressed
  call	decode_key
  jmp	gr_process
got_mouse:
  call	decode_mouse
gr_process:
  or	ebx,ebx
  jz	main_loop	;loop if no button pushed yet
menu_exit2:
  push	eax
  call	cursor_unhide
  mov	eax,30003734h
  call	crt_clear
  pop	eax
  ret
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
; input:  kbuf has mouse info
; output: ebx = 0 to continue, any other key is button code or error code
;             = eax & and al=group  al=button#
decode_mouse:
  mov	cl,[kbuf + 2]		;get cursor column
  mov	ch,[kbuf + 3]		;get cursor row
  mov	bh,[ebp+sl.win_rows]	;max number of rows to check
  mov	bl,[ebp+sl.win_top_row] ;starting row to check
;
; first line is possible separator line
;
  mov	ah,1			;starting with button #1
dm_loop1:
  add	bl,[ebp+sl.button_separation_rows]	;move past any separators
  cmp	bl,ch			;check against click row
  ja	dm_ignore		;exit if click above buttons or in separator row
  je	dm_got			;jmp if click row
  sub	bh,[ebp+sl.button_separation_rows]
  js	dm_ignore		;jmp if out of rows
  add	bl,[ebp+sl.button_size_rows]
  cmp	bl,ch
  jae	dm_got			;jmp if prevous row was click row
  sub	bh,[ebp+sl.button_size_rows]
  js	dm_ignore		;jmp if out of rows
  inc	ah			;bump buttton number	
  jmp	short dm_loop1
;
; ah=button# , check columns
; cl=click column
;
dm_got:
  mov	bl,[ebp+sl.win_left_column]	;get starting search point
  mov	al,1				;start with group 1
  mov	bh,[ebp+sl.win_columns]		;get final column to check
  add	bh,[ebp+sl.win_left_column]	;compute physical location
dm_loop2:
  add	bl,[ebp+sl.button_separation_columns]	;move to first button
  cmp	bl,cl				;check column
  ja	dm_ignore			;jmp if click infront of button
  je	dm_done
  cmp	bl,bh
  jae	dm_ignore			;jmp if at end of window
  add	bl,[ebp+sl.button_size_columns]
  cmp	bl,cl
  ja	dm_done				;jmp if button found
  inc	al				;bump group
  jmp	dm_loop2

;found click, al=group ah=button#
dm_done:
;check if this is a no-select button
  xor	ebx,ebx				;clear ebx
  mov	bl,al				;get group
  dec	ebx				;make zero based
  shl	ebx,2				;make dword index
  add	ebx,ptr2group_ptrs
  mov	ebx,[ebx]			;get ptr to this groups list
  xor	ecx,ecx
  mov	cl,ah				;get button#
  dec	ecx				;convert from 1 based to zero based
  shl	ecx,2				;make into dword index
  add	ebx,ecx				;index into list of defs for this group
  mov	ebx,[ebx]			;get def
  cmp	byte [ebx+button.button_selected_color],-1
  je	dm_ignore			;jmp if no select button
  xchg	ah,al
  mov	ebx,eax
  jmp	short dem_exit
dm_ignore:
  mov	ebx,0
dem_exit:
  ret
;-------------------------------------------------------------------------
; input:  kbuf has key info
; output: ebx = 0 to continue, any other key is button code or error code
decode_key:
  mov	esi,key_decode_table1
  call	key_decode1
  call	eax			;execute process
  ret
;-----------
alpha_key:
  xor	ebx,ebx			;ignore this key
  ret
;------------
exit_key:
  xor	eax,eax
  mov	ebx,-1
  ret
;------------
left_arrow:
  call	find_selected_button_def	;out-> ah=group al=button# ebx=button def
  cmp	ah,1
  je	la_exit				;exit if at left edge
  xor	ebx,ebx				;clear ebx
  mov	bl,ah				;get group
  sub	ebx,2				;move left one group
  shl	ebx,2				;make dword index
  add	ebx,ptr2group_ptrs
  mov	ebx,[ebx]			;get ptr to this groups list
  xor	ecx,ecx
  mov	cl,al				;get button#
  dec	ecx				;convert from 1 based to zero based
  shl	ecx,2				;make into dword index
  add	ebx,ecx				;index into list of defs for this group
  mov	eax,[ebx]			;get def
  cmp	byte [eax+button.button_selected_color],-1
  je	la_exit				;exit if no-select button at our left
  mov	[selected_button_ptr],eax
la_exit:
  xor	ebx,ebx
  ret
;------------
right_arrow:
  call	find_selected_button_def	;out ah=group al=button# ebx=button def
  cmp	ah,[ebp+sl.button_groups]	;are we at right edge?
  je	rak_exit			;exit if at right edge
;
; move right to button on same level
;
  xor	ebx,ebx
  mov	bl,ah				;get group
;;  inc	ebx				;move right one group, (1 based already inc'ed)
  shl	ebx,2				;make dword index
  add	ebx,ptr2group_ptrs
  mov	ebx,[ebx]			;get ptr to this groups list
  xor	ecx,ecx
  mov	cl,al				;get button#
  dec	ecx				;convert from 1 based to zero based
  shl	ecx,2				;make into dword index
  add	ebx,ecx				;index into list of defs for this group
  mov	eax,[ebx]			;get def
  cmp	byte [eax+button.button_selected_color],-1
  je	rak_exit				;exit if no-select button at our right
  mov	[selected_button_ptr],eax
rak_exit:
  xor	ebx,ebx
  ret

;------------
up_arrow:
  call	find_selected_button_def	;out ah=group al=button# ebx=button def
ua_retry:
  cmp	al,1				;at top already
  je	ua_exit
  xor	ecx,ecx
  mov	cl,ah				;get group
  dec	ecx				;convert to zero based
  shl	ecx,2				;make dword index
  add	ecx,ptr2group_ptrs
  mov	ecx,[ecx]			;get ptr to this groups list
;index into group
  xor	ebx,ebx
  mov	bl,al				;get button number
  sub	bl,2				;convert to zero based and dec by 1
  shl	ebx,2				;convert to dword index
  add	ebx,ecx				;index into list
  mov	ebx,[ebx]			;get ptr to def
  cmp	byte [ebx+button.button_selected_color],-1
  jne	ua_exit1			;jmp if button can be selected
; check if previous button can be selected
  dec	al
  jmp	ua_retry
ua_exit1:
  mov	[selected_button_ptr],ebx
ua_exit:
  xor	ebx,ebx
  ret

;------------
down_arrow:
  call	find_selected_button_def	;out ah=group al=button# ebx=button def
da_retry:
  xor	ecx,ecx
  mov	cl,ah				;get group
  dec	ecx				;convert to zero based
  shl	ecx,2				;make dword index
  add	ecx,ptr2group_ptrs
  mov	ecx,[ecx]			;get ptr to this groups list
;index into group
  xor	ebx,ebx
  mov	bl,al				;get button number
  shl	ebx,2				;convert to dword index
  add	ebx,ecx				;index into list
  mov	ebx,[ebx]			;get ptr to def, if zero then at end
  or	ebx,ebx
  jz	da_exit				;jmp if at end
  cmp	byte [ebx+button.button_selected_color],-1
  jne	da_exit1			;jmp if button can be selected
  inc	al
  cmp	[ebp+sl.buttons_per_column],al
  jb	da_exit				;exit if can't go down
  jmp	short da_retry
da_exit1:
  mov	[selected_button_ptr],ebx
da_exit:
  xor	ebx,ebx
  ret
;------------
enter_key:
  call	find_selected_button_def	;out ah=group al=button# ebx=button def
  xchg	al,al			;put group in -al- and button# in -ah-
  mov	ebx,eax
  ret  
;------------
unknown_key:
  xor	ebx,ebx			;ignore this key
  ret
;------------
key_decode_table1:
  dd	alpha_key

  db   1bh,0			;esc
  dd   exit_key

    db	1bh,5bh,44h,0		;left arrow
  dd	left_arrow		;left arrow process

    db	1bh,4fh,44h,0		;left arrow
  dd	left_arrow		;left arrow process

    db	1bh,4fh,74h,0		;left arrow
  dd	left_arrow		;left arrow process

    db 1bh,5bh,43h,0		;pad_right
  dd	right_arrow

    db 1bh,4fh,43h,0		;pad_right
  dd	right_arrow

    db 1bh,4fh,76h,0		;pad_right
  dd	right_arrow

    db 1bh,5bh,41h,0		;pad_up
  dd	up_arrow

    db 1bh,4fh,41h,0		;pad_up
  dd	up_arrow

    db 1bh,4fh,78h,0		;pad_up
  dd	up_arrow

    db 1bh,5bh,42h,0		;pad_down
  dd	down_arrow

    db 1bh,4fh,42h,0		;pad_down
  dd	down_arrow

    db 1bh,4fh,72h,0		;pad_down
  dd	down_arrow

    db 0dh,0			;enter key
  dd	enter_key

    db 0ah,0			;enter key
  dd	enter_key

  db   0
  dd   unknown_key

;-------------------------------------------------------------------------
; output:  ah = button group
;          al = button number
;         ebx = selected button def
;
find_selected_button_def:
  mov	ebx,ptrs2button_defs
  mov	ecx,[selected_button_ptr]	;ptr to selected def
  mov	ah,1			;group#
fsg_loop1:
  mov	al,1			;button#
fsg_loop2:
  cmp	[ebx],ecx
  je	fsg_found
  add	ebx,4			;move to next button
  inc	al
  cmp	dword [ebx],0		;end of this group
  jne	fsg_loop2
  add	ebx,4
  inc	ah			;move to next group
  jmp	short fsg_loop1
fsg_found:
  ret
  
;-------------------------------------------------------------------------
; input:  [ptr2group_ptrs] = ptr to beginning of each group (button column)
;         [ptrs2button_defs= = ptr to button ptrs, see button struc
;         [ebp+sl.button_size_columns]
;         [ebp+sl.button_size_rows]
;         [ebp+sl.button_separation_columns]
;         [ebp+sl.button_separation_rows]
;
display_buttons:
  mov	al,[ebp+sl.win_top_row]
  mov	[row_tracking],al		;init starting display point
  xor	eax,eax
  mov	byte [rows_displayed],al	;init progress count
  mov	[current_display_button],al
  mov	[current_display_state],al
  jmp	short db_check			;force at least one separation line at top
db_lp1:
  mov	al,[current_display_state]
  cmp	al,10h			;are we doing a separator bar?
  jae	db_do_button		;jmp if doing a button
;
; we are doing separation rows
;
  and	al,0fh			;isolate separation count
  cmp	al,[ebp+sl.button_separation_rows] ;is separation done?
  je	db_separation_done		   ;jmp if done
;
  inc	al
  mov	[current_display_state],al
  jb	db_check			;jmp if another  separation line
;
; all separation lines have been displayed
;
db_separation_done:
  mov	byte [current_display_state],10h	;move to button
  jmp	short db_check2		;go check if done
;
; we are displaying a button
;
db_do_button:
  call	display_button_line
  inc	byte [current_display_state]
  mov	al,[current_display_state]
  and	al,0fh			;isolate button line number
  cmp	al,[ebp+sl.button_size_rows]	;is this button done
  jb	db_check			;jmp if button not done
;
; this button is done
;
  mov	byte [current_display_state],0	;start with separator
  inc	byte [current_display_button]
  mov	al,[current_display_button]
  cmp	al,[ebp+sl.buttons_per_column]
  je	db_done				;jmp if all buttons displayed
;
; check if all lines displayed
;
db_check:
  inc	byte [row_tracking]
  inc	byte [rows_displayed]
db_check2:
  mov	al,[rows_displayed]
  cmp	al,[ebp+sl.win_rows]
  je	db_done
  jmp	db_lp1
db_done:
  ret
;-----------------
  [section .data]
row_tracking:	db	0	;current physical row number
rows_displayed: db	0	;total rows displayed so far

current_display_button	db	0	;button number being displayed 0=button1
current_display_state	db	0	;status of button being displayed

  [section .text]
;-------------------------------------------------------------------------
; display one line of button text
;  inputs: [current_display_button]
;          [current_display_state] - button line
;          [ebp+sl.button_separation_columns]
;          [ebp+sl.button_groups]		;numer of button columns
;          [ptr2group_ptrs]  - groups
;          [ptrs2button_defs]
;          [row_tracking] - row physical address
;          [ebp+sl.win_left_column]
;          [edgevirtual_column] - scroll
;
; build text line at lib_buf + 400
; build color list at lib_buf + 580
;
display_button_line:
  mov	byte [group_counter],0
  mov	edi,lib_buf+400		;setup build stuff ptr
  mov	edx,lib_buf+580		;setup color stuff ptr
  mov	eax,[ebp+sl.win_color]	;get separator color
  mov	[edx],eax		;color 1 is for separator
  add	edx,4
dbl_lp:
  call	stuff_separator		;insert separator and color 
;
; lookup current group text line
;
  xor	eax,eax
  mov	al,[group_counter]
  shl	eax,2			;make dword index
  add	eax,ptr2group_ptrs	;get current button
  mov	eax,[eax]		;get group list ptr 
  cmp	dword [eax],0
  jne	dbl_03
  jmp	db_show_it		;jmp if end of buttons
;
; index into group to find current button
;
dbl_03:
  xor	ebx,ebx
  mov	bl,[current_display_button]
  shl	ebx,2			;make dword index
  add	ebx,eax			;point at struc for button (ebx)
  mov	ebx,[ebx]		;get button struc ptr.
;
; stuff the color for this button
;
   mov	eax,[ebx+button.button_color]
   cmp	ebx,[selected_button_ptr]
   jne	dbl_05			;jmp if not selected
   mov	eax,[ebx+button.button_selected_color]
dbl_05:
   mov	[edx],eax
   add	edx,4
;
; stuff color number into line
;
   mov	eax,edx
   sub	eax,lib_buf+580
   shr	eax,2
   stosb				;store color number
;
; find text using the current_display_state
;
  lea	esi,[ebx+button.button_text]
  mov	ah,[current_display_state]
  and	ah,0fh				;isolate current button line#
  cmp	ah,0
  je	got_line			;jmp if esi points at line
;
; scan forward in line to 0ah
;
  mov	cl,1
db_scan:
  lodsb
  cmp	al,0ah
  je	db_scan_end
  or	al,al
  jne	db_scan
  dec	esi				;move back to  zero
  jmp	got_line			;use null line
db_scan_end:
  cmp	cl,ah				;are we at correct line
  je	got_line
  inc	cl
  jmp	db_scan
;
; esi points at text for button 
; move to buffer
;
got_line:
  mov	cl,[ebp+sl.button_size_columns]
gl_loop:
  lodsb
  or	al,al
  jz	db_pad				;jmp if at end of text
  cmp	al,0ah
  je	db_pad				;jmp if spaces needed to fill out button
  stosb
  dec	cl				;end of button area?
  jnz	gl_loop				;loop if room for more text
  jmp	short gl_done			;jmp if this button text moved
;
; pad rest of button area with spaces
;
db_pad:
  mov	al,' '
gl_lp2:
  stosb
  dec	cl
  jnz	gl_lp2
;
; this button had been stored, is their another group?
;
gl_done:
  inc	byte [group_counter]
  mov	al,[group_counter]
  cmp	al,[ebp+sl.button_groups]	;is this the last group
  jae	db_show_it			;jmp if all groups done
  jmp	dbl_lp				;go do another button
;
; the button line has been built at lib_buf+400
;
db_show_it:
  mov	al,1				;color code 1
  stosb
  mov	byte [edi],0			;put zero at end of line
  mov	ebx,lib_buf+580			;get color list
  mov	ch,[row_tracking]
  mov	cl,[ebp+sl.win_left_column]
  mov	dl,[ebp+sl.win_columns]
  mov	esi,lib_buf+400
  xor	edi,edi				;set scroll to 0
  call	crt_line
  ret
;------------------
  [section .data]
group_counter   db	0
  [section .text]
;--------------------------------------
stuff_separator:
  mov	al,1
  stosb
  mov	al,' '
  mov	ah,[ebp+sl.button_separation_columns]
ss_lp:
  stosb
  dec	ah
  jnz	ss_lp			;loop till done
  ret
;-------------------------------------------------------------------------
box_area:
  mov	eax,[ebp+sl.win_color]
  mov	[bwc],eax

  mov	al,[ebp+sl.win_columns]
  mov	[bdc],al			;columns inside box, not frame

  mov	al,[ebp+sl.win_rows]
  mov	[bdr],al			;rows inside box, not frame

  mov	al,[ebp+sl.win_left_column]
  mov	[bsc],al			;window left column, not frame

  mov	al,[ebp+sl.win_top_row]
  mov	[bsr_],al			;window top, not frame top

  mov	eax,[ebp+sl.box_color]
  mov	[bcc],eax  

  mov	esi,box_def
  call	show_box
  ret
;------------------
  [section .data]
box_def:
bwc: dd 0		;window color
     dd	box_data
     dd	box_data_end
     dd	0		;scroll
bdc: db	0		;columns inside box
bdr: db 0		;rows inside box
bsr_: db 0		;box starting row for data inside box
bsc: db 0		;box starting column for data inside box
bcc: dd 0		;box outline color
;
box_data:     db	' '
box_data_end: db	0
  [section .text]
;-------------------------------------------------------------------------
; input: ebp = ptr to callers structures
; output: [ptr2group_ptrs]
;         [ptrs2button_defs] 
build_pointers:
  lea	esi,[ebp+sl.button_separation_rows+1]   ;point at first button definition
  mov	ecx,ptr2group_ptrs			;stuff point for group ptrs
  mov	edi,ptrs2button_defs			;stuff point for buttons
bp_lp1:
  mov	[ecx],edi				;store ptr to list
  add	ecx,4					;move to next store point
  mov	dword [ecx],0				;clear next store point incase it has data
  mov	ah,[esi+button.button_group]		;get this button group number
bp_lp2:
  mov	[edi],esi				;save ptr to button
  add	edi,4
  call	next_button
  or	esi,esi
  jz	bp_done					;jmp if done
  cmp	ah,[esi+button.button_group]  		;is this the next group
  je	bp_lp2					;jmp if another button in same group
;we have found another group
  mov	dword [edi],0
  add	edi,4					;terminate button list
  jmp	bp_lp1  
bp_done:
  mov	dword [edi],0				;terminate last button list
  ret
;-----------------------------------
; input: esi= ptr to top of current button
; output: esi = ptr to next button or zero if end of buttons
;
next_button:
  lea	esi,[esi+button.button_text]		;point at text field
nb_lp:
  lodsb
  or	al,al
  jnz	nb_lp					;loop till end of text
  cmp	byte [esi],0				;end of buttons?
  jne	nb_exit
  xor	esi,esi					;set end of buttons indicator
nb_exit:
  ret
;-------------------------------------------------------------------------
  [section .data]

;topdisplay_button	db	0	;number of button at top of display 0=first
;topdisplay_button_state db	0	;pointer to button row as follows:
;                                       0=separator line1
;                                       1=separator line2
;                                       etc.
;                                       10h = button text line 1
;                                       11h = button text line 2
;                                       etc.
;topvirtualrow		dd	0	;scroll up/down
;edgevirtualcolumn	dd	0	;scroll left

selected_button_ptr	dd	0	;ptr to current button selected

ptr2group_ptrs:
  times 6 dd 0		;max number of button columns are 5, zero at end of list

ptrs2button_defs:
  times 60 dd 0		;max number of 50 buttons, each group has zero at end

  [section .text]

