;-------------file: sbug_windows.inc --------------------------------
extern dis_block
;----------------------------------------------------------
stack_window:
  mov	eax,[aux_win_color]
  call	crt_set_color

  mov	al,[bottom_screen+screen.top] ;get row
  mov	[stack_row],al

  mov	eax,[app_esp]
  mov	[stack_adr],eax

stack_lp:
  mov	ah,[stack_row]
  mov	al,[reg_win_start_col]
  call	move_cursor

  mov	edx,[stack_adr]
  mov	esi,stack_buf
  call	trace_peek		;read dword of data

  mov	edi,lib_buf+100		;line build area
  mov	eax,[stack_adr]		;get mem address
  call	dwordto_hexascii
  mov	al,'='
  stosb
  mov	eax,[stack_buf]		;get data
  call	dwordto_hexascii	;show mem contents

;pad line to end with blanks
  mov	ebx,lib_buf+100	;get buffer start
  add	ebx,24
stack_pad_lp:
  cmp	ebx,edi
  jbe	stack_pad_done
  mov	al,' '
  stosb
  jmp	stack_pad_lp
stack_pad_done:

  call	write_aux_line

  add	[stack_adr],byte 4
  mov	al,[stack_row]
  inc	al
  cmp	al,[menu_line]
  je	stack_done
  mov	[stack_row],al
  jmp	stack_lp
stack_done: 
  ret
;--------
  [section .data]
stack_row	dd	0
stack_buf	dd	0
stack_adr	dd	0	;address in app memory
  [section .text]
  ret
;----------------------------------------------------------
break_window:
  mov	[found_break_flag],byte 0
  mov	eax,[aux_win_color]
  call	crt_set_color

  mov	al,[bottom_screen+screen.top] ;get row
  mov	[brk_row],al
  mov	esi,breaks	;get ptr to breaks
bw_lp:
  mov	edi,lib_buf+100	;get build area
  lodsd			;get break
  inc	esi		;move past save byte
  push	esi
  or	eax,eax
  jz	bw_pad
  call	dwordto_hexascii
  mov	[found_break_flag],byte 1
bw_pad:
;pad line to end with blanks
  mov	ebx,lib_buf+100	;get buffer start
  add	ebx,24
brk_pad_lp:
  cmp	ebx,edi
  jbe	brk_pad_done
  mov	al,' '
  stosb
  jmp	brk_pad_lp
brk_pad_done:
  mov	ah,[brk_row]
  mov	al,[reg_win_start_col]
  call	move_cursor

  call	write_aux_line

  inc	dword [brk_row]
  pop	esi
  mov	al,[brk_row]
  cmp	al,[menu_line]
  jb	bw_lp
;check if any breaks found
  cmp	byte [found_break_flag],0
  jnz	bw_exit		;jmp if breaks found
;no breaks, show message
  mov	ah,[brk_row]
  sub	ah,4
  mov	al,[reg_win_start_col]
  call	move_cursor
  mov	ecx,no_breaks_msg
  mov	edx,no_breaks_msg_len
  call	crt_write
bw_exit:
  ret
;-----------------
  [section .data]
brk_row: db 0
found_break_flag:	db 0	;0=no breaks found
no_breaks_msg: db ' no breaks set'
no_breaks_msg_len  equ $ - no_breaks_msg
  [section .text]

;----------------------------------------------------------
; mem win format address dword 'ascii'
;                ---8---1--8--1--6----
;
mem_window:
  mov	eax,[aux_win_color]
  call	crt_set_color

  mov	al,[bottom_screen+screen.top] ;get row
  mov	[mem_row],al

  mov	edx,[mem_top_adr]
  mov	[mem_adr],edx		;set starting adr

mem_lp:
  mov	ah,[mem_row]
  mov	al,[reg_win_start_col]
  call	move_cursor

  mov	edx,[mem_adr]
  mov	esi,mem_buf
  call	trace_peek		;read dword of data

  mov	edi,lib_buf+100		;line build area
  mov	eax,[mem_adr]		;get mem address
  call	dwordto_hexascii
  mov	al,'='
  stosb
  mov	eax,[mem_buf]		;get data
  call	dwordto_hexascii	;show mem contents
;append ascii to tail
  mov	al,' '
  stosb
  mov	al,22h
  stosb				;put quote around ascii
  mov	esi,mem_buf		;get data ptr
  mov	ecx,4
ma_loop:
  lodsb				;get char
  call	is_alpha
  je	mem_ascii
  mov	al,' '
mem_ascii:
  stosb
  loop	ma_loop
  mov	al,22h
  stosb				;add ending quote
  call	write_aux_line

  add	[mem_adr],byte 4
  mov	al,[mem_row]
  inc	al
  cmp	al,[menu_line]
  je	ml_done
  mov	[mem_row],al
  jmp	mem_lp
ml_done:
 
  ret
;--------
  [section .data]
mem_top_adr dd	0
mem_row	dd	0
mem_buf dd	0
mem_adr	dd	0	;address in app memory
  [section .text]
;----------------------------------------------------------
reg_window:
  mov	eax,[aux_win_color]
  call	crt_set_color
  mov	ebx,reg_tbl
  mov	al,[bottom_screen+screen.top] ;get row
  mov	[reg_row],al

sr_lp:
  mov	edi,lib_buf+100
  mov	eax,[ebx]	;get reg text ptr
  stosd			;move reg name
  add	ebx,4		;move to reg value ptr

  cmp	dword [ebx],0
  je	sr_status

  mov	esi,[ebx]	;get reg ptr
  lodsd			;get reg value
  push	ebx
  call	dwordto_hexascii

  mov	ah,[reg_row]
  mov	al,[reg_win_start_col]
  call	move_cursor

  call	write_aux_line
  pop	ebx

  inc	byte [reg_row]
  add	ebx,4
  jmp	sr_lp

sr_status:  
;display flags
  mov	esi,flag_letters	;upper case letters
  mov	ebx,[app_flags]
  shl	ebx,20			;position flag start
  mov	ecx,12			;loop counter
sr_60:
  lodsb			;get next letter
  rol	ebx,1
  jc	sr_70
  or	al,20h		;unset (to lower case)
sr_70:
  cmp	al,20h
  je	sr_80		;skip unused flag positions
  stosb
sr_80:
  loop	sr_60
;write flag data
  mov	ah,[reg_row]
  mov	al,[reg_win_start_col]
  call	move_cursor

  call	write_aux_line

sr_exit:
  ret


;---------------
  [section .data]
 align 4

reg_row: dd 0	;current display row

reg_tbl:
  db 'EAX='
  dd app_eax
  db 'EBX='
  dd app_ebx
  db 'ECX='
  dd app_ecx
  db 'EDX='
  dd app_edx
  db 'ESI='
  dd app_esi
  db 'EDI='
  dd app_edi
  db 'EBP='
  dd app_ebp
  db 'ESP='
  dd app_esp
  db 'EIP='
  dd app_eip
  db 'FLG='
  dd 0


flag_letters: db 'ODITSZ A P C'
flag_build:   db '            '


  [section .text]
;----------------------------------------------------------
write_aux_line:
  mov	al,' '
wal_pad_lp:
  cmp	edi,lib_buf+100+24
  ja	wal_write
  stosb
  jmp	short wal_pad_lp
wal_write:
  mov	ecx,lib_buf+100
  sub	edi,lib_buf+100	;compute length
  mov	edx,edi
  call	crt_write
  ret
;----------------------------------------------------------
dis_window:
  mov	eax,[dis_win_top]		;get data
  mov	[dis_adr],eax		;save starting eip
  mov	[dis_loop_count],dword 10

  mov	al,[bottom_screen+screen.top] ;get row
  mov	[dis_display_row],al

  mov	edx,[dis_adr]		;address of inst
  mov	esi,dis_raw_inst	;buffer
  mov	[dis_buf_ptr],esi	;save buffer start
  mov	edi,100			;read 100 bytes
  call	trace_peek_bytes

  mov	eax,dis_win_array
  mov	[dis_win_array_ptr],eax
dw_loop:
  call	set_background_color
  mov	edi,lib_buf+100

;eax=physical address, put in buf
  mov	eax,[dis_adr]
  mov	ebx,[dis_win_array_ptr]
  mov	[ebx],eax
  add	[dis_win_array_ptr],dword 4
  call	dwordto_hexascii

  push	edi
  mov	edi,dis_adr	;move physical address to edi
  mov	ecx,4
  xor	edx,edx		;use hash
  call	hash_lookup
  pop	edi
  or	eax,eax
  jnz	dw_label_end	;jmp if no label
;esi points to symbol name
  mov	al,' '
  stosb			;put space infront of label
  add	esi,byte 5
  call	str_move
  mov	ax,': '
  stosw
  jmp	short dw_dis
dw_label_end:
  mov	al,' '		;put extra space if no label
  stosb
dw_dis:
;check if inst. or data 
  mov	eax,[dis_adr]
  mov	edx,eax		;save data ptr
  call	adr2map
  jnc	dw_10		;jmp if within map
  cmp	edx,[app_eip]
  je	dw_inst		;if eip then force dis
  jmp	short dw_data
dw_10:
  test	[eax],byte 22h	;inst start?
  jnz	dw_inst		;jmp if instruction
;show db
dw_data:
  mov	eax,' db '
  stosd
  mov	edx,[dis_buf_ptr]
  mov	al,[edx]	;get byte
  call	byteto_hexascii
  mov	al,'h'
  stosb
  mov	eax,dis_block	;force inst length
  mov	[eax + Dis.inst_len],byte 1
  add	edi,byte 2	;pre bump for padding
  jmp	short dw_pad
;do dis and stuff inst
dw_inst:
  push	edi
  mov	eax,[dis_adr]
  mov	ebp,[dis_buf_ptr]
  call	dis_one			;eax=phys adr, ebp=code ptr our=eax
  pop	edi
;move dis data to lib_buf
  lea	esi,[eax+Dis.inst_+1]	;get address of inst ascii
  mov	al,' '
  stosb
  call	inst_move
;pad line to end with blanks
dw_pad:
  mov	ebx,lib_buf+100	;get buffer start (past color)
  add	ebx,[dis_win_end_col]	;compute end of window
  dec	edi			;move back to tab at end of inst
  dec	edi			;move back to tab at end of inst
dis_pad_lp:
  cmp	ebx,edi
  jbe	dis_show
  mov	al,' '
  stosb			;add pad char.
  jmp	dis_pad_lp

dis_show:

;display line
  call	show_line
  call	set_foreground_color
;adjust dis_buf_ptr
  mov	eax,dis_block
  xor	ecx,ecx
  mov	cl,[eax + Dis.inst_len] ;get inst length
  add	[dis_buf_ptr],ecx	;compute next inst
  add	[dis_adr],ecx		;save next inst adr
  inc	dword [dis_display_row] ;bump row
  dec	dword [dis_loop_count]  ;bump loop count
  jnz	dw_loop			;loop till done
  and	[app_mode],byte ~10h	;turn display off
  ret
;------------
  [section .data]
dis_win_top: dd 0	;address at top of win
dis_adr dd 0		;addr of raw inst in app mem
dis_buf_ptr dd 0	;ptr to raw inst
dis_loop_count dd 0
dis_raw_inst:	times 100 db 0
dis_display_row: dd 0

dis_win_array:	times 11 dd 0	;address in dis win
dis_win_array_ptr: dd 0
  [section .text]
;-----------------------------------------------------------------
;move ascii string and expand tab if found
;input: esi=from  edi=to
inst_move:
  lodsb
  cmp	al,9		;tab?
  jne	im_20
tab_lp:
  mov	al,' '
  stosb
  cmp	edi,lib_buf+100+16
  jb	tab_lp
im_20:
  stosb
  or	al,al
  jnz	inst_move
  ret
;-----------------------------------------------------------------
; input: lib_buf+100 has data, edi=end ptr
show_line:
  mov	ah,[dis_display_row]
  mov	al,1
  call	move_cursor

  sub	edi,lib_buf+100		;compute length of line
  mov	edx,edi
  mov	ecx,lib_buf+100
  call	crt_write
  ret
;-------------------------------------------------------------
;called by dis_one when possible symbol encountered
; input: edi = physical address or operand value
; output: eax = 0 if symbol found  esi=string ptr
;
symbol_handler:
  push	ebp
;this label could be a dynamic symbol that fails range
;or map test, check symbol table first
  mov	[label_adr],edi
  mov	edi,label_adr	;move physical address to edi
  mov	ecx,4
  xor	edx,edx		;use hash
  call	hash_lookup
  or	esi,esi
  jz	sh_exit		;jmp if no sym tbl entry
  add	esi,5
  xor	eax,eax		;signal that label was found
sh_exit:
  pop	ebp
  ret
;-----------
  [section .data]
label_adr: dd 0
  [section .text]
;----------------------------------------------------------
; input:  [dis_adr] address of current line
;         [select_line#] line# for select ptr
;    dis_win_color: dd 30003734h
;    dis_win_break_color: dd 30003732h
set_foreground_color:
;check if any breaks here
  mov	esi,breaks
  mov	eax,[dis_adr]
  mov	ecx,10		;max loop size
sfc_lp:
  cmp	[esi],eax
  je	sfc_found
  add	esi,5
  loop	sfc_lp
  jmp	short sfc_check
sfc_found:
  mov	eax,[dis_win_break_color]
  and	eax,~0ffh	;remove foreground
  mov	ebx,[background_color]
  and	ebx,0ffh	;isolate background color
  or	eax,ebx		;insert default background
  call	crt_set_color
  mov	ah,[dis_display_row]
  mov	al,1
  call	move_cursor

  mov	edx,8			;length of line
  mov	ecx,lib_buf+100
  call	crt_write
;check if select here
sfc_check:
  mov	bl,[dis_display_row]
  cmp	bl,[select_line#]
  jne	sfc_exit	;jmp if no select line here
  mov	eax,[dis_win_select_color]
  and	eax,~0ffh	;remove foreground
  mov	ebx,[background_color]
  and	ebx,0ffh	;isolate background color
  or	eax,ebx		;insert default background
  call	crt_set_color
  mov	ah,[dis_display_row]
  mov	al,9
  call	move_cursor
  add	edx,[dis_win_end_col]	;get end of window
  sub	edx,byte 9		;length of line
  mov	ecx,lib_buf+100+8
  call	crt_write
sfc_exit:
  ret
;----
  [section .data]
select_line#:	db	0
  [section .txt]
;----------------------------------------------------------
; input:  [dis_adr] address of current line
;         [app_eip] instruction ptr
;         [select_line#] line# for select ptr
;    dis_win_color: dd 30003734h
;    dis_win_eip_color: dd 30003732h
;    dis_win_select_color: dd 30003637h
set_background_color:
  mov	eax,[dis_win_eip_color]
  mov	ebx,[dis_adr]
  cmp	ebx,[app_eip]
  je	sbc_select
  mov	eax,[dis_win_color]
sbc_select:
  mov	[background_color],eax	;save color
  call	crt_set_color
  ret
;----
  [section .data]
background_color: dd 0
  [section .txt]
;----------------------------------------------------------
;keep eip inside window
eip_tracking:
  cmp	[eip_track_flag],byte 0
  je	eip_exit		;exit if no tracking
  mov	[eip_track_flag],byte 0
  mov	eax,[app_eip]
  cmp	eax,[dis_win_array]	;check top of window
  jb	fix_win_top
  cmp	eax,[dis_win_array + (4*9)] ;check win bottom
  jbe	eip_exit		;jmp if ok
fix_win_top:
  mov	[dis_win_top],eax
eip_exit:  
  ret
;-------------
  [section .data]
eip_track_flag db 0
  [section .text]
;----------------------------------------------------------
show_menu_line:
  mov	ah,[menu_line]	;row
  mov	al,1		;column
  call	move_cursor

  mov	eax,[menu_color]
  call	crt_set_color

  mov	esi,menu_txt
  mov	edi,lib_buf
  call	str_move

  mov	ebx,[crt_columns]
  add	ebx,lib_buf	;compute end of text

  mov	al,' '
ml_lp:
  cmp	edi,ebx
  ja	ml_check
  stosb
  jmp	short ml_lp
ml_check:
  mov	edi,ebx		;truncate line if too long
ml_show:
  mov	edx,edi
  sub	edx,lib_buf	;compute length of line
  mov	ecx,lib_buf
  call	crt_write
  ret
;-------------
  [section .data]
menu_txt:
 db ' Go Step brk-At Clr-brk Help Quit  (show)-> Regs Mem Esp Brk',0
  [section .text]  
;-----------------------------------------------------------------------
;add message to last line of display
; input:  [append_msg_ptr] = byte 1 flag 0=one time  bit1=hold bit2=set dead
;                            byte 2+ asciiz message
append_to_dis:
  mov	ecx,[append_msg_ptr]
  jecxz	atd_exit	;jmp if no append msg
  push	ecx

  mov	al,1
  mov	ah,[bs_bottom_row]
  call	move_cursor

  mov	eax,[dis_win_alert_color]
  call	crt_set_color

  pop	ecx
  dec	ecx		;get message start
  call	crt_str

  dec	ecx	;move back to flag
  test	[ecx],byte 2	;app dead
  jz	atd_10		;jmp if app still alive
  or	[app_mode],byte 2	;set dead flag
atd_10:
  test	[ecx],byte 1
  jnz	atd_exit	;jmp if hold message
  xor	eax,eax
  mov	[append_msg_ptr],eax ;clear msg ptr
atd_exit:  
  ret
;-----------
  [section .data]
append_msg_ptr: dd 0
  [section .text]

;-----------------------------------------------------------------------
shrink_window:
;set scroll region
  mov	ax,[ts_top_rowa]	;set
  mov	[sr_top],ax		; scroll
  mov	ax,[ts_bottom_rowa]	;  region
  mov	[sr_end],ax
  mov	ecx,scroll_region
  call	crt_str			;set scroll region
;set screen size
  mov	al,[ts_bottom_row]	;set
  mov	[ss_row],al		;  screen
  mov	ax,[crt_columns]	;    size
  mov	[ss_col],ax

  mov	eax,54
  mov	ebx,0		;stdio
  mov	ecx,5414h	;ioctl TIOCGWINSZ
  mov	edx,scrn_size
  int	byte 80h	;set screen size
;save cursor for top window
  mov	ax,0101h	;cursor position
  call	move_cursor
  mov	edi,ts_cursor
  call	save_cursor_at
  ret
;--------
  [section .data]
scrn_size:
ss_row: dw 0
ss_col: dw 0
ss_x	dw 0
ss_y	dw 0
  [section .text]

;-----------------------------------------------------------------------
restore_window:
  mov	edx,our_termios
  call	output_termios_0	;restore termios
;set scroll region
  mov	ax,[ts_top_rowa]
  mov	[sr_top],ax
  mov	ax,[bs_bottom_rowa]
  mov	[sr_end],ax
  mov	ecx,scroll_region
  call	crt_str
;set screen size
  mov	al,[menu_line]		;crt_rows has changed, use menu_line!
  mov	[ss_row],al
  mov	ax,[crt_columns]
  mov	[ss_col],ax

  mov	eax,54
  mov	ebx,0		;stdio
  mov	ecx,5414h	;ioctl TIOCGWINSZ
  mov	edx,scrn_size
  int	byte 80h
  ret
;--------------------
  [section .data]

scroll_region:
 db 1bh
 db '['
sr_top:
 db '00'
 db ';'
sr_end:
 db '00'
 db 'r'
 db 0
  [section .text]
;-----------------------------------------------------------------------
set_top_win:
  mov	edx,our_termios
  call	read_termios_0		;save our termios
  mov	edx,app_termios
  cmp	dword [edx],0		;termios saved?
  je	stw_skip		;jmp if no termios
  call	output_termios_0	;restore app termios
stw_skip:
;set color
  mov	eax,[app_win_color]
  call	crt_set_color
;restore cursor
  mov	esi,ts_cursor
  call	restore_cursor_from
  ret
;-----------------------------------------------------------------------
set_bottom_win:
;save app termios
  mov	edx,app_termios
  call	read_termios_0	;save app termios
;restore our termios
  mov	edx,our_termios
  call	output_termios_0 ;set our termios
;save cursor
  mov	edi,ts_cursor
  call	save_cursor_at
  ret
;-----------------------------------------------------------------------
;display running message
running_msg:
  mov	ah,[bs_top_row]
  add	ah,4
  mov	al,40
  call	move_cursor
 
  mov	eax,[menu_color]	;save color
  call	crt_set_color

  mov	ecx,running_txt
  mov	edx,running_txt_len
  call	crt_write
  ret
;-------------
  [section .data]
running_txt:
 db ' App Running '
running_txt_len	equ $ - running_txt
  [section .text]  

;------------------------------
dead_msg:
  mov	ah,[bs_top_row]		;get bottom screen top row
  add	ah,4
  mov	al,40
  call	move_cursor
 
  mov	eax,[menu_color]	;save color
  call	crt_set_color

  mov	ecx,dead_txt
  mov	edx,dead_txt_len
  call	crt_write
  ret
;-------------
  [section .data]
dead_txt:
 db '   App died   '
dead_txt_len	equ $ - dead_txt
  [section .text]  
