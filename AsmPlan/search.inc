
;
;******* search.asm *************************************
;
search:
s_loop1:
  mov	eax,[todo_data_color]  
  call	crt_clear

  mov	eax,[todo_data_color]
  mov	bl,1				;column
  mov	bh,[crt_rows]
  sub	bh,12				;row
  mov	ecx,enter_string_msg1
  call	crt_color_at

; get prompted string or mouse event
;  input:  ebp -> prompt message ptr       +0 (dword)
;                 prompt message color ptr +4 (dword)
;                 data buffer ptr          +8 (dword)   has zero or preload
;                 max string length       +12 (dword)
;                 color ptr               +16 (dword)
;                 display row             +20 (db)       prompt row
;                 display column          +21 (db)
;                 allow 0d/0a in str      +22 (db)	;0=no 1=yes
  mov	al,[crt_rows]
  sub	al,10
  mov	[search_row],al			;row for string entry
  add	al,10
  mov	[menu_table +1],al		;row for buttons
  mov	byte [search_column],1
  mov	ebp,search_tbl
  call	get_prompted_string
  cmp	al,0
  jne	s_exit				;jmp if no valid name entered
;
; terminate string with zero
;
  mov	eax,[str_ptr]
  mov	byte [eax],0			;terminate string

  call	find_continue			;search for string
;
s_loop2:
  mov	ebp,menu_table
  call	menu_handler			;get get input
  jecxz	s_exit				;igonre clicks in unknown area
  call	ecx				;call keyboard process !!!!
  cmp	al,0				;check if normal loop
  je	s_loop2
  cmp	al,1				;check if new search
  je	s_loop1				;jmp if new search
s_exit:
  mov	esi,[selected_todo]
  call	prev_todo
  call	prev_todo
  mov	[display_top_ptr],esi
  ret
;-------------------
 [section .data]
menu_table:
  db	2			;two lines per button
  db	1			;put on top of screen
  dd	mline1
  dd	mprocess
  dd	mkeys

mline1:
  db 1,' find from ',1,' continue ',1,' edit ',1,' new find ',1,' quit ',0
  db 1,' top (f)   ',1,' find (c) ',1,' (e)  ',1,'   (n)    ',1,'  (q) ',0
mprocess:
  dd     find_top,      find_continue,  edit_find, new_find,    quit_find, 0
mkeys:
  db        'f',              'c',           'e',           'n',            'q', 0

search_tbl:
  dd  enter_string_msg2
  dd  todo_data_color
  dd  search_buf
  dd  search_buf_end - search_buf
  dd  edit_entry_color
search_row:
  db  0					;display row
search_column:
  db  1
  db  0					;terminate string with nl

enter_string_msg1    db 'Enter find text (ESC to abort, <ENTER> to accept) ',0
string_found_msg     db 'Search string found.                              ',0
string_not_found_msg db 'Search string NOT found.                          ',0
end_buffer_msg       db 'End of buffer reached                             ',0
enter_string_msg2  db ' > ',0

search_buf	times 50 db  ' '
search_buf_end:
  db 0,0
;----------------- 
 [section .text]

;-------------------------------------------------------------------
; search from top, set active_todo
; display status of search at [crt_rows]-8
;
find_top:
  mov	esi,fbuf
  jmp	find_next

;-------------------------------------------------------------------
; continue search from active_todo, set active_todo
; display status of search at [crt_rows]-8
;
find_continue:
  mov	esi,[active_todo_ptr]
  call	next_todo
  jnc	find_next		;go look for next match
  mov	ecx,end_buffer_msg
  jmp	fc_display

find_next:
  mov	[active_todo_ptr],esi
  mov	edi,esi              	;search buffer
  mov	esi,search_buf		;match string
  mov	edx,1			;set search direction to forward
  call	string_search		;edi,ebx = match if carry
  jc	fc_fail			;jmp if string not found
;
; scan to start of string
;
find_10:
  cmp	word [edi],0a0ah
  je	find_20			;jmp if beginning found
  cmp	edi,fbuf
  je	find_22			;jmp if at top of buffer
  dec	edi
  jmp	find_10			;loop back and keep looking
find_20:
  add	edi,2			;move forward past 0a0ah
  mov	[active_todo_ptr],edi	;store ptr
find_22:
;
; display match string found
;
  mov	eax,[todo_data_color]
  mov	bl,1				;column
  mov	bh,[crt_rows]
  sub	bh,12				;row
  mov	ecx,string_found_msg
  call	crt_color_at
;
; display match string, entered from edit_find also
;
display_match:
  mov	esi,edi			;get string pointer
  mov	bl,2			;column
  mov	bh,[crt_rows]
  sub	bh,8			;row
  mov	eax,[edit_entry_color]
  call	display_block		;display todo
  jmp	fc_exit
;
; display not found msg
;
fc_fail:
  mov	ecx,string_not_found_msg
fc_display:
  mov	eax,[todo_data_color]
  mov	bl,1				;column
  mov	bh,[crt_rows]
  sub	bh,12				;row
  call	crt_color_at
fc_exit:
  mov	al,0
  ret

edit_find:
  call	edit_jump
  mov	eax,[todo_data_color]
  call	crt_clear
  mov	edi,[active_todo_ptr]
  jmp	display_match

;;  mov	al,0
;;  ret

new_find:
  mov	al,1
  ret

quit_find:
  mov	al,2
  ret

;---------------------------------------------------------------------------
; menu_handler - show buttons and process responses
;  input: ebp = pointer to table -> db  -number of lines to create a button
;                                   db  -location of first button line
;                                   dd  -pointer to text lines
;                                   dd  -pointer to process table
;                                   dd  -pointer to key table
;
; output: ecx = process requested by user
;
; example: ebx = mtable db  2  ;two lines need to create a button
;                       db  1  ;first line of button is at top of screen
;                       dd  bline1  ;text of button line1, line2 follows
;                       dd  process_tbl ;process pointers matching buttons
;                       dd  key_tbl  ;keys matching buttons in same order as process's
;
; menu line codes: 1=spacer  0=end of data
;
;                       bline1
;                         db 1,' New-proj  ',1,' Del-proj  ',0
;                       bline2
;                         db 1,'    n      ',1,'    d      ',0
;                       process_tbl
;                         dd  new_proj,  del_proj, 0
;                       key_tbl
;                         db  'n','d',0
;
menu_handler:
  mov	esi,[ebp + 2]		;get ptr to first text line
  mov	al,[ebp]		;get number of rows per button
  mov	ah,[ebp +1]		;get screen row
mh_lp1:
  push	eax
  call	build_line
  pop	eax
  push	eax
  dec	ah
  mov	al,1
  call	move_cursor		;position cursor
  mov	ecx,lib_buf
  call	crt_str
  pop	eax
  inc	ah			;move to next row
  dec	al			;check if done
  jnz	mh_lp1			;go back and display next line
;
; buttons are displayed, now read keyboard
;
  call	read_stdin		;get keyboard data
  cmp	byte [kbuf],-1		;check if mouse click
  jne	mh_key_event		;jmp if key press
  call	mh_mouse_decode
  jmp	mh_end
mh_key_event:
  mov	eax,dword [kbuf]
  call	mh_key_decode		;ecx = index or err(0)
mh_end:
  ret
;----------------------------------------------------------------
; mh_key_event - get process to match key press
;  inputs:  ebp - pointer to menu table
;  output:  ecx - process or zero if none found, (use call ecx )
; This logic only handles lower case alpha keys
;
mh_key_decode:
  mov	ecx,[ebp + 6]	;get ptr to first process
  mov	esi,[ebp + 10]	;get ptr to first key
  mov	al,[kbuf]	;get key
mhk_lp:
  mov	ah,[esi]	;get next key
  cmp	ah,0
  je	mhk_exit	;exit if no matchs in table
  cmp	ah,al		;check this key
  je	mhk_exit	;exit if match found
  inc	esi		;move to next key
  add	ecx,4		;move to next process
  jmp	mhk_lp
mhk_exit:
  mov	ecx,[ecx]	;get process
  ret

;---------------------------------------------------------------
; mh_mouse_event - get process to match mouse click
;  inputs:  ebp - pointer to menu table
;           kbuf = ff,button,column,row  
;  output:  ecx - process or zero if none found, (use call ecx )
;
mh_mouse_decode:
  mov	bl,[kbuf+2]	;get column 1+
  mov	bh,[kbuf+3]	;get row 1+
;
; check if click on buttons
;
  mov	ah,[ebp + 1]	;get row of buttons
  mov	al,[ebp]	;get numbero of rows to create one button
  dec	ah
  xor	ecx,ecx		;preload null process
mhm_lp1:
  cmp	bh,ah		;check if click on button row
  je	mhm_10		;jmp if click on correct row
  inc	ah		;move to next row
  dec	al
  jnz	mhm_lp1
  jmp	mhm_exit1	;jmp if click out of range
;
; we have found a click on button row
;
mhm_10:
  mov	bl,1				;starting column
  mov	esi,[ebp + 2]			;starting button text
  mov	edi,[ebp + 6]			;look up table to process
mhm_62:
  inc	bl
  inc	esi
  cmp	bl,[kbuf + 2 ]			;display columns match?
  je	mhm_exit2			;jmp if we are at click column
  cmp	byte [esi],9
  jae	mhm_62				;jmp if normal char

  cmp	byte [esi],0			;check if outside button area
  je	mhm_exit1			;exit if beyond buttons
  add	edi,4				;move to next process
  jmp	mhm_62
mhm_exit1:
  xor	ecx,ecx				;return ecx to caller
  jmp	mhm_exit
mhm_exit2:
  mov	ecx,[edi]			;get process
mhm_exit:      
  ret



;--------------------
;inputs
; fbuf = buffer which will be scanned
; [file_end_ptr] - end of file ptr
; esi = match string
; edi - cursor position in buffer
; edx = find direction -1=back 1=forward
;output
; carry = not found
; edi,ebx = match pointer if no carry
; clobbered = ecx,eax,esi
;
string_search:
  mov	[find_str],esi		;save pointer to match string
;
; initialize start of match string
;
fnd0:
  mov	ch,0dfh			;get case mask
  mov	esi,[find_str]		;get match string
  cld
  lodsb				;get match character
  or	al,al
  jz	notfnd			;exit if no string entered
  cmp	al,41h
  jb	fnd1			;jmp if not alpha character
  and	al,ch			;adjust case
;
; looking for match on first character, loop
;
fnd1:
  mov	cl,byte [edi]		;get character from buffer
  cmp	cl,41h			;check if possible alpha
  jb	fnd6			;jmp if not alpha
  and	cl,ch			;adjust case
fnd6:
  cmp	al,cl			;compare match string to buffer
  je	fnd2			;jmp if first char. matches
  add	edi,edx			;add edi,[scan_direction]	;direction of find control
  cmp	edi,[file_end_ptr]
  ja	notfnd			;jmp if at end of buffer
  cmp	edi,fbuf		;check if backwards scan at start of buffer
  ja	fnd1			;loop back if still looking for first match char
  jmp	notfnd
;
; we have found first match
;
fnd2:
  mov	ebx,edi			;save  start of match
;
; matching loop
;
fnd3:
  lodsb			;get next match string char
  or	al,al		;=end?
  jz	fnd		;done if match
  cmp	al,41h
  jb	fnd7		;jmp if possible alpha character
  and	al,ch		;adjust case of char
fnd7:
  inc	edi
  cmp	edi,[file_end_ptr]
  jae	notfnd		;exit if string not found
  mov	cl,byte [edi]	;get next buffer char
  cmp	cl,41h
  jb	fnd10
  and	cl,ch		;adjust case
fnd10:
  cmp	al,cl		;compare two upper case characters
  jz	fnd3		;loop if match
;
; this partial match failed, go back and reinitialize match string
;
  mov	edi,ebx
  add	edi,edx		;move to next buffer position
  jmp	fnd0
;
; exit
;
notfnd:
  stc
  ret
fnd:
  mov	edi,ebx
  clc
  ret

 [section .data]

find_str	dd	0

 [section .text]

;-----------------------------------------------------
; display_block
;    inputs: esi=text block to display (has 0ah line ends and 0a0ah end of message
;            bl = column
;            bh = starting row
;            eax = color
;
display_block:
  push	ebx
  push	eax
  push	esi
;
; put  zero at end of this line
;  
  push	esi
db_04:
  cmp	byte [esi],0ah
  je	db_10			;jmp if end of line found
  inc	esi
  jmp	db_04			;loop
db_10:
  mov	byte [esi],0		;put zero at end of line
  pop	esi
;
; display line
;
;                               ;eax = color
;                               ;bl = column
;                               ;bh = row
  mov	ecx,esi			;ecx = message ptr 
  call	crt_color_at
  pop	esi
  pop	eax
  pop	ebx
;
; retore 0ah at end of line
;
db_14:
  cmp	byte [esi],0
  je	db_20			;jmp if end of line found
  inc	esi
  jmp	db_14			;loop
db_20:
  mov	byte [esi],0ah		;put 0ah back
;
; check if done
;
  cmp	word [esi],0a0ah
  je	db_done
  inc	esi			;move past 0ah to next line
  inc	bh			;move to next row
  jmp	display_block
db_done:
  ret