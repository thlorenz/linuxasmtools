  extern terminal_type
  extern x_connect
  extern x_get_input_focus
  extern x_get_geometry
  extern root_win_pix_width
  extern root_win_pix_height
  extern x_configure_window
  extern window_pre
;  extern window_create
  extern window_move_resize
  extern window_name
  
;%include "../window/window.inc"

;-------------- setup_win.inc ----------------------
; output: flags = "js" if fatal error
win_setup:
  call	initial_window_setup
  js	ws_exit			;exit if error
  call	code_win_setup
  call	reg_win_setup
  call	brk_win_setup
  call	mem_win_setup
  xor	eax,eax			;set normal exit flag
ws_exit:
  ret
;-----------------------------------------------------------
; operation: 1. get terminal type
;            2. connect to x server
;            6. create debug window & set font
; inputs: asmbugrc
; output: sign bit set if fatal error and eax negative
;            
initial_window_setup:
  call	terminal_type
  cmp	al,2	;console
  jne	iws_10		;jmp if probable x window
  mov	eax,err_iws1
  call	show_error
  mov	eax,-1
  jmp	iws_exit
;connect to x server
iws_10:
  call	x_connect
  jns	iws_15		;jmp if connected ok
  mov	eax,err_iws2
  call	show_error
  mov	eax,-1
  jmp	iws_exit
iws_15:
  call  app_resize	
;select font size
  mov	eax,[DebugWinFont]
  or	eax,eax
  jnz	iws_18		;jmp if font found
  mov	eax,9		;preload font size
  cmp	[root_win_pix_width],word 850
  jb	iws_17		;jmp to set font=9
  inc	eax		;set al=10 (font width)
;  cmp	[root_win_pix_width],word 1200
;  jb	iws_17
;  inc	eax
iws_17:
  mov	[DebugWinFont],eax ;store font
iws_18:
;setup app window 
iws_20:
;allocate work buffer for window create
  mov	eax,24000
  call	m_allocate
  mov	[the_buffer],eax
;create debug window
  mov	ebp,win_block
  mov	eax,[the_buffer]
  mov	edx,24000	;the_buffer_size
  mov	ebx,[DebugWinFont]	;font
  mov	ecx,Blue		;blue	;window background color
  call	window_pre	;get initial conditions
  js	iws_exit
;setup parameters for window_create

  mov	eax,[ebp+win.s_char_width]
  imul	eax,65
  mov	[wc_block+4],ax	;set width
  mov	[DebugWinWidth],ax

;compute suggested height for window in pixels
  movzx	eax,word [root_win_pix_height]
  sub	ax,[ebp+win.s_char_height]	;shorten by 1 line
  sub	ax,[ebp+win.s_char_height]	;shorten by 1 line
  sub	ax,[ebp+win.s_char_height]	;shorten by 1 line
;check if history has height
  mov	edx,[DebugWinHeight]
  or	edx,edx
  jz	iws_22			;jmp if no height in history
;check if history height legal
  cmp	edx,eax
  ja	iws_22			;jmp if history value too big
;use history value
  mov	eax,edx
;set height to even character boundry
iws_22:
  xor	edx,edx
  div	dword [ebp+win.s_char_height]
  mul	word [ebp+win.s_char_height]

  mov	[wc_block+6],ax	;set height
  mov	[DebugWinHeight],ax

  mov	esi,wc_block
  call	window_create
  js	iws_exit		;jmp if error

  mov	esi,window_title
  call	window_name

  call	window_write_table_setup
  push	ebp			;save win_block
  mov	eax,[the_buffer]
  call	m_release    
  pop	ebp			;restore win_block
;sending winch may not be needed, put in for testing
;a problem with app window reporting wrong size
  mov	eax,37	;kill
  mov	ebx,0	;pid (0=all)
  mov	ecx,28	;winch
  int	80h

iws_exit:
  or	eax,eax
  ret

;-----------
  [section .data]

window_title: db 'AsmBug',0
err_iws1: db 'X terminal needed',0ah,0
err_iws2: db 'X server connection failed',0ah,0

win_block: times win_struc_size db 0

blue:	db 'blue',0
the_buffer	dd 0


wc_block: dw 1	;x loc
	  dw 1	;y
	  dw 0	;width
	  dw 0	;height

  [section .text]
;-----------------------------------------------------------
;called after x-connect

app_resize:
  cmp	byte [AppResize],0
  je	ar_exit			;jmp if no resize
  call	x_get_input_focus	;get terminal id
  js	ar_exit			;exit if failure
  mov	eax,[ecx+8]		;get window id
  mov	[terminal_id],eax
  or	eax,eax
  jz	ar_exit			;exit if no focus
  call	x_get_geometry		;get current geometry for restore
  lea	esi,[ecx+12]
  mov	edi,term_col_loc
  mov	ecx,8
  rep	movsb			;save window size
;root - root_win_pix_width,root_win_pix_height
  movzx	eax,word [root_win_pix_width]
  shr	eax,1
  mov	[adj_trm_col_loc],ax
  mov	[adj_trm_cols],ax
;;  mov	[ss_y],ax		;;
  movzx	eax,word [root_win_pix_height]
  sub	eax,40
  mov	[adj_trm_rows],ax
;;  mov	[ss_x],ax		;; rows
;resize window
  mov	eax,[terminal_id]	;get xterm id   
  mov	esi,adj_trm_col_loc
  call	window_move_resize	;x window size
;resize window again
  mov	eax,[terminal_id]
  call	x_get_geometry
  mov	eax,[terminal_id]	;get xterm id   
  mov	esi,adj_trm_col_loc
  call	window_move_resize	;x window size
  
  call	set_app_screen_size	;terminal size
ar_exit:
  ret

;------------------
  [section .data]
terminal_id	dd 0

term_col_loc	dw 0	;pixel x location
term_row_loc	dw 0	;pixel y location
term_cols	dw 0	;total pixels in line
term_rows	dw 0	;total pixels for vertical screen

adj_trm_col_loc	dw 0
adj_trm_row_loc	dw 20
adj_trm_cols	dw 0
adj_trm_rows	dw 0

  [section .text]
;----------------------------------------------------------
; this logic is having trouble???
app_win_restore:
  mov	eax,[terminal_id]
  or	eax,eax
  jz	awr_exit	;exit if window unchanged
  mov	esi,term_col_loc
  call	window_move_resize
;get new geometry, but ignore it for now
  mov	eax,[terminal_id]
  call	x_get_geometry
;try setting screen size again
  mov	eax,[terminal_id]	;get xterm id   
  mov	esi,term_col_loc
  call	window_move_resize	;x window size

awr_exit:
  ret

;-----------------
;
  extern read_window_size,crt_rows,crt_columns
set_app_screen_size:
  call	read_window_size
  mov	eax,[crt_rows]
  sub	eax,1
  mov	[ss_row],al
  mov	eax,[crt_columns]
  shr	eax,1
  dec	eax
  mov	[ss_col],ax
  jmp	short screen_set
;-------------------------
restore_app_screen_size:
  mov	eax,[crt_rows]
  mov	[ss_row],al
  mov	eax,[crt_columns]
  mov	[ss_col],ax
screen_set:
;  mov	[winch_expected_flag],byte 1	;ignore next winch
  mov	eax,54
  mov	ebx,1		;stdio
  mov	ecx,5414h	;ioctl TIOCGWINSZ
  mov	edx,scrn_size
  int	byte 80h
  ret
;--------------------
  [section .data]
scrn_size:
ss_row: dw 3
ss_col: dw 0
ss_x	dw 0	;row pixels
ss_y	dw 0	;col pixels


  [section .text]
;------------------------------------
;the following is called if winch signal occurs
;inputs: the orgional screen size at crt_rows,crt_columns
;                   term_cols, term_rows (pixel)
;                   term_col_loc term_row_loc

;resizing works in terminal, but fails if inside asmfile?
;the following logic as abandoned as not needed.

adjust_app_size:
  mov	eax,54
  mov	ebx,1		;stdio
  mov	ecx,5413h	;ioctl read size
  mov	edx,scrn_size
  int	byte 80h
  ret

;---------------
  [section .text]

