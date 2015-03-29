  extern days_in_month
  extern ascii_to_dword

;*************   edit.inc **********************
text_column equ	3
;-----------------------------------------------
; interface with human to edit a single todo entry
;  input:  eax = pointer to todo entry
;  output: todo fields updated
;          al = return code 2-normal exit, save edits
;                           3-delete this todo
;                           4-save edits, next todo
;                           5-save edits, previous todo
;                           6-abort, abandon edits, restore origional data
;
edit_todo:
  mov	[current_edit_todo],eax	;save ptr to todo
  call	edit_setup
  call	insert_text
  call	build_years
  call	build_days
  call	light_state
  call	light_year
  call	light_month
  call	light_day
  call	light_schedule
edit_lp1:
  call	display_edit_table
  call	edit_display_time
edit_lp2:
  mov	ebp,get_string_table
  call	get_edit_string		;output 0=unknown key typed  1=mouse click
  cmp	al,0
  je	key_process		;jmp if key event
  cmp	byte [kbuf],-1		;verify this was a mouse event
  jne	edit_lp2		;jmp if not mouse event
  mov	al,[kbuf +1 ]		;get mouse button
  mov	[edit_click_button],al	;save mouse button
  mov	ah,[kbuf + 2]		;get mouse column
  mov	al,[kbuf + 3]		;get mouse row
  mov	[edit_click_column],ah
  mov	[edit_click_row],al
  call	cursor_to_table		;find table location for mouse
  call	find_mouse_process
  jmp	el_process
key_process:
  mov	eax,dword [kbuf]
  call	decode_edit_key		;ecx = index or err(0)
el_process:
  mov	esi,[current_edit_todo]	;pass process a pointer to current todo
  jecxz	ml_end2
  call	ecx			;call keyboard or mouse process !!!!
ml_end2:
  mov	al,[edit_mode]
  cmp	al,0
  je	edit_lp1		;jmp if redisplay needed
  cmp	al,1
  je	edit_lp2		;jmp if no redisplay of screen needed
  ret				;return code in -al-

  [section .data]
get_string_table:
current_line_ptr  dd	edit_line1			;initiial buffer
max_string_length dd	default_text_field_len		;60
str_color	  dd	edit_button_color
display_row       db	15
display_column    db    text_column
string_flag	  db    0		;no cr/lf in string
cursor_column	  db	text_column
  [section .text]


;------------------------------------------------
; initialize
;
edit_setup:
  mov	eax,edit_line1
  mov	[current_line_ptr],eax
  mov	[edit_text_ptr],eax
  call	table_to_cursor
  mov	al,[edit_click_row]
  mov	[display_row],al
  mov	al,[edit_click_column]
  mov	[display_column],al
  mov	[cursor_column],al
  mov	byte [edit_mode],0
  ret	 
;------------------------------------------------
; build year entries in edit_table
;  inputs:  current_edit_todo
;  output:  edit_table adjusted with years
;
build_years:
  mov	esi,[current_edit_todo]
  add	esi,year_field
  mov	eax,[esi]
  mov	[tmp_year],eax			;store year as asciiz
  mov	esi,tmp_year			;setup to call  ascii_to_dword
  call	ascii_to_dword		;returns year in ecx
  mov	eax,ecx
  push	eax
  mov	edi,years		;storage point for ascii
  mov	esi,4
  call	dword_to_l_ascii  
  pop	eax
  inc	eax
  add	edi,4
  push	eax
  mov	esi,4
  call	dword_to_l_ascii
  pop	eax
  inc	eax
  add	edi,4
  mov	esi,4
  call	dword_to_l_ascii
  ret

  [section .data]
tmp_year	db	'0000',0
  [section .text]

;-----------------------------------------------
; build days per month in edit_table
;   input:  current_edit_todo
;
build_days:
  mov	esi,[current_edit_todo]	;setup to convert year to binary
  mov	eax,[esi + year_field]	;get ascii year for current todo
  mov	[temp_yearx],eax	;store year in asciiz holding area
  mov	esi,temp_yearx
  call	ascii_to_dword	; we need year for leap calculation
  push	ecx			;store this todo's year as binary
;
; now convert month to binary
;
  mov	esi,[current_edit_todo]
  mov	ax,[esi + month_field]	;store month as asciiz
  mov	[tmp_month],ax
  mov	esi,tmp_month
  call	ascii_to_dword	; we need decimal month# to look up days
  mov	bl,cl			;move month# to bl
  pop	edx			;get binary year
  call	days_in_month
  mov	al,bl
 
  mov	edi,day31		;point at last displayed day (31)
  cmp	al,31
  je	aet_20			;jmp if 31 days in this month
  mov	word [edi],'  '		;blank out day 31
  jmp	short aet_21
aet_20:
  mov	word [edi],'31'
aet_21:

  sub	edi,6			;move to next day (30)
  cmp	al,30
  jae	aet_22			;jmp if days=30
  mov	word [edi],'  '		;blank out day 30
  jmp	short aet_23
aet_22:
  mov	word [edi],'30'
aet_23:

  sub	edi,6
  cmp	al,29
  jae	aet_24			;jmp if days=29 (leap year)
  mov	word [edi],'  '
  jmp	short aet_25
aet_24:
  mov	word [edi],'29'
aet_25:
  ret

  [section .data]
temp_yearx	db	'xxxx',0
tmp_month	db	'xx',0
  [section .text]

;-----------------------------------------------
; highlight the current todo's state
;  input:  current_edit_todo
;
light_state:
  mov	edi,[state_save_ptr]
  mov	byte [edi],2			;restore virgin state
  mov	esi,[current_edit_todo]
  mov	al,[esi]			;get state flag
  mov	edi,pending -1
  cmp	al,"_"				;check if pending
  je	light_state1
  mov	edi,completed -1
  cmp	al,'C'
  je	light_state1
;
; assume delete
;
  mov	edi,deleted -1
light_state1:
  mov	byte [edi],3
  mov	dword [state_save_ptr],edi
  ret

  [section .data]
state_save_ptr	dd	pending -1
  [section .text]


;-----------------------------------------------
; highlihgt the current todo's year
;  input:  current_edit_todo
;
light_year:
  mov	edi,[selected_year_ptr]
  mov	byte [edi-1],2			;remove all highlights
  mov	esi,[current_edit_todo]
  add	esi,year_field
  mov	eax,[esi]			;get year
  mov	edi,years
ly_lp:
  cmp	eax,[edi]
  je	ly_20				;jmp if year found
  inc	edi				;move to next year
  jmp	ly_lp
ly_20:
  mov	[selected_year_ptr],edi
  mov	byte [edi -1],3			;light up  current year
  ret

;-----------------------------------------------
; hightlight the current todo's month
;  input: current_edit_todo
;
light_month:
  mov	esi,[selected_month_ptr]
  mov	byte [esi-1],2			;remove all highlights
  mov	esi,[current_edit_todo]
  add	esi,month_field
  mov	ax,[esi]			;get month
  mov	esi,months
lm_lp:
  cmp	ax,[esi]
  je	lm_20				;jmp if days found
  add	esi,6
  jmp	lm_lp
lm_20:
  mov	[selected_month_ptr],esi
  mov	byte [esi -1],3			;light up  current month
  ret

;-----------------------------------------------
; highlight the current todo's day
;  input:  current_edit_todo
;
light_day:
  mov	esi,[selected_day_ptr]
  mov	byte [esi -1],2			;remove all highlights
  mov	esi,[current_edit_todo]
  add	esi,day_field
  mov	ax,[esi]			;get day
  mov	esi,days1
ld_lp:
  cmp	ax,[esi]
  je	ld_20				;jmp if days found
  inc	esi
  jmp	ld_lp
ld_20:
  mov	[selected_day_ptr],esi
  mov	byte [esi -1],3			;light up  current day
  ret

;-----------------------------------------------
; highlight the current resschedule option for new todo
;  input:  current_edit_todo
;  output: selected_sched_text
;          selected_sched_ptr
;
light_schedule:
  mov	esi,[selected_sched_ptr]
  mov	byte [esi -1],2			;remove old highlight
  mov	esi,[current_edit_todo]
  add	esi,sched_field
  mov	ax,[esi]			;get sched code

;nasm can't handle?
;  and	ax,0ffdfh			;remove any lower case, flag for extended data
  and	ax,-33

  mov	esi,resched_table
ls_lp:
  cmp	ax,[esi]
  je	ls_found
  add	esi,10
  cmp	byte [esi],0
  jne	ls_lp			;loop till resched found
ls_found:
  mov	[selected_sched_text],ax
  mov	esi,[esi + 2]		;get edit_table ptr
  mov	[selected_sched_ptr],esi
  mov	byte [esi -1],3		;light up selected sched
  ret


resched_table:
  db 'D0'		;todo data file code - once
  dd schedule_once	;edit_table ptr
  dd resched_once	;resched process
;
  db 'D1'		;todo data file code - daily
  dd schedule_daily	;edit_table ptr
  dd resched_daily	;resched process
;
  db 'ME'		;todo data file code - at EOM
  dd schedule_eom	;edit_table ptr
  dd resched_eom	;resched process
;
  db 'W1'		;todo data file code
  dd schedule_wk1	;edit_table ptr
  dd resched_wk1	;resched process
;
  db 'W2'		;todo data file code
  dd schedule_wk2	;edit_table ptr
  dd resched_wk2	;resched process
;
  db 'W3'		;todo data file code
  dd schedule_wk3	;edit_table ptr
  dd resched_wk3	;resched process
;
  db 'W4'		;todo data file code
  dd schedule_wk4	;edit_table ptr
  dd resched_wk4	;resched process
;
  db 'M1'		;todo data file code
  dd schedule_m1	;edit_table ptr
  dd resched_m1		;resched process
;
  db 'M2'		;todo data file code
  dd schedule_m2	;edit_table ptr
  dd resched_m2		;resched process
;
  db 'M3'		;todo data file code
  dd schedule_m3	;edit_table ptr
  dd resched_m3		;resched process
;
  db 'M4'		;todo data file code
  dd schedule_m4	;edit_table ptr
  dd resched_m4		;resched process
;
  db 'M6'		;todo data file code
  dd schedule_m6	;edit_table ptr
  dd resched_m6		;resched process
;
  db 'Y1'		;todo data file code
  dd schedule_y1	;edit_table ptr
  dd resched_y1		;resched process
;
  db 'Y2'		;todo data file code
  dd schedule_y2	;edit_table ptr
  dd resched_y2		;resched process
;
  db 'Y3'		;todo data file code
  dd schedule_y3	;edit_table ptr
  dd resched_y3		;resched process
;
  db 0			;end of table
;

;-----------------------------------------------
; extract todo text from table
;  inputs:  edit_table
;           current_edit_todo (pointer)
;
extract_text:
  mov	edi,[current_edit_todo]
  add	edi,text_field			;move to text area
;
; move text from table
;
  cld
  mov	esi,edit_line1
  call	find_line_end
  rep	movsb				;move line
  mov	byte [edi],0ah			;terminate line1
  inc	edi
  
  mov	esi,edit_line2
  call	find_line_end
  rep	movsb				;move line
  mov	byte [edi],0ah			;terminate line1
  inc	edi
  
  mov	esi,edit_line3
  call	find_line_end
  rep	movsb				;move line
  mov	byte [edi],0ah			;terminate line1
  inc	edi
  
  mov	esi,edit_line4
  call	find_line_end
  rep	movsb				;move line
  mov	byte [edi],0ah			;terminate line1
  inc	edi
  
  mov	esi,edit_line5
  call	find_line_end
  rep	movsb				;move line
  mov	byte [edi],0ah			;terminate line1
  inc	edi

  mov	byte [edi],0ah			;terminate todo
  mov	byte [edi+1],0			;put zero at end

  ret

;-----------------------------------------------
; find the end of text line in edit_table
;  input:  esi - points at start of line
;  output: esi - points at start of line
;          ecx - count of characters in line +1
;          carry set if null line
;
find_line_end:
  push	esi
  mov	ecx,default_text_field_len ;get max line length
  add	esi,ecx			;move to end of line
fle_lp:
  jecxz	fle_exit1		;jmp if only blanks found on this line
  dec	esi
  dec	ecx
  cmp	byte [esi],' '
  je	fle_lp
  jmp	fle_exit2		;jmp if non-blank line found
fle_exit1:
  pop	esi			;blank line was found, exit
  jmp	fle_exit5
fle_exit2:
  inc	ecx			;adjust count
  pop	esi
  push	ebx
  mov	ebx,[current_edit_todo]
  add	ebx,sched_field
  cmp	esi,edit_line1
  jne	fle_exit3		;jump if not line 1 and line non-blank
  and	byte [ebx],0dfh		;clear extended data flag
  jmp	fle_exit4
fle_exit3:
  or 	byte [ebx],020h		;set extended data flag
fle_exit4:
  pop	ebx
fle_exit5:
 ret
;-----------------------------------------------
; insert todo text into edit_table
;  input:  edit_table
;          current_edit_todo
;  output: current_line_ptr
;
insert_text:
  mov	esi,[current_edit_todo]
  mov	edi,edit_line1
  mov	[current_line_ptr],edi	;save for later
  add	esi,text_field		;move to start of text
  mov	ecx,default_text_field_len  ;line length
it_lp1:
  cmp	byte [esi],0ah
  je	it_eol1a		;jmp if end of input data
  movsb				;move data
  dec	ecx
  jnz	it_lp1
;
; we have filled one table line,  scan input data till end of current line found
;
it_lp2:
  inc	esi
  cmp	byte [esi],0ah
  jne	it_lp2
;   
; we are at end of input data, verify table is filled
;
it_eol1a:
  mov	al,' '
it_lp3:
  jcxz	it_eol1			;jmp if eol for both input and table
  stosb
  dec	ecx
  jmp	it_lp3
; 
it_eol1:
  inc	esi
  cmp	byte [esi],0ah
  jne	it_10			;jmp if not end of input data
;
; we are at end of all input data, fill remaining table lines with blanks
;
it_eol2:
  jcxz	it_eol3
it_04:
  mov	al,' '
it_05:
  stosb
  dec	ecx
  jnz	it_05			;loop till end of table field cleared
it_eol3:
  call	insert_text_helper
  jcxz	it_exit
  jmp	it_04
;
; we have more input data, another line
;
it_10:
  call	insert_text_helper
  jcxz	it_exit			;exit if table full
  jmp	it_lp1
it_exit:
  ret  

;-------------------------------------
; setup edi, ecx for next line
;  input: edi = pointer to last data stored in table
;  output:  ecx=0 if at end
;
insert_text_helper:
  mov	ecx,default_text_field_len	;setup for next line

  cmp	edi,edit_line2
  ja	it_20			;jmp if not doing line1
  mov	edi,edit_line2
  jmp	ith_exit

it_20:
  cmp	edi,edit_line3
  ja	it_30
  mov	edi,edit_line3
  jmp	ith_exit

it_30:
  cmp	edi,edit_line4
  ja	it_40
  mov	edi,edit_line4
  jmp	ith_exit

it_40:
  cmp	edi,edit_line5
  ja	it_50
  mov	edi,edit_line5
  jmp	ith_exit
it_50:
  mov	ecx,0
ith_exit:
  ret

;------------------------------------------------
; display the contents of edit_table
;  inputs:  edit_table
;
display_edit_table:
  mov	esi,edit_table		;get table pointer
  mov	dh,1			;row
td_next_line:
  mov	edi,lib_buf		;storage buffer
  mov	dl,1			;column
  mov	ecx,[left_column]	;get scroll count
td_lp:
  lodsb
  test	al,80h
  jnz	td_lp			;jmp/ignore special processing codes
  cmp	al,9
  jbe	td_20			;jmp if function found
  jecxz	td_10			;jmp if left column scroll not needed
  dec	ecx
  jmp	short td_lp
td_10:
  stosb				;store data
  inc	dl
  jmp	td_lp
td_20:
  cmp	al,9
  jne	td_15
  jmp	td_30			;jmp if tail needed
td_15:
  cmp	al,5
  jne	td_21
  jmp	td_40			;jmp if end of data
td_21:
  mov	ebx,[edit_color]
  cmp	al,1
  jne	td_2x
  jmp	td_50			;jmp if color 1
td_2x:
  mov	ebx,[edit_field_color]
  cmp	al,2
  jne	td_22
  jmp	td_50			;jmp if color 2
td_22:
  mov	ebx,[edit_entry_color]
  cmp	al,3
  je	td_50			;jmp if color 3
  mov	ebx,[edit_button_color]
  cmp	al,4
  je	td_50			;jmp if color 4
  cmp	al,0
  je	td_90			;jmp if end of table
;
; write blanks to end of line, init for next line
;
td_30:
  call	display_tail
  inc	dh			;bump row
  jmp	td_next_line
;
; we are at end of data, fill remaining lines with blanks
;
td_40:
  mov	dl,[crt_rows]
  inc	dl
  cmp	dl,dh
  jbe	td_90			;exit if done
  mov	edi,lib_buf		;storage buffer
  mov	ecx,[left_column]	;get scroll count
  mov	dl,1			;start from column 1
  call	display_tail
  inc	dh
  jmp	td_40
;
; handle colors
;
td_50:
  mov	eax,ebx
  push	edx
  call	mov_color
  pop	edx
  jmp	td_lp
;
td_90:
  ret

;---------------------------------------
; fill blanks to end of screen, display line,  and init for next line
;
display_tail:
  push	edx
;
; write blanks to end of line
;
  mov	al,' '
dt10:
  cmp	dl,[crt_columns] ;check if at end of line
  ja	dt20		;jmp if at end
  stosb
  inc	dl
  jmp	short dt10	;loop till line filled out
dt20:
  mov	byte [edi],0	;terminate text in lib_buf
  mov	eax,edx
  mov	al,1		;display from column 1
  call	move_cursor
  mov	ecx,lib_buf
  call	crt_str
  pop	edx
  ret

  extern crt_str

;------------------------------------------------
; display_time - add time to end of display
;  inputs:  edit_color
;           crt_rows
;           seconds_today
; output: hour_today  minute_today
;         ascii_hour  ascii_minute
;
edit_display_time:
  call	get_raw_time		;returns raw time in eax,ebx
  mov	edi,lib_buf + 400
  mov	ebx,format3
  call	raw2ascii
  mov	byte [edi],0		;put zero at end of msg
  mov	al,2			;column
  mov	ah,[crt_rows]
  sub	ah,1
  call	move_cursor
  mov	ecx,lib_buf + 400
  call	crt_str
  ret

;----------------------------------------------------------
format3:
  db '6- 2, 7- 0   1-2-0   time 3:4:58',0


;------------------------------------------------
; find edit_table entry from cursor position
;  inputs:  edit_click_row
;           edit_click_column
;  output: edit_text_ptr
;
cursor_to_table:
  mov	bh,1			;set startng row
  mov	bl,1			;set starting column
  mov	esi,edit_table
ctt_lp1:
  lodsb				;get next table entry
  cmp	al,9			;check if end of line
  je	ctt_02			;jmp if eol  
  cmp	byte [edit_click_row],bh
  je	ctt_08			;jmp if correct row found
  cmp	al,0
  je	ctt_exit		;jmp if click outside table
  jmp	ctt_lp1
ctt_02:
  inc	bh			;bump row
  jmp	ctt_lp1			;loop till row found
;
; correct row found, now look for column match
;
ctt_lp2:
  lodsb
ctt_08:
  cmp	byte [edit_click_column],bl
  je	ctt_match		;jmp if column found
  cmp	al,9
  jb	ctt_lp2			;jmp if control byte
  je	ctt_exit		;jmp if no match on this line
  test	al,80h
  jnz	ctt_lp2			;jmp if process code
  inc	bl			;bump column
  jmp	ctt_lp2
ctt_match:
  dec	esi
ctt_exit:
  mov	[edit_text_ptr],esi
  ret

;-------------------------------------------------
; find text cursor position from table address
;  inputs:  edit_text_ptr
;  output:  edit_click_row
;           edit_click_column
;
table_to_cursor:
  mov	esi,edit_table
  mov	byte [edit_click_row],1
  mov	byte [edit_click_column],1
ttc_lp:
  cmp	esi,[edit_text_ptr]
  je	ttc_exit		;jmp if done
  mov	al,[esi]		;get table entry
  cmp	al,0			;check if end of table
  je    ttc_exit		;exit if end
  test	al,80h			;check if process code
  jnz	ttc_next		;jmp if process code
  cmp	al,9
  ja	ttc_text		;jmp if normal text char
  je	ttc_line		;jmp if end of line
  jmp	ttc_next		;ignore all others
ttc_line:
  inc	byte [edit_click_row]
  mov	byte [edit_click_column],1
  jmp	ttc_next
ttc_text:
  inc	byte [edit_click_column]
ttc_next:
  inc	esi
  jmp	ttc_lp
ttc_exit:
  ret

;------------------------------------------------
; find process for edit_table location
;  inputs:  edit_text_ptr
;  output:  ecx = process pointer
;
find_mouse_process:
  mov	esi,[edit_text_ptr]
fmp_lp:
  cmp	esi,edit_table
  jne	fmp_04			;jmp if inside table
  mov	eax,fmp_exit		;get null process
  jmp	fmp_exit		;return null process
fmp_04:
  mov	al,[esi]
  test	al,80h
  jnz	fmp10			;jmp if process found
  dec	esi
  jmp	fmp_lp
;
; we have found process code
;
fmp10:
  neg	al			;make positive
  xor	ebx,ebx
  mov	bl,al
  shl	ebx,2			;looking up process
  add	ebx,edit_process_table -4
  mov	ecx,[ebx]		;get process
fmp_exit:
  ret


;---------------------------------------------------------
;  edit mouse processes
;    inputs to all processes  esi = [current_todo_ptr]
;    output  edit_mode = 0 (redisplay loop)
;            edit_mode = 1 (no redisplay loop)
;            edit_mode = 1 exit edit mode
;---------------------------------------------------------
;
edit_pending:		;-1
  mov	byte [esi],"_"			;set pending code in todo
  call	light_state			;update color attributes
  jmp	redisplay_rtn			;go  redisplay screen

edit_complete:		;-2
  mov	byte [esi],'C'
  call	light_state
  jmp	redisplay_rtn

edit_deleted_status:	;3
  mov	byte [esi],'D'
  call	light_state
  jmp	redisplay_rtn
  
edit_year1:		;4
  mov	eax,[years]			;get current clicked year
  mov	[esi + year_field],eax		;put new year into todo
  call	light_year
  jmp	redisplay_rtn

edit_year2:		;5
  mov	eax,[years2]			;get current clicked year
  mov	[esi + year_field],eax		;put new year into todo
  call	light_year
  jmp	redisplay_rtn

edit_year3:		;6
  mov	eax,[years3]			;get current clicked year
  mov	[esi + year_field],eax		;put new year into todo
  call	light_year
  jmp	redisplay_rtn

edit_month_01:		;7
  mov	word [esi + month_field],'01'	;store month ascii in todo
  call	light_month
  jmp	redisplay_rtn

edit_month_02:		;8
  mov	word [esi + month_field],'02'	;store month ascii in todo
  call	light_month
  jmp	redisplay_rtn

edit_month_03:		;9
  mov	word [esi + month_field],'03'	;store month ascii in todo
  call	light_month
  jmp	redisplay_rtn

edit_month_04:		;10
  mov	word [esi + month_field],'04'	;store month ascii in todo
  call	light_month
  jmp	redisplay_rtn

edit_month_05:		;11
  mov	word [esi + month_field],'05'	;store month ascii in todo
  call	light_month
  jmp	redisplay_rtn

edit_month_06:		;12
  mov	word [esi + month_field],'06'	;store month ascii in todo
  call	light_month
  jmp	redisplay_rtn

edit_month_07:		;13
  mov	word [esi + month_field],'07'	;store month ascii in todo
  call	light_month
  jmp	redisplay_rtn

edit_month_08:		;14
  mov	word [esi + month_field],'08'	;store month ascii in todo
  call	light_month
  jmp	redisplay_rtn

edit_month_09:		;15
  mov	word [esi + month_field],'09'	;store month ascii in todo
  call	light_month
  jmp	redisplay_rtn

edit_month_10:		;16
  mov	word [esi + month_field],'10'	;store month ascii in todo
  call	light_month
  jmp	redisplay_rtn

edit_month_11:		;17
  mov	word [esi + month_field],'11'	;store month ascii in todo
  call	light_month
  jmp	redisplay_rtn

edit_month_12:		;18
  mov	word [esi + month_field],'12'	;store month ascii in todo
  call	light_month
  jmp	redisplay_rtn

edit_day_01:		;19
  mov	word [esi + day_field],'01'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_02:		;20
  mov	word [esi + day_field],'02'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_03:		;21
  mov	word [esi + day_field],'03'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_04:		;22
  mov	word [esi + day_field],'04'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_05:		;23
  mov	word [esi + day_field],'05'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_06:		;24
  mov	word [esi + day_field],'06'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_07:		;25
  mov	word [esi + day_field],'07'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_08:		;26
  mov	word [esi + day_field],'08'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_09:		;27
  mov	word [esi + day_field],'09'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_10:		;28
  mov	word [esi + day_field],'10'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_11:		;29
  mov	word [esi + day_field],'11'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_12:		;30
  mov	word [esi + day_field],'12'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_13:		;31
  mov	word [esi + day_field],'13'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_14:		;32
  mov	word [esi + day_field],'14'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_15:		;33
  mov	word [esi + day_field],'15'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_16:		;34
  mov	word [esi + day_field],'16'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_17:		;35
  mov	word [esi + day_field],'17'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_18:		;36
  mov	word [esi + day_field],'18'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_19:		;37
  mov	word [esi + day_field],'19'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_20:		;38
  mov	word [esi + day_field],'20'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_21:		;39
  mov	word [esi + day_field],'21'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_22:		;40
  mov	word [esi + day_field],'22'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_23:		;41
  mov	word [esi + day_field],'23'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_24:		;42
  mov	word [esi + day_field],'24'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_25:		;43
  mov	word [esi + day_field],'25'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_26:		;44
  mov	word [esi + day_field],'26'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_27:		;45
  mov	word [esi + day_field],'27'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_28:		;46
  mov	word [esi + day_field],'28'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_29:		;47
  mov	word [esi + day_field],'29'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_30:		;48
  mov	word [esi + day_field],'30'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_day_31:		;49
  mov	word [esi + day_field],'31'	;store month ascii in todo
  call	light_day
  jmp	redisplay_rtn

edit_sched_once:		;50
  mov	word [esi + sched_field],'D0'
  call	light_schedule
  jmp	redisplay_rtn

edit_sched_daily:	;51
  mov	word [esi + sched_field],'D1'
  call	light_schedule
  jmp	redisplay_rtn

edit_sched_eom:		;52
  mov	word [esi + sched_field],'ME'
  call	light_schedule
  jmp	redisplay_rtn

edit_sched_wk1:		;53
  mov	word [esi + sched_field],'W1'
  call	light_schedule
  jmp	redisplay_rtn

edit_sched_wk2:		;54
  mov	word [esi + sched_field],'W2'
  call	light_schedule
  jmp	redisplay_rtn

edit_sched_wk3:		;55
  mov	word [esi + sched_field],'W3'
  call	light_schedule
  jmp	redisplay_rtn

edit_sched_wk4:		;56
  mov	word [esi + sched_field],'W4'
  call	light_schedule
  jmp	redisplay_rtn

edit_sched_m1:		;57
  mov	word [esi + sched_field],'M1'
  call	light_schedule
  jmp	redisplay_rtn

edit_sched_m2:		;58
  mov	word [esi + sched_field],'M2'
  call	light_schedule
  jmp	redisplay_rtn

edit_sched_m3:		;59
  mov	word [esi + sched_field],'M3'
  call	light_schedule
  jmp	redisplay_rtn

edit_sched_m4:		;60
  mov	word [esi + sched_field],'M4'
  call	light_schedule
  jmp	redisplay_rtn

edit_sched_m6:		;61
  mov	word [esi + sched_field],'M6'
  call	light_schedule
  jmp	redisplay_rtn

edit_sched_y1:		;62
  mov	word [esi + sched_field],'Y1'
  call	light_schedule
  jmp	redisplay_rtn

edit_sched_y2:		;63
  mov	word [esi + sched_field],'Y2'
  call	light_schedule
  jmp	redisplay_rtn

edit_sched_y3:		;64
  mov	word [esi + sched_field],'Y3'
  call	light_schedule
  jmp	redisplay_rtn


edit_del_button:		;65
  mov	byte [esi],'D'
  mov	byte [edit_mode],3
  ret

edit_done_button:	;66
  call	extract_text
  mov	byte [edit_mode],2
  ret

edit_abort:		;67
  mov	byte [edit_mode],6
  ret

edit_text_line1:		;68
  mov	dword [current_line_ptr],edit_line1
  jmp	etl_entry

edit_text_line2:		;69
  mov	dword [current_line_ptr],edit_line2
  jmp	etl_entry

edit_text_line3:		;70
  mov	dword [current_line_ptr],edit_line3
  jmp	etl_entry

edit_text_line4:		;71
  mov	dword [current_line_ptr],edit_line4
  jmp	etl_entry

edit_text_line5:		;72
  mov	dword [current_line_ptr],edit_line5
etl_entry:
  call	cursor_to_table
  mov	al,byte [edit_click_row]
  mov	byte [display_row],al
  mov	al,byte [edit_click_column]
  mov	byte [cursor_column],al
  jmp	no_redisplay_rtn

edit_previous:		;73
  call	extract_text
  mov	byte [edit_mode],4
  ret

edit_next:		;74
  call	extract_text
  mov	byte [edit_mode],5
  ret

redisplay_rtn:
  mov	byte [edit_mode],0		;force redisplay of screen
  ret
no_redisplay_rtn:
  mov	byte [edit_mode],1
  ret
;---------------------------------------------------------
; decode_key - look up processing for this key
;  input - kbuf - has char zero terminated
;  output - ecx = ptr to processing or zero if no match
;           eax,ebx modified
decode_edit_key:
  mov	esi,key_table3
  call	key_decode1
  cmp	eax,alphakey
  jne	dek_exit
  xor	eax,eax
dek_exit:
  mov	ecx,eax
  ret

alphakey:			;dummy entry

key_table3:
  dd alphakey			;alpha key presss  

  db 1bh,0			;1 esc
  dd edit_done_button	;01

  db 1bh,5bh,32h,31h,7eh,0	;11 f10
  dd edit_done_button	;01

  db 1bh,5bh,42h,0		;20 pad_down
  dd edit_down		;02

  db 1bh,5bh,41h,0		;15 pad_up
  dd edit_up		;03

  db 0ah,0			;132 enter
  dd edit_enter_key	;04

  db 0dh,0
  dd edit_enter_key

  db 03h,0			;133 ctrl-c
  dd edit_abort		;05

  db 1bh,5bh,36h,7eh,0		;21 pad_pgdn
  dd edit_next		;06


  db 1bh,5bh,35h,7eh,0		;16 pad_pgup
  dd edit_previous	;07

  db 1bh,5bh,31h,39h,7eh,0	;9 f8
  dd edit_del_button	;08

  db 1bh,5bh,32h,30h,7eh,0	;10 f9
  dd edit_abort

  db 1bh,79h,0
  dd bump_year

  db 1bh,6dh,0
  dd bump_month

  db 1bh,64h,0
  dd bump_day

  db 1bh,73h,0
  dd bump_schedule

  db 1bh,59h,0
  dd dec_year

  db 1bh,4dh,0
  dd dec_month

  db 1bh,44h,0
  dd dec_day

  db 1bh,53h,0
  dd dec_schedule

  db 0f9h,0
  dd bump_year

  db 0edh,0
  dd bump_month

  db 0e4h,0
  dd bump_day

  db 0f3h,0
  dd bump_schedule

  db 0d9h,0
  dd dec_year

  db 0cdh,0
  dd dec_month

  db 0c4h,0
  dd dec_day

  db 0d3h,0
  dd dec_schedule

  db 0
  dd alphakey		;unknown key press

;
;------------------------------------------------------------------------------
bump_year:
  mov	ebp,1
  call	p_year
  ret

p_year:
  mov	esi,[current_edit_todo]
  add	esi,year_field
  push	esi
  mov	edi,lib_buf
  movsb
  movsb
  movsb
  movsb
  xor	eax,eax
  stosb
  mov	esi,lib_buf
  call	ascii_to_dword
  add	ecx,ebp
  mov	eax,ecx
  pop	edi
  mov	esi,4			;store 4 digets
  call	dword_to_l_ascii
  call	build_years
  call	light_year
  mov	byte [edit_mode],0
  ret

dec_year:
  mov	ebp,-1
  call	p_year
  ret

bump_month:
  mov	ebp,1
  call	p_month
  ret

p_month:
  mov	esi,[current_edit_todo]
  add	esi,month_field
  push	esi
  mov	edi,lib_buf
  movsb
  movsb
  xor	eax,eax
  stosb
  mov	esi,lib_buf
  call	ascii_to_dword
  add	ecx,ebp
  cmp	ecx,12
  ja	p_m4			;jmp if month 13
  cmp	ecx,1
  jae	p_m6			;jmp if month in range
  mov	ecx,1
  jmp	short p_m6
p_m4:
  dec	ecx			;ecx -> 12
p_m6:
  mov	eax,ecx
  pop	edi
  mov	esi,2			;store 2 digets
  call	dword_to_l_ascii
  call	light_month
  call	build_days
  mov	byte [edit_mode],0
  ret

dec_month:
  mov	ebp,-1
  call	p_month
  ret


bump_day:
  mov	ebp,1
  call	p_day
  ret

p_day:
  mov	esi,[current_edit_todo]
  add	esi,day_field
  push	esi
  mov	edi,lib_buf
  movsb
  movsb
  xor	eax,eax
  stosb
  mov	esi,lib_buf
  call	ascii_to_dword
  add	ecx,ebp
  cmp	ecx,31
  ja	p_d4			;jmp if day = 32
  cmp	ecx,1
  jae	p_d6			;jmp if month in range
  mov	ecx,1
  jmp	short p_d6
p_d4:
  dec	ecx			;ecx -> 12
p_d6:
  mov	eax,ecx
  pop	edi
  mov	esi,2			;store 2 digets
  call	dword_to_l_ascii
  call	light_day
  mov	byte [edit_mode],0
  ret

dec_day:
  mov	ebp,-1
  call	p_day
  ret

bump_schedule:
  mov	ebp,3
  call	p_sched
  ret

dec_schedule:
  mov	ebp,-3
  call	p_sched
  ret

p_sched:
  mov	esi,[current_edit_todo]
  add	esi,sched_field
  push	esi
  mov	edi,lib_buf
  movsb
  movsb
  xor	eax,eax
  stosb

  push	ebp
  mov	ebp,sched_list_end
  mov	esi,lib_buf
  mov	edi,sched_list
  mov	edx,1			;forward search
  mov	ch,0ffh			;match case
  call	blk_find		;sets ebx pointing to match
  pop	ebp

  add	ebx,ebp			;move to next field
  cmp	ebx,sched_list_end
  jae	p_s4			;jmp if at end of list
  cmp	ebx,sched_list
  jae	p_s6			;jmp if in range
  add	ebx,3
  jmp	short p_s6
p_s4:
  sub	ebx,3		;ecx -> 12
p_s6:
  mov	esi,ebx
  pop	edi
  movsb
  movsb
  call	light_schedule
  mov	byte [edit_mode],0
  ret

  db 0			;top of table
sched_list:
  db 'D0',0
  db 'D1',0
  db 'ME',0
  db 'W1',0
  db 'W2',0
  db 'W3',0
  db 'W4',0
  db 'M1',0
  db 'M2',0
  db 'M3',0
  db 'M4',0
  db 'M6',0
  db 'Y1',0
  db 'Y2',0
  db 'Y3',0
sched_list_end:
  db 0			;end of table

;
edit_down:
  cmp	dword [current_line_ptr],edit_line5
  je	ed_end
  inc	byte [display_row]
  add	dword [current_line_ptr],default_text_field_len +7
ed_end:
  jmp	no_redisplay_rtn

edit_up:
  cmp	dword [current_line_ptr],edit_line1
  je	eu_end				;jmp if at top already
  sub	dword [current_line_ptr],default_text_field_len +7
  dec	byte [display_row]
eu_end:
  jmp	no_redisplay_rtn


edit_enter_key:
  mov	byte [cursor_column],text_column
  cmp	byte [display_row],15+4
  je	eek_end
  inc	byte [display_row]
  add	dword [current_line_ptr],default_text_field_len +7
eek_end:
  jmp	no_redisplay_rtn

;---------------------------------------------------------
;  input:  ebp -> data buffer ptr         +0    (dword) has zero or preload
;                 max string length       +4    (dword) buffer must be bigger
;                 color ptr               +8    (dword)
;                 display row             +12   (db)	;str display loc
;                 display column          +13   (db)
;                 allow 0d/0a in str      +14   (db)	;0=no 1=yes
;                 initial curosr col      +15   (db)
; output: al=0 data in buffer, unknown char in kbuf
;         al=1 data in buffer. mouse click
;
get_edit_string:
  xor	ebx,ebx
  mov	bl,byte [ebp + 15]		;get initial row
  sub	bl,[ebp + 13]			; compute positon of starting cursor

  mov	edi,[ebp]			;get buffer start
  mov	[str_begin],edi			;save entry string start
  add	edi,ebx				;compute initial cursor posn
  mov	[str_ptr],edi			;set initial cursor ptr

  mov	edi,[ebp]			;get buffer start
  add	edi,[ebp +4]
  mov	[str_end],edi			;set entry string end
  mov	ax,[edi]			;get data at end of buffer
  mov	word [char_out],ax		;save temporarily
  mov	word [edi],'  '			;put spaces at end of buffer

  mov	byte [get_string_flg],0		;set first time flag
  mov	al,[ebp +12]			;get row
  mov	[str_cursor_row],al		;save row
  mov	al,[ebp +13]			;get cursor for left edge
  add	al,bl				;move to current positon
  mov	[str_cursor_col],al		;save column
  jmp	gs_10

;-------------------------------------------
;  input:  ebp -> data buffer ptr         +0    (dword) has zero or preload
;                 max string length       +4    (dword) buffer must be bigger
;                 color ptr               +8    (dword)
;                 display row             +12   (db)	;str display loc
;                 display column          +13   (db)
;                 allow 0d/0a in str      +14   (db)	;0=no 1=yes
; output: al=0 data in buffer, unknown char in kbuf
;         al=1 data in buffer. mouse click
;
get_string:
  mov	edi,[ebp]			;get buffer start
  mov	[str_begin],edi			;save entry string start
  mov	[str_ptr],edi			;set initial cursor ptr
  add	edi,[ebp +4]
  mov	[str_end],edi			;set entry string end
  mov	ax,[edi]			;get data at end of buffer
  mov	word [char_out],ax		;save temporarily
  mov	word [edi],'  '			;put spaces at end of buffer

  mov	byte [get_string_flg],0		;set first time flag
  mov	al,[ebp +12]			;get row
  mov	[str_cursor_row],al		;save row
  mov	al,[ebp +13]
  mov	[str_cursor_col],al		;save column
gs_10:
  call	display_get_string
gs_12:
  mov	al,[str_cursor_col]
  mov	ah,[str_cursor_row]
  call	move_cursor			;position cursor
gs_20:
  call	read_stdin
  cmp	byte [kbuf],-1
  jne	gs_20b				;jmp if not mouse click
  mov	al,[str_cursor_row]
  cmp	byte [kbuf + 3],al		;check if mouse click on edit line
  je	gs_20a
  jmp	gs_mouse_exit
gs_20a:				;exit if mouse click elsewhere
  call	position_string_cursor
  jmp	short gs_10
gs_20b:
  call	decode_get_string_key
  jmp	eax
gs_ignore_char:
  jmp	short gs_20
gs_normal_char:
  mov	eax,[str_ptr]
  cmp	eax,[str_end]			;check if room for another char
  je	gs_ignore_char			;jmp if no room
;
; make hole to stuff char
;
  std
  mov	edi,[str_end]
  mov	esi,edi
  inc	edi
gs_21:
  movsb
  cmp	edi,eax				;are we at hole
  jne	gs_21
  cld
  mov	al,[kbuf]			;get char
  mov	byte [edi],al
  mov	edi,[str_end]
  mov	byte [edi+1],0			;zero out any overflow char
gs_23:
  inc	byte [str_cursor_col]		;move cursor fwd
  inc	dword [str_ptr]			;move ptr fwd
  jmp	gs_10
gs_backspace:
  mov	esi,[str_ptr]
  mov	edi,esi
  dec	edi
  cmp	esi,[str_begin]
  je	gs_10				;ignore operation if at beginning
gs_24:
  movsb
  cmp	edi,[str_end]
  jne	gs_24
gs_25:
  dec	byte [str_cursor_col]
  dec	dword [str_ptr]
  jmp	gs_10
gs_home:
gs_end:
  jmp	gs_10				;ignore home/end for now
gs_right:
  mov	eax,[str_ptr]
  inc	eax
  cmp	eax,[str_end]
  jae	gs_end				;jmp if at right edge already
  inc	byte [str_cursor_col]		;move cursor fwd
  inc	dword [str_ptr]			;move ptr fwd
  jmp	gs_12
gs_left:
  mov	eax,[str_ptr]
  cmp	eax,[str_begin]
  je	gs_home				;jmp if at left edge already
  dec	byte [str_cursor_col]
  dec	dword [str_ptr]
  jmp	gs_12
gs_del:
  mov	esi,[str_ptr]
  mov	edi,esi
  inc	esi
gs_27:
  movsb
  cmp	edi,[str_end]
  jne	gs_27
  jmp	gs_10

gs_passkey_done:
  mov	al,0
  jmp	short gs_exit
gs_mouse_exit:
  mov	al,1
gs_exit:
  mov	bx,[char_out]		;restore data at end of string
  mov	edi,[str_end]		;  buffer that was clobbered
  mov	word [edi],bx
  ret
;----------------------------------------------
; set str_cursor_row str_cursor_col to click location
;
position_string_cursor:
  mov	al,byte [kbuf + 2]	;get click location
  mov	bh,[ebp +13]		;get left edge
  mov	bl,bh
  add	bl,[ebp + 4]		;compute right edge
psc_loop:
  mov	ah,[str_cursor_col]
  cmp	al,ah
  jb	psc_go_left
  ja	psc_go_right
  jmp	psc_done
psc_go_left:
  cmp	al,bh			;are we at left edge yet
  je	psc_done
  dec	byte [str_cursor_col]
  dec	dword [str_ptr]
  jmp	psc_loop
psc_go_right:
  cmp	al,bl
  je	psc_done
  inc	byte [str_cursor_col]
  inc	dword [str_ptr]
  jmp	psc_loop
psc_done:  
  ret
;----------------------------------------------
;  input:  ebp -> data buffer ptr         +0    (dword)  has zero or preload
;                 max string length       +4    (dword)
;                 color ptr               +8    (dword)
;                 display row             +12   (db)	;str display loc
;                 display column          +13   (db)
display_get_string:
  mov	edi,lib_buf
  mov	esi,[ebp]		;get buffer to display
  mov	ecx,[ebp +4]		;get max string length
;
; build string in lib_buf buffer
;
dgs_10:
  cmp	byte [esi],0		;end of data found
  je	dgs_30			;jmp if at end of preloaded data
  lodsb
  jmp	short dsg_40		;go store data
dgs_30:
  mov	al,' '			;store blank
dsg_40:
  stosb
  dec	ecx
  jnz	dgs_10			;loop till done
  mov	byte [edi],0		;terminate string
;
; display string area
;  
  mov	eax,[ebp +8]		;get color ptr
  mov	eax,[eax]		;get color
  mov	bh,[ebp + 12]		;get row
  mov	bl,[ebp + 13]		;display column
  mov	ecx,lib_buf		;get msg address
  call	crt_color_at	;display message
  ret
;------------------------------------
;  input:  kbuf - has last character typed
;  output: eax - pointer to process for character typed
;
decode_get_string_key:
  cmp	byte [kbuf+1],0
  jne	dgsk_20			;jmp if special key
  mov	al,[kbuf]		;get key
  cmp	al,20h
  jb	dgsk_20			;jmp if special key
  cmp	al,7fh
  je	dgsk_60			;jmp if backspace
  ja	dgsk_20			;jmp if non-alpha key
  mov	eax,gs_normal_char
  jmp	short dgsk_exit
;
; decode special char in range 0 - 1fh
;
dgsk_20:
  mov	esi,gs_decode_table
dgsk_22:
  mov	edi,kbuf
  mov	al,byte [edi]		;get kbuf entry
  cmp	al,byte [esi]		;compare to keystring
  je	dgsk_30			;initial char. match
dgsk_24:
  inc	esi
dgsk_26:
  cmp	byte [esi],0		;end of tbl entry
  jne	dgsk_24			;loop if not end of tbl str
  add	esi,5			;move to next entry
  cmp	byte [esi],0		;check if end of table
  jne	dgsk_22			;jmp if more strings
  jmp	dgsk_50			;jmp to ignore this char
;
; we have a match
;
dgsk_30:
  inc	esi
  inc	edi
  mov	al,byte [edi]		;get next kbuf entry
  cmp	byte [esi],al		;match?
  jne	dgsk_26			;jmp if no match
  cmp	al,0			;end of kbuf string
  je	dgsk_40			;jmp if match at zero in both
  cmp	byte [esi],0		;end of table string
  jne	dgsk_30			;keep comparing if more data

dgsk_40:
  inc	esi			;move to process address
  mov	eax,[esi]		;get process
  jmp	short dgsk_exit
dgsk_50:
  mov	eax,gs_ignore_char
  jmp	short dgsk_exit
dgsk_60:
  mov	eax,gs_backspace
dgsk_exit:
  ret
;-----------------------------------------
; get prompted string or mouse event
;  input:  ebp -> prompt message ptr       +0 (dword)
;                 prompt message color ptr +4 (dword)
;                 data buffer ptr          +8 (dword)   has zero or preload
;                 max string length       +12 (dword)
;                 color ptr               +16 (dword)
;                 display row             +20 (db)       prompt row
;                 display column          +21 (db)
;                 allow 0d/0a in str      +22 (db)	;0=no 1=yes
; output: al=0 data in buffer, terminator char in kbuf
;         al=1 data in buffer. next command in kbuf
;         al=2 abort (ctrl-c) typed
;
get_prompted_string:
  mov	edi,lib_buf		;setup to clear line
  xor	ecx,ecx
  mov	cl,[crt_columns]	;get length of line
  mov	al,' '
gps_10:
  stosb
  loop	gps_10
  mov	byte [edi],0		;terminate blank line
;
; blank line used to display string
;
  mov	eax,[ebp +4]		;get color ptr
  mov	eax,[eax]		;get color
  mov	bh,[ebp + 20]		;get row
  mov	bl,1			;display from column 1
  mov	ecx,lib_buf		;get msg address
  call	crt_color_at	;display message
;
; display prompt message
;
  mov	eax,[ebp +4]		;get color ptr
  mov	eax,[eax]		;get color
  mov	bh,[ebp + 20]		;get row
  mov	bl,[ebp + 21]		;display column
  mov	ecx,[ebp]		;get msg address
  call	crt_color_at	;display message
;
; compute ending column of displayed message
;
  xor	ecx,ecx
  mov	cl,[ebp + 21]		;get display column
  mov	esi,[ebp]		;get message pointer
gps_20:
  lodsb
  or	al,al
  jz	gps_30			;jmp if end of message
  inc	ecx
  jmp	short gps_20		;keep counting
gps_30:
;
; adjust display column to point at string input area
;
  add	[ebp + 21],cl
  add	ebp,8			;setup data ptr for get_string
  call	get_string
  ret

 [section .data]

;-----------------------------------------------------------

string_buffer  times 20 db 0

get_string_flg	db	0	;set each time get_string entered
str_cursor_row	db	0	;current cursor row
str_cursor_col	db	0	;current cursor column

str_begin	dd	0	;start of string
str_ptr		dd	0	;current string edit point
str_end		dd	0	;max string ptr
;----------------------------------------------
gs_decode_table:
  db 1bh,0			;1 esc
     dd gs_passkey_done
  db 1bh,5bh,31h,31h,7eh,0	;2 f1
   dd gs_passkey_done
  db 1bh,5bh,31h,32h,7eh,0	;3 f2
   dd gs_passkey_done
  db 1bh,5bh,31h,33h,7eh,0	;4 f3
   dd gs_passkey_done
  db 1bh,5bh,31h,34h,7eh,0	;5 f4
   dd gs_passkey_done
  db 1bh,5bh,31h,35h,7eh,0	;6 f5
   dd gs_passkey_done
  db 1bh,5bh,31h,37h,7eh,0	;7 f6
   dd gs_passkey_done
  db 1bh,5bh,31h,38h,7eh,0	;8 f7
   dd gs_passkey_done
  db 1bh,5bh,31h,39h,7eh,0	;9 f8
   dd gs_passkey_done
  db 1bh,5bh,32h,30h,7eh,0	;10 f9
   dd gs_passkey_done
  db 1bh,5bh,32h,31h,7eh,0	;11 f10
   dd gs_passkey_done
  db 1bh,5bh,32h,33h,7eh,0	;12 f11
   dd gs_passkey_done
  db 1bh,5bh,32h,34h,7eh,0	;13 f12
   dd gs_passkey_done

 db 1bh,5bh,48h,0		;14 pad_home
   dd gs_home
  db 1bh,4fh,48h,0		;14 pad_home
   dd gs_home
  db 1bh,4fh,77h,0		;14 pad_home
   dd gs_home

 db 1bh,5bh,41h,0		;15 pad_up
   dd gs_passkey_done
 db 1bh,4fh,41h,0		;15 pad_up
   dd gs_passkey_done
 db 1bh,4fh,78h,0		;15 pad_up
   dd gs_passkey_done

  db 1bh,5bh,35h,7eh,0		;16 pad_pgup
   dd gs_passkey_done
  db 1bh,4fh,79h,0		;16 pad_pgup
   dd gs_passkey_done

  db 1bh,5bh,44h,0		;17 pad_left
   dd gs_left
  db 1bh,4fh,44h,0		;17 pad_left
   dd gs_left
  db 1bh,4fh,74h,0		;17 pad_left
   dd gs_left

  db 1bh,5bh,43h,0		;18 pad_right
   dd gs_right
  db 1bh,4fh,43h,0		;18 pad_right
   dd gs_right
  db 1bh,4fh,76h,0		;18 pad_right
   dd gs_right

  db 1bh,5bh,46h,0		;19 pad_end
   dd gs_end
  db 1bh,4fh,46h,0		;19 pad_end
   dd gs_end
  db 1bh,4fh,71h,0		;19 pad_end
   dd gs_end

  db 1bh,5bh,42h,0		;20 pad_down
   dd gs_passkey_done
  db 1bh,4fh,42h,0		;20 pad_down
   dd gs_passkey_done
  db 1bh,4fh,72h,0		;20 pad_down
   dd gs_passkey_done

  db 1bh,5bh,36h,7eh,0		;21 pad_pgdn
   dd gs_passkey_done
  db 1bh,4fh,79h,0		;21 pad_pgdn
   dd gs_passkey_done

  db 1bh,5bh,32h,7eh,0		;22 pad_ins
   dd gs_passkey_done
  db 1bh,4fh,70h,0		;22 pad_ins
   dd gs_passkey_done

  db 1bh,5bh,33h,7eh,0		;23 pad_del
   dd gs_del
  db 1bh,4fh,6eh,0		;23 pad_del
   dd gs_del
  db 0dh,0		;90  enter 
   dd gs_passkey_done
; the above are vt100, next is xterm unique keys
  db 1bh,4fh,50h,0		;123 F1
   dd gs_passkey_done
  db 1bh,4fh,51h,0		;123 F2
   dd gs_passkey_done
  db 1bh,4fh,52h,0		;123 F3
   dd gs_passkey_done
  db 1bh,4fh,53h,0		;123 F4
   dd gs_passkey_done
;the above are xterm unique, next is linux-console unique
  db 1bh,5bh,5bh,41h,0		;127 F1
   dd gs_passkey_done
  db 1bh,5bh,5bh,42h,0		;128 f2
   dd gs_passkey_done
  db 1bh,5bh,5bh,43h,0		;129 f3
   dd gs_passkey_done
  db 1bh,5bh,5bh,44h,0		;130 f4
   dd gs_passkey_done
  db 1bh,5bh,5bh,45h,0		;131 f5
   dd gs_passkey_done
  db 0ah,0			;132 enter
   dd gs_passkey_done

  db 1bh,79h,0			;alt-y
  dd gs_passkey_done

  db 1bh,6dh,0			;alt-m
  dd gs_passkey_done

  db 1bh,64h,0			;alt-d
  dd gs_passkey_done

  db 1bh,73h,0			;alt-s
  dd gs_passkey_done

  db 1bh,59h,0			;alt-Y
  dd gs_passkey_done

  db 1bh,4dh,0			;alt-M
  dd gs_passkey_done

  db 1bh,44h,0			;alt-D
  dd gs_passkey_done

  db 1bh,53h,0			;alt-S
  dd gs_passkey_done

  db 0f9h,0			;alt-y
  dd gs_passkey_done

  db 0edh,0			;alt-m
  dd gs_passkey_done

  db 0e4h,0			;alt-d
  dd gs_passkey_done

  db 0f3h,0			;alt-s
  dd gs_passkey_done

  db 0d9h,0			;alt-Y
  dd gs_passkey_done

  db 0cdh,0			;alt-M
  dd gs_passkey_done

  db 0c4h,0			;alt-D
  dd gs_passkey_done

  db 0d3h,0			;alt-S
  dd gs_passkey_done

  db 0		;end of table


char_out	db	0,0,0	;used by get_string


;---------------------------------------------------------
;  edit data
;---------------------------------------------------------


edit_mode		db	0	;0=redisplay loop 1=no redisplay
                                        ;2=exit edit - normal exit, save todo
                                        ;3=delete todo
                                        ;4=previous todo (save any edits)
                                        ;5=next todo (save any edits)
                                        ;6=abandon edits

current_edit_todo	dd	0	;pointer to current todo

edit_click_button	db	0	;
edit_click_row		db	0	;could be anywhere in edit screen
edit_click_column	db	0

edit_text_ptr		dd	edit_line1	;pointer to text cursor in edit_table

selected_state_ptr	dd	pending
selected_sched_text	db	'Y1'	;current schedule code
selected_sched_ptr	dd	schedule_once	;points to table entry for sched text
selected_year_ptr	dd	years
selected_month_ptr	dd	months
selected_day_ptr	dd	days1


edit_process_table:
  dd	edit_pending		;-1
  dd	edit_complete		;-2
  dd	edit_deleted_status	;3
  dd	edit_year1		;4
  dd	edit_year2		;5
  dd	edit_year3		;6
  dd	edit_month_01		;7
  dd	edit_month_02		;8
  dd	edit_month_03		;9
  dd	edit_month_04		;10
  dd	edit_month_05		;11
  dd	edit_month_06		;12
  dd	edit_month_07		;13
  dd	edit_month_08		;14
  dd	edit_month_09		;15
  dd	edit_month_10		;16
  dd	edit_month_11		;17
  dd	edit_month_12		;18
  dd	edit_day_01		;19
  dd	edit_day_02		;20
  dd	edit_day_03		;21
  dd	edit_day_04		;22
  dd	edit_day_05		;23
  dd	edit_day_06		;24
  dd	edit_day_07		;25
  dd	edit_day_08		;26
  dd	edit_day_09		;27
  dd	edit_day_10		;28
  dd	edit_day_11		;29
  dd	edit_day_12		;30
  dd	edit_day_13		;31
  dd	edit_day_14		;32
  dd	edit_day_15		;33
  dd	edit_day_16		;34
  dd	edit_day_17		;35
  dd	edit_day_18		;36
  dd	edit_day_19		;37
  dd	edit_day_20		;38
  dd	edit_day_21		;39
  dd	edit_day_22		;40
  dd	edit_day_23		;41
  dd	edit_day_24		;42
  dd	edit_day_25		;43
  dd	edit_day_26		;44
  dd	edit_day_27		;45
  dd	edit_day_28		;46
  dd	edit_day_29		;47
  dd	edit_day_30		;48
  dd	edit_day_31		;49
  dd	edit_sched_once		;50
  dd	edit_sched_daily	;51
  dd	edit_sched_eom		;52
  dd	edit_sched_wk1		;53
  dd	edit_sched_wk2		;54
  dd	edit_sched_wk3		;55
  dd	edit_sched_wk4		;56
  dd	edit_sched_m1		;57
  dd	edit_sched_m2		;58
  dd	edit_sched_m3		;59
  dd	edit_sched_m4		;60
  dd	edit_sched_m6		;61
  dd	edit_sched_y1		;62
  dd	edit_sched_y2		;63
  dd	edit_sched_y3		;64

  dd	edit_del_button		;65
  dd	edit_done_button	;66
  dd	edit_abort      	;67		;discard edits and abort

  dd	edit_text_line1		;68
  dd	edit_text_line2		;69
  dd	edit_text_line3		;70
  dd	edit_text_line4		;71
  dd	edit_text_line5		;72

  dd	edit_previous		;73 		;exit and request previous todo
  dd	edit_next		;74		;exit and request next todo

; table used to display edit screen.
;  codes:  0 - end of table
;          1 - normal color
;          2 - edit/select field
;          3 - active edit/select field
;          4 - button color
;          5 - blank all rows from here to [window_rows]
;          9 - add blanks to end of line, init for next line
;         -x - process code for mouse clicks
;
 db -67			;trap to catch clicks at upper left corner of screen
edit_table:
 db 1,'  ',-73,4,'Previous(PgUp)',1,'  ',-74,4,'Next(PgDn)',1,'  ',-65,4,'Delete(F8)',1,'  ',-67,4,'Abort edits(F9)',1,'  ',-66,4,'Done(F10)',1,9
 db 1,9
 db 1,'todo state:   ',-1,2
pending:
 db 'Pending',1,'   ',-2,2
completed:
 db 'completed',1,'   ',-3,2
deleted:
 db 'deleted',1,9
 db 1,9
 db 1,'date:  year:  ',-4,2
years:
tyear:
 db '2003',1,' ',-5,2
years2: 
 db '2004',1,' ',-6,2
years3:
 db '2005',1,9
 db 1,'       Month: ',-7,2
months:
 db '01',1,' ',-8,2,'02',1,' ',-9,2,'03',1,' ',-10,2,'04',1,' ',-11,2,'05',1,' ',-12,2,'06',1,' ',-13,2,'07',1,' ',-14,2,'08',1,' ',-15,2,'09',1,' ',-16,2,'10',1,' ',-17,2,'11',1,' ',-18,2,'12',1,9
 db 1,'       Day:   ',-19,2
days1:
 db '01',1,' ',-20,2,'02',1,' ',-21,2,'03',1,' ',-22,2,'04',1,' ',-23,2,'05',1,' ',-24,2,'06',1,' ',-25,2,'07',1,' ',-26,2,'08',1,' ',-27,2,'09',1,' ',-28,2,'10',1,' ',-29,2,'11',1,' ',-30,2,'12',1,' ',-31,2,'13',1,' ',-32,2,'14',1,' ',-33,2,'15',1,9
 db 1,'              ',-34,2
days2:
 db '16',1,' ',-35,2,'17',1,' ',-36,2,'18',1,' ',-37,2,'19',1,' ',-38,2,'20',1,' ',-39,2,'21',1,' ',-40,2,'22',1,' ',-41,2,'23',1,' ',-42,2,'24',1,' ',-43,2,'25',1,' ',-44,2,'26',1,' ',-45,2,'27',1,' ',-46,2,'28',1,' ',-47,2
day29:
 db '29',1,' ',-48,2
day30:
 db '30',1,' ',-49,2
day31:
 db '31',1,9
 db 1,9
 db 1,'Schedule:  ',-50,2
schedule_once:
 db 'once',1,'     ',-51,2
schedule_daily:
 db 'daily',1,'   ',-52,2
schedule_eom:
 db 'at EOM',1,9
 db 1,'           every:   ',-53,2
schedule_wk1:
 db 'weekly',1,'  ',-54,2
schedule_wk2:
 db '2 weeks',1,'    ',-55,2
schedule_wk3:
 db '3 weeks',1,'   ',-56,2
schedule_wk4:
 db '4 weeks',1,9 
 db 1,'           every:   ',-57,2
schedule_m1:
 db 'month',1,'   ',-58,2
schedule_m2:
 db '2 months',1,'   ',-59,2
schedule_m3:
 db '3 months',1,'  ',-60,2
schedule_m4:
 db '4 months',1,'  ',-61,2
schedule_m6:
 db '6 months',1,9
 db 1,'           every:   ',-62,2
schedule_y1:
 db 'yearly',1,'  ',-63,2
schedule_y2:
 db '2 years',1,'    ',-64,2
schedule_y3:
 db '3 years',1,9
 db 1,9

 db    1,'  ',-68,4				;temp;;; use button color for text area
edit_line1:
 times default_text_field_len db ('*')
 db	1,9
 db    1,'  ',-69,4
edit_line2:
 times default_text_field_len db ('*')
 db	1,9
 db    1,'  ',-70,4
edit_line3:
 times default_text_field_len db ('*')
 db	1,9
 db    1,'  ',-71,4
edit_line4:
 times default_text_field_len db ('*')
 db	1,9
 db    1,'  ',-72,4
edit_line5:
 times default_text_field_len db ('*')
 db	1,9
 db	1,9
 db	1,9
 db 'keyboard: alt(y) = inc year  alt(Y) = dec year',9
 db '          alt(m) = inc month alt(M) = dec month',9
 db '          alt(d) = inc day   alt(D) = dec  day',9
 db '          alt(s) = inc sched alt(S) = dec  sched',9
 db 5
 db 0
edit_table_end:

 [section .text]


