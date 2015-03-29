
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
  extern file_simple_read
  extern message_box
  extern key_mouse1
  extern blk_find
  extern crt_open,crt_close
  extern mouse_enable
  extern ascii_to_dword
  extern crt_rows,crt_columns
  extern make_box
  extern crt_set_color
  extern crt_win_from_ptrs
  extern move_cursor
  extern crt_str
  extern kbuf
  extern key_decode1
  extern crt_clear
  extern reset_clear_terminal

 [section .text]
;--------------------------------------------------------------
;>1
; Asmmenu - display menu for shell script
;
;
;    usage: from within script (menu definition at end of script)
;           execute:  asmmenu $0   <-- this gives AsmMenu the
;                                      script file location.
;
;    introduction:
;          AsmMenu is a very easy to use menu system for shell
;          scripts.  The caller only needs to identify the button
;          size and then make a text map of the buttons in the
;          pattern they are to be displayed.  Reviewing the
;          example below should explain the setup needed.
;        
;    operation:
;    ----------
;          Asmmenu extracts a menu definition from the executing
;          shell script.  Only one menu definition can be placed
;          in the shell script and it must be at the end and built
;          as described below.  AsmMenu reads the shell script and
;          displays the menu it finds.  When a button is pushed the
;          code for that button is returned to the calling shell
;          script and AsmMenu exits.
;
;          This design works because shell scripts can be told to
;          exit and ignore any data that follows.  We can then
;          use the end of the script file to define our menu.
;
;    inputs
;    ------
;          AsmMenu finds the calling shell script and
;          scans to the end looking for a menu definition.
;          Each menu definition begins with:  buttonsize: x,y
;          Next, it expects to find box titles identified
;          as:      header: "text goes here"
;          Multiple headers are possible.  The rest of a menu
;          definition is a visual button layout separated by
;          tabs.
;
;          Example of a menu definition:
;
;          #set button size to 2 rows long and 15 columns wide
;          buttonsize: 2,15
;          header: "this is a sample header"
;
;          <tab> hello I'm <tab> i'm a 
;          <tab> button 1  <tab> button
;
;          <tab> row2      <tab> yet another
;          <tab> button    <tab> button
;
;          summary of menu options:
;            buttonsize: x,y   <-- size for all buttons
;            header: " "       <-- header.  max number headers = 8
;                                  each header starts with: header:
;            color1:           <-- alternate color set #1
;                                  Can be before or after header: defs
;            clear:            <-- clear display after selection
;                                  Place after buttonsize: and before
;                                  first tab
;
;   output
;   ------
;          When selected, the buttons return a code
;          indicating its position.  All first
;          row buttons start with "1".  Second tier
;          buttons start with "2", etc.  Next, the
;          button column is included within the code.
;          Thus, 12 indicates row 1 column 2.  Thus,
;          the above example returns codes showing
;          button positon as follows:
;
;                11             12
;
;                21             22
;
;          If AsmMenu encounters an error it will
;          return -1.  It will also display a message.
;
;   limitations
;   -----------
;          The maximum number of text rows in a single button
;          is 4.  The maximum number of columns in a single
;          button is 200 or the screen size.  The maximum
;          number of buttons is 49.  The maximum number or
;          buttons on a line is 9.  The maximum number of
;          button rows is 9.
;
;          AsmMenu only runs on the Linux console or in
;          a terminal and only on X86 processors.  It can
;          be used within X-windows by utilizing a terminal
;          program such as xterm,rxvt, or konsole.
;          For most terminals the following will work:
;
;              xterm -e script
;
;   example shell script
;   --------------------
;          #Shell script to call asmmenu and capture
;          #the return code
;
;          asmmenu $0
;          if [ $? = 11 ]; then
;          echo "button row 1 column 1"
;          else
;          echo "some other button"
;          fi
;          exit
;          #------------------------------------
;          #single button menu
;          buttonsize: 1,4
;          header: "the menu"
;          <tab> test
;          
;<
;-------------------------------------------------------------------------             
 global main,_start

main:
_start:
  nop
  call	crt_open
  call	mouse_enable
  call	parse
  js	menu_exit2	;exit if error (code in ebx)
;scan for menu definition
  mov	ebp,[file_end_ptr]
  mov	esi,buttonsize_txt
  mov	edi,buf		;search start loc
  mov	edx,1		;forward search
  mov	ch,0ffh		;ignore case
  call	blk_find	;if found ebx = ptr to match
  jnc	found_menu
  call	menu_err
  jmp	menu_exit2	;exit if error
;ebx points at buttonsize: and top of menu
found_menu:
  call	parse_menu_def
  js	menu_exit2	;exit if error
  call	compute_window_dimensions
  call	set_selected_button
  call	color_setup
main_loop:
  call	display_menu
  call	get_response
  or	ebx,ebx
  jz	main_loop	;loop if no button pushed yet
menu_exit2:
  push	ebx
  call	cursor_unhide
  call	crt_close
  mov	eax,[exit_color]
  call	crt_set_color
  mov	ecx,exit_msg
  call	crt_str
  cmp	byte [clear_flag],0
  je	menu_e2		;jmp if no clear
;  call	clear_screen
  call	reset_clear_terminal
menu_e2:
  pop	ebx
  mov	eax,1
  int	byte 80h		;exit

exit_msg: db 0ah,0
;-------------------------------------------------------------------------
clear_screen:
  mov	eax,[exit_color]
  call	crt_clear
  ret

;---------------
  [section .data]
clear_flag	db	0
exit_color	dd	30003730h
  [section .text]
;-------------------------------------------------------------------------
; input: eax = ptr to button definition
; output: je (null button)  jne (valid button) 
null_button_check:
  push	esi
  push	edi
  lea	esi,[eax+button_struc.btn_text_ptr_row1]
nbc_10:
  mov	edi,[esi]		;get ptr to text
  or	edi,edi			;end of pointers
  jz	nbc_exit		;jmp if end of pointers, null button
  cmp	byte [edi],0		;null first line of button?
  jnz	nbc_exit		;jmp if valid button found
  add	esi,4			;move to next pointer
  jmp	short nbc_10
nbc_exit:
  pop	edi
  pop	esi
  ret
  
;-------------------------------------------------------------------------
; input:  kbuf has mouse info
; output: ebx = 0 to continue, any other key is button code or error code
decode_mouse:
  mov	cl,[kbuf + 2]		;get cursor column
  mov	ch,[kbuf + 3]		;get cursor row
  mov	ebp,button_defs
dem_lp:
  cmp	byte [ebp],0		;end of def's
  je	dem_fail		;exit if end of def's
  cmp	ch,[ebp+button_struc.starting_row]
  jb	dem_fail		;exit if illegal row
  cmp	ch,[ebp+button_struc.ending_row]
  ja	dem_next		;go try another def
;we have found a valid row, check column
  cmp	cl,[ebp+button_struc.starting_col]
  jb	dem_next		;not this button
  cmp	cl,[ebp+button_struc.ending_col]
  jbe	dem_hit
dem_next:
  add	ebp,button_struc_size
  jmp	dem_lp
dem_hit:
  mov	eax,ebp
  call	null_button_check
  je	dem_fail		;ignore null buttons
  xor	ebx,ebx
  mov	bl,[ebp+button_struc.return_code]
  jmp	dem_exit
dem_fail:
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
  mov	ebx,-1
  ret
;------------
left_arrow:
  mov	eax,[selected_button_ptr]
la_10:
  cmp	eax,button_defs		;at top left?
  je	la_exit			;ignore this key if at top left
  sub	eax,button_struc_size
  call	null_button_check
  jne	la_50			;jmp if not null button
  jmp	short la_10		;try to skip over null button
la_50:
  mov	[selected_button_ptr],eax
la_exit:
  xor	ebx,ebx
  ret
;------------
right_arrow:
  mov	eax,[selected_button_ptr]
ra_10:
  cmp	byte [eax+button_struc_size],0	;is another button available
  je	rak_exit			;exit if no more buttons
  add	eax,button_struc_size
  call	null_button_check
  jne	rak_50			;jmp if not null button
  jmp	short ra_10		;try to skip over null button
rak_50:
  mov	[selected_button_ptr],eax
rak_exit:
  xor	ebx,ebx
  ret
;------------
up_arrow:
  mov	eax,[selected_button_ptr]
  mov	bl,[eax+button_struc.return_code] ;get return code
  cmp	bl,20
  jb	ua_exit		;exit if can not go up
ua_10:
  sub	bl,10		;compute new code
ua_loop:
  cmp	eax,button_defs
  je	ua_exit		;exit if can't go up
  sub	eax,button_struc_size
  mov	cl,[eax+button_struc.return_code]
  cmp	bl,cl
  je	ua_found_one		;loop till upper button found
  jb	ua_loop
  jmp	short ua_10		;jmp if null button missing, keep looking
ua_found_one:
  call	null_button_check
  je	ua_10		;jmp if null button here
ua_50:
  mov	[selected_button_ptr],eax
ua_exit:
  xor	ebx,ebx
  ret

;------------
down_arrow:
  mov	eax,[selected_button_ptr]
  mov	bl,[eax+button_struc.return_code]
da_10:
  add	bl,10		;compute next row code
da_lp:
  cmp	byte [eax],0
  je	da_exit			;exit if at end
  add	eax,button_struc_size	;move to next button
  mov	cl,[eax+button_struc.return_code]
  cmp	bl,cl
  je	da_40			;jmp if found
  ja	da_lp			;loop if still looking
  jmp	short da_10		;if nulll button missing,keep looking
da_40:
  call	null_button_check
  je	da_10		;jmp if null button
da_80:
  mov	[selected_button_ptr],eax
da_exit:
  xor	ebx,ebx
  ret
;------------
enter_key:
  mov	eax,[selected_button_ptr]
  xor	ebx,ebx
  mov	bl,[eax+button_struc.return_code]
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
    db 1bh,4fh,4dh,0
  dd	enter_key

  db   0
  dd   unknown_key

;-------------------------------------------------------------------------
;get_response - get key or mouse
;  inputs: selected_button_ptr
;  output: ebx = 0 to continue, else button code
;
get_response:
  call	key_mouse1	;get key
  cmp	byte [kbuf],-1	;mouse?
  je	got_mouse
;a key was pressed
  call	decode_key
  jmp	gr_exit
got_mouse:
  call	decode_mouse
gr_exit:
  ret

;-------------------------------------------------------------------------
; inputs:
;          button_defs -- button_struc -- button_sruc_size
;          [window_rows], [window_columns]  [box_top_row], [box_left_col]
;
display_menu:
  mov	al,[window_columns]
  mov	[cib],al
  mov	al,[window_rows]
  mov	[rib],al
  mov	al,[box_top_row]
  mov	[sr],al
  mov	al,[box_left_col]
  mov	[sc],al
  mov	esi,box_parameters
  call	make_box
;put headers into box, and set box color
  mov	eax,[menu_color]
  call	crt_set_color
  mov	ebx,menu_color	;not used
  mov	ch,[box_top_row]
  mov	cl,[box_left_col]
  mov	dl,[window_columns]
  mov	dh,[window_rows]
  mov	ebp,header_pointers
  mov	edi,0			;no adjustments
  call	crt_win_from_ptrs  
;put buttons in box
  mov	eax,button_defs
dm_lp1:
  cmp	byte [eax],0		;end of defs
  je	dm_50
  push	eax
  cmp	eax,[selected_button_ptr]
  jne	dm_20
  mov	eax,[selected_button_color]
  call	crt_set_color
  jmp	short dm_40
dm_20:
  mov	eax,[button_color]
  call	crt_set_color
dm_40:
  pop	eax
  mov	ch,[eax+button_struc.starting_row]
  mov	cl,[eax+button_struc.starting_col]
  mov	dl,[eax+button_struc.number_of_cols]
  mov	dh,[eax+button_struc.number_of_rows]
  lea	ebp,[eax+button_struc.btn_text_ptr_row1]
  mov	edi,0			;no adjustments
  push	eax
;check if this is a null button, and skip display if it is
  mov	eax,ebp
dm_42:
  mov	esi,[eax]		;
  or	esi,esi
  jz	dm_48			;jmp if end of pointers
  cmp	byte [esi],0		;null first line of button?
  jnz	dm_46			;jmp if valid button found
  add	eax,4			;move to next pointer
  jmp	short dm_42
dm_46:
  call	crt_win_from_ptrs
dm_48:
  pop	eax
  add	eax,button_struc_size
  jmp	dm_lp1			;go do next button  
;hide the cursor
dm_50:
  call	hide_cursor
dm_exit:     
  ret

;---------------
  [section .data]
selected_button_ptr	dd	button_defs

;    aaxxffbb      aa-attr ff-foreground  bb-background
;    30-blk 31-red 32-grn 33-brwn 34-blu 35-purple 36-cyan 37-gry
;    attributes 30-normal 31-bold 34-underscore 37-inverse

menu_color:		dd	30003036h
button_color:		dd	30003734h
selected_button_color	dd	31003334h

box_parameters:
cib  db	0		;columns inside box
rib  db	0		;rows inside box
sr   db	0		;starting row
sc   db	0		;starting col
obc  dd	30003737h	;outline box color
  
  [section .text]
;-------------------------------------------------------------------------
; hide_cursor
;
hide_cursor:
  mov	ecx,hide_string
  call	crt_str
;  mov	ah,[crt_rows]
;  mov	al,[crt_columns]
;  inc	al
;  call	move_cursor
  ret

hide_string:  db 1bh,'[?25l',0
;-------------------------------------------------------------------------
cursor_unhide:
  mov	ecx,unhide_string
  call	crt_str
  ret

unhide_string db 1bh,'[?25h',0
;-------------------------------------------------------------------------
; inputs:
;  [color_flag]
; output:
;   [menu_color]		dd	30003036h
;   [button_color]		dd	30003734h
;   [selected_button_color]	dd	31003334h
;   [obc]			dd	30003737h	;outline box color

color_setup:
  cmp	byte [color_flag],0
  je	cs_exit

  mov	eax,[alt_mc]
  mov	ebx,[alt_bc]
  mov	ecx,[alt_sbc]
  mov	edx,[alt_obc]

  mov	[menu_color],eax
  mov	[button_color],ebx
  mov	[selected_button_color],ecx
  mov	[obc],edx
cs_exit:
  ret
;---------------
  [section .data]
color_flag	db	0

alt_mc	dd	30003730h
alt_bc	dd	30003037h
alt_sbc dd	30003437h
alt_obc	dd	30003037h

  [section .text]
;-------------------------------------------------------------------------
set_selected_button:
  mov	eax,button_defs
ssb_lp:
  cmp	byte [eax],0
  je	ssb_exit		;exit if null structure
  call	null_button_check
  jne	ssb_exit		;jmp if button ok
  add	eax,button_struc_size
  jmp	short ssb_lp
ssb_exit:
  mov	[selected_button_ptr],eax
  ret
;-------------------------------------------------------------------------
; compute window dimensons and adjust all button locations to fit window
;  input:  [crt_rows]
;          [crt_columns]
;          button_defs -- button_struc -- button_sruc_size
; output: box_row, box_col, rows_in_box, cols_in_box
;
compute_window_dimensions:
  cmp	byte [button_defs],0		;any defs avail?
  jne	cwd_05				;jmp if def found
  jmp	cwd_exit
cwd_05:
  mov	edi,button_defs-button_struc_size
;first find window length and width, width = last ending column +2
;lenght(rows) = last .ending_row + 1
  mov	ch,0				;prime max ending column
cwd_lp1:
  add	edi,button_struc_size		;move to next definition 
  mov	cl,[edi+button_struc.ending_col]
  cmp	cl,ch
  jb	cwd_06				;jmp if new value less than refeence
  mov	ch,cl
cwd_06:
  cmp	byte [edi+button_struc_size],0	;last button def?
  jne	cwd_lp1				;loop till last button def found
;find last row for window
  mov	al,[edi+button_struc.ending_row] ;get last row of buttons
  inc	al				;add blank line at end
  mov	[window_rows],al
;cl has last column for window
  add	ch,1				;add blank columns at end
  mov	[window_columns],ch
;compute display row for box
  mov	al,[crt_rows]			;get rows in current display
  sub	al,[window_rows]
  shr	al,1
  cmp	al,0
  ja	cwd_10				;jmp if row ok
  mov	al,1				;force row 1
cwd_10:
  mov	[box_top_row],al
;compute dislay column for box
  mov	al,[crt_columns]
  sub	al,[window_columns]
  shr	al,1
  cmp	al,0
  ja	cwd_20				;jmp if column ok
  mov	al,1
cwd_20:
  mov	[box_left_col],al
;adjust all window_def rows/columns to fit into our window
  mov	ah,[box_top_row]		;row adjust value
  mov	al,[box_left_col]		;column adjust value
  mov	edi,button_defs
cwd_lp2:
  add	[edi+button_struc.starting_row],ah
  add	[edi+button_struc.ending_row],ah
  add	[edi+button_struc.starting_col],al
  add	[edi+button_struc.ending_col],al
  add	edi,button_struc_size		;move to next definition 
  cmp	byte [edi],0			;end of defs
  jne	cwd_lp2				;loop till done
cwd_exit:
  ret
;-----------------
  [section .data]
window_rows:	db	0	;total rows in window
window_columns:	db	0	;total columns in window

box_top_row	db	0	;display row, center of screen
box_left_col	db	0	;display col, center of screen

  [section .text]
;-------------------------------------------------------------------------
; input: ebx = ptr to string "buttonsize:"
; output: ebx = -1 if error, js,jns set
parse_menu_def:
  mov	esi,ebx		;save ptr to defs
;clear button def area
  mov	edi,button_defs
  mov	ecx,1000
  mov	al,0
  repnz	stosb
;scan for number of rows in button
pmd_lp1:
  lodsb
  cmp	al,':'
  jne	pmd_lp1
pmd_lp2:
  lodsb
  cmp	al,' '
  je	pmd_lp2		;skip over any spaces
;assme we have found a number in range 0-4
  and	al,07h		;isolate binary
  mov	[button_row_size],al
;look for columns in button
pmd_lp3:
  lodsb
  cmp	al,','
  je	pmd_lp3
  cmp	al,' '
  je	pmd_lp3
;assume we have found columns in button
  push	esi		;save position
pmd_lp4:
  lodsb
  cmp	al,0ah
  je	pmd_10		;jmp if end of string
  cmp	al,' '
  jne	pmd_lp4
pmd_10:
  dec	esi
  mov	byte [esi],0
  pop	esi		;restore ptr to start of string
  push	esi
  dec	esi
  call	ascii_to_dword	;return bin value in ecx
  mov	byte [button_column_size],cl
  pop	esi		;restore ptr to start of string
;look for header or color lines
pmd_lp5:
  cmp	dword [esi],'head'
  je	pmd_20		;jmp if header found
  cmp	dword [esi],'colo'
  je	pmd_15		;jmp if possible color
  cmp	dword [esi],'clea'
  je	pmd_13		;jmp if possible clear
  lodsb
  cmp	al,9		;check for tab
  je	pmd_30		;jmp if start of button def found
  jmp	short pmd_lp5
;we have found 'clea' assume it is clear
pmd_13:
  add	esi,6
  mov	byte [clear_flag],1
  jmp	short pmd_lp5
;we have found 'colo' check if "color:"
pmd_15:
  add	esi,5
  lodsb			;get color code
  mov	byte [color_flag],al
  jmp	short pmd_lp5
;we have found 'head' and assume it is header def
pmd_20:
  add	esi,4
  cmp	word [esi],'er'
  jne	pmd_lp5		;jmp if not header
  add	esi,2
  lodsb
  cmp	al,':'
  jne	pmd_lp5		;jmp if not header
;we have now found 'header:' , look for quotes
pmd_lp6:
  lodsb
  cmp	al,0ah		;end of line?
  je	pmd_lp5		;abort out if no quote found
  cmp	al,'"'
  jne	pmd_lp6
;we have found the quote in front header text
  mov	eax,[header_stuff_ptr]
  mov	[eax],esi	;save pointer to header text
  add	eax,4
  mov	[header_stuff_ptr],eax
;scan to end of header text
pmd_lp7:
  lodsb
  cmp	al,0ah
  je	pmd_24		;jmp if end of header
  cmp	al,'"'
  jne	pmd_lp7		;loop till end of header
pmd_24:
  mov	byte [esi -1],0	;terminate header line
  jmp	pmd_lp5		;go back and look for another header
;we have found our first tab, this must be a button def
pmd_30:
  mov	ebp,button_defs			;get button def storage
;compute next available row
  mov	eax,[header_stuff_ptr]
;  sub	eax,(header_pointers -4)
  sub	eax,(header_pointers)
  shr	eax,2				;convert to index
  or	eax,eax
  jnz	pmd_30a				;jmp if headers found
  inc	eax				;force a blank line at start
pmd_30a:
  mov	[next_available_row],al
;-----
; esi = parse ptr
; ebp = structure stuff ptr 
;fill in a new structure for next button
;-----
pmd_31:
;save row information
  mov	cl,[button_row_size]
  mov	byte [ebp + button_struc.number_of_rows],cl

  mov	al,[next_available_row]
  mov	byte [ebp + button_struc.starting_row],al

  add	al,cl				;compute ending row for button
  mov	[ebp + button_struc.ending_row],al
  
;save column information
  mov	al,[column_index]
  dec	al
  mov	bl,[button_column_size]
  add	bl,2				;number of spaces between buttons
  mul	bl
  inc	al				;convert column 0 -> 1
  mov	byte [ebp + button_struc.starting_col],al

  mov	bl,[button_column_size]
  mov	byte [ebp + button_struc.number_of_cols],bl

  add	al,bl					;compute ending column
  mov	byte [ebp + button_struc.ending_col],al

;save return code  
  mov	al,[base_rtn_code]
  add	al,[column_index]		;make return code
  mov	[ebp + button_struc.return_code],al
;setup text pointers
  lea	edx,[ebp + button_struc.btn_text_ptr_row1]
  mov   [edx],esi			;store pointer to text on line one of button
  xor	eax,eax
  add	edx,4
  mov	[edx],eax
  add	edx,4
  mov	[edx],eax
  add	edx,4
  mov	[edx],eax
  add	edx,4
  mov	[edx],eax
;terminate text string for initial line of this button
pmd_lp8:
  cmp	esi,[file_end_ptr]
  jae	pmd_exitj		;
  lodsb
  cmp	al,0ah		;end of line?
  je	pmd_50		;jmp if end of line
  cmp	al,09h		;end of text?
  jne	pmd_lp8		;jmp if not end of text
pmd_32:
  mov	byte [esi -1],0	;terminate this line of button text
;we have found a tab saying another button follows or possibly a end of line
pmd_33:
  lodsb
  cmp	al,0ah
  je	pmd_50
  dec	esi
;we are at start of another button, setup to define it
  add	ebp,button_struc_size		;move to next button definition
  inc	byte [column_index]		;move to next column
  jmp	pmd_31

;we have found the end of line, check if more text exists for these buttons
; [esi-1]  points at 0ah, if next char. is 0ah we are at end of this button row
pmd_50:
  lodsb			;get next menu def char
  cmp	al,0ah
  je	pmd_60		;jmp if this button row done
  cmp	al,9		;is this a tab, more button lines follow
  je	pmd_52		;jmp if tab
pmd_exitj:
  jmp	pmd_exit	;abort out if expected tab not found	
;add text lines to exiting button definitions
;first move back to beginning of this row
;ebp points at current definition
pmd_52:
  mov	al,[base_rtn_code]	;get return code base 10,20,30, etc.
  inc	al			;make into first return code
pmd_53:
  cmp	al,[ebp+button_struc.return_code]	;at first button on row?
  je	pmd_54			;jmp if at first button for this row
  sub	ebp,button_struc_size	;move back one button definition
  jmp	short pmd_53
;ebp now points at definition for first button on this row
;we are on line 2 or 3 or 4 of button definition
;find storage location for button text
pmd_54:
  lea	ebx,[ebp+button_struc.btn_text_ptr_row1]
pmd_55:
  add	ebx,4			;move to next pointer
  cmp	dword [ebx],0
  jne	pmd_55			;loop till next available ptr
  mov	[ebx],esi		;point at this text string
pmd_55a:
  cmp	byte [esi],9		;tab? could be a null button
  je	pmd_56			;jmp if end of this button
;find end of string
  inc	esi
  cmp	byte [esi],0ah		;eol?
  je	pmd_58
  cmp	esi,[file_end_ptr]
  jne	pmd_55a			;loop till end of string
  mov	byte [esi],0		;termnate this string
  jmp	short pmd_exit		;jmp if end of file
;we found end of this button, terminate string, button ended with tab
pmd_56:
  mov	byte [esi],0
  add	ebp,button_struc_size	;move to next button
  inc	esi			;move past terminating zero
  jmp	pmd_54  
;we found end of this line of buttons, it ended with 0ah, more button lines?
pmd_58:
  mov	byte [esi],0		;terminate this line
  inc	esi
  lodsb				;get next char
  cmp	esi,[file_end_ptr]
  je	pmd_exit		;exit if done
  cmp	al,0ah
  je	pmd_60			;jmp if possibly another button row	
  cmp	al,9			;new button row?
  je	pmd_52			;loop back and do another row on current button
;look for another row of buttons and setup structures if found
pmd_60:
  lodsb
  cmp	esi,[file_end_ptr]
  jae	pmd_exit	;jmp if end of menu found
  cmp	al,09h		;tab?
  jne	pmd_60		;jmp if not button id
;another button row was found, esi points past tab
;setup to define another row of buttons
  mov	al,[next_available_row]		;get top of previous button
  add	al,[button_row_size]		;add button size (rows)
  inc	al				;add spacer row between buttons
  mov	[next_available_row],al

  add	ebp,button_struc_size
  add	byte [base_rtn_code],10
  mov	byte [column_index],1
  jmp	pmd_31		;go define the next row

pmd_exit:
  or	ebx,ebx
  ret
;---------------
  [section .data]
header_stuff_ptr	dd	header_pointers

next_available_row	db	1	;
column_index		db	1	;1,2,3,4, etc.
base_rtn_code		db	10	;row 1 base code=10  row2=20 row3=30

;size of one button
button_row_size:	db	0
button_column_size	db	0
;ptrs to headers (optional)
header_pointers:
  dd	0,0,0,0,0,0,0,0,0,0,0,0		;space for 11 header lines

;this structure matches calling sequence for crt_win_from_ptrs
struc button_struc
.starting_row	resb	1	;ch
.starting_col	resb	1	;cl
.number_of_rows resb	1	;dh
.number_of_cols	resb	1	;dl
.ending_row	resb	1
.ending_col	resb	1
.return_code	resb	1
.btn_text_ptr_row1	resd	1
.btn_text_ptr_row2	resd	1
.btn_text_ptr_row3	resd	1
.btn_text_ptr_row4	resd	1
.zero_at_end_ptrs	resd	1
endstruc
; button_struc_size

;-------------------------------------------------------------------------
parse:
  mov	esi,esp			;get stack pointer
  lodsd				;get return address
  lodsd				;get parameter count
  cmp	eax,2
  jne	parse_error		;jmp if error
  lodsd				;get our name
  lodsd				;get parameter
;try to open file
  mov	ebx,eax			;set ebx=ptr to file path
  mov	edx,max
  mov	ecx,buf
  call	file_simple_read
  js	parse_error		;jmp if file read error
  add	eax,buf
  mov	[file_end_ptr],eax
  jmp	parse_exit
parse_error:
  mov	esi,message_block
  call	message_box
  mov	ebx,-1
  jmp	parse_exit2
parse_exit:
  xor	ebx,ebx
parse_exit2:
  or	ebx,ebx
  ret

;-------------------------------------
menu_err:
  mov	dword [m1],msg2
  mov	dword [m2],msg2_end
  call	parse_error
  ret

;-------------------------------------
  [section .data]

buttonsize_txt:
  db 'buttonsize:',0

message_block:
    dd	30003034h	;color for text
m1  dd	message		;data to display
m2  dd	message_end
    dd	0		;scroll
    db	30		;columns
    db	6		;rows
    db	5		;column for upper left corner
    db	5		;row for upper left corner
    dd	30003730h	;box outline color
message: db 'AsmMenu parameter',0ah
	 db 'incorrect',0ah,0ah
	 db 'press <enter>'
message_end:	db	0

msg2:    db "AsmMenu can't",0ah
         db 'find menu def',0ah
         db 0ah
         db 'press <enter>'
msg2_end db 0

;-------------------------------------
  [section .bss]
file_end_ptr	resd	1
button_defs	resb	1000
max equ 20000
buf	resb max
