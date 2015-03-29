;---------- file: sbug_key_cmds.inc --------------------------

;----------------------------------------------------------
decode_key:
  mov	esi,key_decode_table
  call	key_decode3
  ret
;--------
  [section .data]
key_decode_table:

  db 1bh,5bh,41h,0		;15 pad_up
  dd cmd_key_up

  db 1bh,4fh,41h,0		;15 pad_up
  dd cmd_key_up

  db 1bh,4fh,78h,0		;15 pad_up
  dd cmd_key_up

  db 1bh,5bh,42h,0		;20 pad_down
  dd cmd_key_down

  db 1bh,4fh,42h,0		;20 pad_down
  dd cmd_key_down

  db 1bh,4fh,72h,0		;20 pad_down
  dd cmd_key_down

  db 1bh,5bh,35h,7eh,0		;16 pad_pgup
  dd cmd_key_pgup

  db 1bh,4fh,79h,0		;16 pad_pgup
  dd cmd_key_pgup

  db 1bh,5bh,36h,7eh,0		;21 pad_pgdn
  dd cmd_key_pgdn

  db 1bh,4fh,73h,0		;21 pad_pgdn
  dd cmd_key_pgdn

  db 1bh,5bh,44h,0		;17 pad_left
  dd mem_up

  db 1bh,4fh,74h,0		;143 pad_left
  dd mem_up

  db 1bh,5bh,43h,0		;18 pad_right
  dd mem_down

  db 1bh,4fh,76h,0		;144 pad_right
  dd mem_down

  db 1bh,5bh,48h,0		;14 pad_home
  dd mem_pgup
  db 1bh,4fh,77h,0		;150 pad_home
  dd mem_pgup
  db 1bh,5bh,31h,7eh,0		;138 home (non-keypad)
  dd mem_pgup

  db 1bh,5bh,46h,0		;19 pad_end
  dd mem_pgdn
  db 1bh,5bh,34h,7eh,0		;139 end (non-keypad)
  dd mem_pgdn
  db 1bh,4fh,71h,0		;145 pad_end
  dd mem_pgdn
  
  db 'g',0
  dd cmd_go

  db 's',0
  dd cmd_step

  db ' ',0
  dd cmd_step

;  db 'o',0
;  dd cmd_step_over

  db 'c',0
  dd cmd_clear_breaks

  db 'a',0
  dd cmd_brk_here

  db 'h',0
  dd cmd_help

  db 'q',0
  dd cmd_quit

  db 'r',0
  dd cmd_show_regs

  db 'm',0
  dd cmd_show_memory

  db 'e',0
  dd cmd_show_stack

  db 'b',0
  dd cmd_show_breaks

  db 17h,0		;control-w
  dd cmd_switch_windows

  db 0		;end of table    
  [section .text]
;----------------------------------------------------------
cmd_go:
  mov	esi,app_regs
  call	trace_regsset

  mov	ebx,[app_eip]
  call	find_break	;check if break at eip
  jecxz	cg_20		;jmp if no break at eip
;we need to step over break location
  mov	esi,[send_signal] ;get signal
  mov	[send_signal],dword 0	;clear signal flag
  call	trace_step
  js	cg_exit

  xor	eax,eax
  mov	[app_status],eax

  mov	eax,114
  mov	ebx,[trace_pid]
  mov	ecx,app_status
  mov	edx,0				;1=WNOHANG
  xor	esi,esi
  int	byte 80h
;returns eax=err if app dead
;returns eax=0 if no change in status
;returns eax=pid if stop and status filled in

  mov	esi,app_regs
  call	trace_regsget
  mov	edx,[app_eip]
  call	find_break	;break here?
  jecxz	cg_20		;jmp if no break here
  jmp	short cg_exit	;exit if break here
;run to next break
cg_20:
  call	running_msg
  call	set_top_win
  call	insert_breaks
  xor	esi,esi			;normal restart
  call	trace_continue
  or	[app_mode],byte 01h	;set running mode
  mov	[eip_track_flag],byte 1	;enable eip tracking
%ifdef LOG
  call	log_eol
  mov	eax,'run '
  call	log_regtxt
%endif

cg_exit:
  ret

;----------------------------------------------------------
cmd_step:
  test	[app_mode],byte 3 ;dead or running?
  jz	do_step		;jmp if app mode ok
;stop running app
;  call	stop_app
  jmp	cs_exitx
do_step:
  call	set_top_win
  mov	esi,app_regs
  call	trace_regsset
  mov	esi,[send_signal] ;get signal
  mov	[send_signal],dword 0	;clear signal flag
  call	trace_step
  xor	eax,eax
  mov	[app_status],eax

  mov	eax,114
  mov	ebx,[trace_pid]
  mov	ecx,app_status
  mov	edx,0				;1=WNOHANG
  xor	esi,esi
  int	byte 80h
;returns eax=err if app dead
;returns eax=0 if no change in status
;returns eax=pid if stop and status filled in
  cmp	[app_status],word 057fh		;normal break?
  je	step_ok
  call	report_signal
  jmp	short ca_exit2
step_ok:
  mov	esi,app_regs
  call	trace_regsget
  or	[app_mode],byte 10h
  mov	[eip_track_flag],byte 1	;enable eip tracking
cs_exitx:
  call	set_bottom_win
ca_exit2:
  ret

;----------------------------------------------------------
;----------------------------------------------------------
cmd_brk_here:
  xor	eax,eax
  mov	al,[select_line#]
  sub	al,[bottom_screen+screen.top] ;compute index
  shl	eax,2			;make dword index
  add	eax,dis_win_array
  mov	ebx,[eax]		;get address at select bar
  call	find_break
  jecxz	cbh_add
  call	remove_break
  jmp	short cbh_exit
cbh_add:
  push	ebx			;save break address
  push	ebx			;save break address
  call	add_break
  pop	eax
  call	map_update		;update map
  pop	eax
  call	hunt_entry		;do hunt
cbh_exit:
  or	[app_mode],byte 10h	;force display update
  ret
;---------------
;input: ebx=break address
add_break:
;add this break
  mov	esi,breaks
  mov	ecx,10
cbh_lp:
  cmp	[esi],dword 0
  je	stuff_break
  add	esi,5
  loop	cbh_lp
  jmp	short ab_exit
stuff_break:
  mov	[esi],ebx
;get break restore data
  mov	edx,ebx		;address to edx
  add	esi,4		;compute stuff ptr
  mov	edi,1		;read one byte
  call	trace_peek_bytes
  or	[app_mode],byte 10h	;force display update
ab_exit:
  ret

;----------------------------------------------------------
cmd_clear_breaks:
  mov	edi,breaks
  xor	eax,eax
  mov	ecx,10
  rep	stosd
  mov	ecx,10
  rep	stosb
  or	[app_mode],byte 10h	;force display update
  ret
;--------------------------------------------------
; input: ebx = break to remove
;       
remove_break:
  call	find_break
  jecxz	rbb_exit		;exit if not found
;break found at [ebx]
rbb_10:
  mov	edi,eax ;top of delete area
  mov	eax,5			;remove 5 bytes
  lea	ebp,[breaks + (5 * 10)] 
  call	blk_del_bytes
  xor	eax,eax
  mov	[breaks + (5*(10 -1))],eax
rbb_exit:
  ret
;--------------------------------------------------
; input:  ebx = absolute break address
; output: ecx=0 if not found
;         ecx=x if found & ebp=shared memory ptr
;                          [ebx] = break ptr
find_break:
  mov	ecx,10
  mov	eax,breaks
rbb_lp:
  cmp	[eax],ebx
  je	fb_exit			;jmp if break found
  add	eax,5
  loop	rbb_lp			;loop till break found
fb_exit:
  ret

;-----------------------------------------------------------------
;insert breaks into app code before execution
insert_breaks:
  mov	esi,breaks
  mov	ecx,10
ib_lp:
  mov	edx,[esi]			;get poke address
  or	edx,edx
  jz	ib_done				;jmp if end of breaks
  push	esi
  mov	esi,trap_code			;get pointer to data
  mov	edi,1				;get number of bytes
  push	ecx
  call	trace_poke_bytes
  pop	ecx
  pop	esi
  add	esi,5
  loop	ib_lp
ib_done:
  ret
;-------------
  [section .data]
trap_code db 0cch
  [section .text]
;----------------------------------------------------------
;restore app to non-break state
remove_breaks:
  mov	esi,breaks
  mov	ecx,10
rb_lp:
  mov	edx,[esi]			;get poke address
  or	edx,edx
  jz	rb_done				;jmp if end of breaks
  add	esi,4				;move to restore byte
  push	esi
  mov	edi,1				;get number of bytes
  push	ecx
  call	trace_poke_bytes
  pop	ecx
  pop	esi
  inc	esi
  loop	rb_lp
rb_done:
  ret


;----------------------------------------------------------
cmd_key_up:
  mov	al,[select_line#]
  cmp	al,[bottom_screen+screen.top]
  jne	cku_up
  call	find_prev
  jc	cku_exit		;exit if error
  mov	[dis_win_top],eax
  jmp	short cku_exit
cku_up:
  dec	byte [select_line#]
cku_exit:
  or	[app_mode],byte 10h	;force display update
  ret

;----------------------------------------------------------
cmd_key_down:
  mov	al,[select_line#]
  cmp	al,[bottom_screen+screen.bottom]
  jne	ckd_down
  mov	eax,[dis_win_array+4]
;check if at end of memory
  mov	ebx,[load_end_ptr]
  cmp	eax,ebx
  jae	ckd_exit		;exit if at end
  mov	[dis_win_top],eax
  jmp	short ckd_exit
ckd_down:
  inc	byte [select_line#]
ckd_exit:
  or	[app_mode],byte 10h	;force display update
  ret

;----------------------------------------------------------
cmd_key_pgup:
  mov	ecx,9
ckp_lp:
  push	ecx
  call	find_prev
  pop	ecx
  mov	[dis_win_top],eax
  loop	ckp_lp
ckp_exit:
  or	[app_mode],byte 10h	;force display update
  ret

;----------------------------------------------------------
;output: flag "jc" set if error
;        eax = adress if success
find_prev:
  mov	eax,[dis_win_top]		;address of inst
  cmp	eax,[load_header_ptr]
  jne	fb_back			;jmp if within range
  stc
  jmp	short fp_err
fb_back:
  call	adr2map
  jc	fp_err			;jmp if out of range
fb_lp:
  dec	eax			;go back
  test	[eax],byte 22h		;start of inst?
  jnz	fp_rtn
  cmp	[eax],byte 0		;data here
  jne	fb_lp			;go back if not data
fp_rtn:
  call	map2adr		;compute address
  clc
fp_err:
  ret
    
;----------------------------------------------------------
cmd_key_pgdn:
  mov	eax,[dis_win_array+(4*9)]
  cmp	eax,[load_end_ptr]
  jae	ckp_done
  mov	[dis_win_top],eax
  or	[app_mode],byte 10h	;force display update
ckp_done:
  ret

;----------------------------------------------------------
;right arrow
mem_down:
  mov	eax,[mem_top_adr]
  cmp	eax,[load_end_ptr]
  jae	mem_down_exit		;exit if at top
  add	eax,4
  mov	[mem_top_adr],eax
mem_down_exit:
  or	[app_mode],byte 10h	;force display update
  ret
;----------------------------------------------------------
;left arrow
mem_up:
  mov	eax,[mem_top_adr]
  cmp	eax,[load_header_ptr]
  jbe	mem_up_exit		;exit if at bottom
  sub	eax,4		;move up 1 dword
  mov	[mem_top_adr],eax
mem_up_exit:
  or	[app_mode],byte 10h	;force display update
  ret
;----------------------------------------------------------
mem_pgup:
;----------------------------------------------------------
mem_pgdn:
  ret
;----------------------------------------------------------
cmd_help:
  mov	eax,help_end - help_msg
  xor	ebx,ebx
  mov	ecx,help_msg
  call	view_buffer
  or	[app_mode],byte 10h	;force display update
  ret

;----------------------------------------------------------
cmd_quit:
  or	[app_mode],byte 10h	;force display update
  or	[app_mode],byte 4
  ret

;----------------------------------------------------------
cmd_show_regs:
  or	[app_mode],byte 10h	;force display update
  mov	[win_select],byte 0
  ret

;----------------------------------------------------------
cmd_show_memory:
  or	[app_mode],byte 10h	;force display update
  mov	[win_select],byte 1
  ret

;----------------------------------------------------------
cmd_show_stack:
  or	[app_mode],byte 10h	;force display update
  mov	[win_select],byte 3
  ret

;----------------------------------------------------------
cmd_show_breaks:
  or	[app_mode],byte 10h	;force display update
  mov	[win_select],byte 2
  ret

;----------------------------------------------------------
cmd_switch_windows:
  or	[app_mode],byte 10h	;force display update
  ret

;----------------------------------------------------------

;**********************************************************
  [section .data]
send_signal	dd 0	;set to signal if necessary
app_status	dd 0	;status of last command
  [section .text]

