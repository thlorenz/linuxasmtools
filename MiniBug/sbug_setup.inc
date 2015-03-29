;--------------- file: sbug_setup.inc ------------------------

;----------------------------------------------------------
;output: sign bit set for js if error
load_program:
  cmp	byte [parse_attach],0
  jz	lt_50		;jmp if normal launch
;this is a attach
  mov	eax,[attach_pid]
  mov	[trace_pid],eax	;setup global variable
  call	trace_attach
  jmp	short lt_60  

;fork duplicates program, including signal handling, open fd's etc.
;     only pending signals are cleared and PID changed.
;fork ---- fork

lt_50:
  mov	eax,2		;fork
  int	byte 80h
  or	eax,eax
  jz	child_processing
;parent path -- exit ---
  mov	[trace_pid],eax
;lt_wait:
  mov	ebx,[trace_pid]	;process to wait for
  mov	edx,0		;wait forever

  xor	esi,esi
  call	trace_wait
lt_60:
;get initial registers
  mov	esi,app_regs
  call	trace_regsget
;check if preliminary code inserted on stack
;and run before program.  This is common for
;"c" programs and dynamic library usage.
;  mov	eax,[app_eip]
;  test	eax,0f0000000h	;are we on stack
;  jz	lt_exit		;exit if load point off stack
;we are running on stack, step till program entered
;  mov	[stack_stub_code],eax ;set stack flag
;  call	optional_stub_msg
;lf_loop:
;  xor	esi,esi ;get signal
;  call	trace_step
;
;  mov	esi,app_regs
;  call	trace_regsget

;  mov	eax,[app_eip]
;  test	eax,0f0000000h	;still on stack?
;  jnz	lf_loop
lt_exit:
  ret
  
;child processing ---------------------------- child -----------

child_processing:
  call	traceme
;execute command ----  exec ----
; execve passes PID and open fd's on.  Signals are
; set to their defualt state.  The SIGCHLD state is
; undetermined if set to SIG_IGN (no handler)
; pending signals are cleared.
  mov	esi,LastTarget
  mov	edi,lib_buf+400
  call	str_move
  inc	edi
  mov	esi,LastTargetParm
cp_lpy:
  lodsb
  or	al,al
  jz	ccp_50		;jmp if end of parameters
  cmp	al,' '
  jne	ccp_10		;jmp if not space
  mov	al,0
ccp_10:
  stosb
  jmp	short cp_lpy
;start app -----------
ccp_50:
  mov	dword [edi],0	;terminate parameters
  mov	esi,lib_buf+400
  call	sys_run_die
;should not get here
  mov	eax,1
  int	byte 80h			;exit
;end of child processing ----
  ret
;----------------------------------------------------------
adjust_starting_eip:
  mov	ebx,[app_eip]
  cmp	ebx,[_elf_phys_exec_entry]
  je	ase_exit	;exit if starting at main
  call	optional_stub_msg
  mov	ebx,[_app_main]
  or	ebx,ebx
  jnz	ase_20		;jmp if found
  mov	ebx,[_elf_phys_exec_entry]
ase_20:
  call	add_break
  call	cmd_go
  call	trace_wait
  call	remove_breaks
  mov	esi,app_regs
  call	trace_regsget
  dec	dword [app_eip]	;adjust for break
  mov	esi,app_regs
  call	trace_regsset
  mov	[app_mode],byte 0
ase_exit:
  ret  

;----------------------------------------------------------
optional_stub_msg:
;check if we skipped over stack code
  mov	eax,[app_eip]
;we skipped over stack code, show message
  mov	edi,stub_adr
  call	dwordto_hexascii
  mov	ah,[top_screen+screen.top]
  add	ah,4
  mov	al,4
  call	move_cursor
 
  mov	eax,[menu_color]	;save color
  call	crt_set_color

  mov	ecx,stack_code_txt
  mov	edx,stack_code_txt_len
  call	crt_write

  xor	eax,eax
  mov	[stack_stub_code],eax
osm_exit:
  ret
;-------------
  [section .data]
stack_code_txt:
 db ' Skipped over startup code at: '
stub_adr:
 db '12345678 '
stack_code_txt_len	equ $ - stack_code_txt
  [section .text]  

;----------------------------------------------------------
;input:
; parse states:  asmbug                      <- use history data,verify history data present
;                asmbug <prog> <parmaters>   <- stuff in history,clear existing asmdis files
;                asmbug -a <prog>            <- set flag and lookup pid for program
;                asmbug -h                   <- show help and exit
;output: sign flag set if error
parse:
;check if any parameters
  mov	esi,esp
  lodsd			;clear return address from stack
  lodsd			;get parameter count, 1=none

  push	eax		;save parm count
  lodsd			;get our executable name ptr
  pop	eax

  dec	eax
  jnz	pi_10		;jmp if parameter entered
  or	eax,-1
  jmp	pi_exit		;error jump, no parameters
;get parameters
pi_10:
pi_sw_lp:
  lodsd			;eax=ptr to user parameter
  or	eax,eax
  jz	pi_exit		;exit if all parameters processed
pi_12:
  cmp	word [eax],'-a'
  jne	pi_target
  call	attach_setup
  jmp	short pi_exit
pi_target:
  call	get_target
  js	pi_exit
  mov	edi,LastTargetParm
pi_parm_lp:
  lodsd			;get parameter ptr
  or	eax,eax
  jz	pi_exit2	;exit if no parameters
  push	esi
  mov	esi,eax
  call	str_move
  mov	al,' '
  stosb
  pop	esi		;restore stack ptr
  jmp	short pi_parm_lp
pi_exit2:
  xor	eax,eax
  stosd			;zero end of parmaters
pi_exit:
  or	eax,eax
  ret
;-------------------------------------------------------------
; parse target filename,check if file
; exists, any other parsed entry is error.
; eax=ptr to parameter
; esi=ptr to stack ptrs 
get_target:
  mov	[gt_name_ptr],eax
  push	esi		;save stack ptr

;is full path of file provided?
gt_10:
  cmp	byte [eax],'/'
  jne	gt_20			;jmp if not full path
  mov	esi,eax
  mov	edi,lib_buf+200
  call	str_move
  jmp	short gt_30  
;is file in local directory
gt_20:
  call	dir_current		;sets ebx=dir ptr (lib_buf)
  mov	esi,ebx
  mov	edi,lib_buf+200		;filename build area
  call	str_move
  mov	al,'/'
  stosb
  mov	esi,[gt_name_ptr]
  call	str_move
gt_30:
  mov	ebx,lib_buf+200
  mov	ecx,1			;check if executable
  call	file_access
  or	eax,eax
  jz	gt_file_ok		;jmp if access ok
;file not in local directory, check path
  mov	ebx,[enviro_ptrs]
  mov	ebp,[gt_name_ptr]
  call	env_exec
  jc	gt_fail			;jmp if file not found
;move path to remote file
  mov	esi,ebx
  mov	edi,LastTarget
  call	str_move
  jmp	short gt_exit1
;file found in local dir, move name
gt_file_ok:
;  mov	esi,[gt_name_ptr]
  mov	esi,lib_buf + 200
  mov	edi,LastTarget
  call	str_move
  jmp	short gt_exit1
gt_fail:
;  mov	eax,err1
;  call	show_error
  mov	eax,-1
  jmp	short gt_exit
gt_exit1:
  xor	eax,eax
gt_exit:
  or	eax,eax
  pop	esi		;restore esi
  ret
  
;-----------
  [section .data]
gt_name_ptr: dd 0 ;ptr to input file name
  [section .text]  
;-------------------------------------------------------------
;parse filename if present, get pid of target
; eax=ptr to parameter
; esi=ptr to stack ptrs 
attach_setup:
  lodsd			;get next parameter
  call	get_target
  js	as_exit0	;exit if error
  mov	byte [parse_attach],1
;find pid of file at LastTarget
  mov	esi,LastTarget
  cmp	byte [esi],'/'
  jne	as_40		;jmp if not full path
  call	str_end
as_10:
  dec	esi
  cmp	byte [esi],'/'
  jne	as_10		;loop till prior '/' found
  inc	esi		;move to start of name
;setup to search /proc
as_40:
  push	esi
  mov	eax,temp_buf_size
  call	m_allocate	;allocate buffer to read files
  js	as_exit2
  mov	[temp_buf_ptr],eax
  mov	ebx,temp_buf_size
  pop	ecx		;get match string
  call	process_search	;find process
  jz	as_exit0	;jmp if not found
  js	as_exit0	;jmp if not found
;search for pid
  mov	esi,eax		;get buf ptr
  mov	ecx,100		;max serach length
as_50:
  inc	esi
  cmp	[esi],dword 'Pid:'
  je	as_60		;jmp if "Pid:" found
  loop	as_50		;keep looking
  jmp	short as_exit0	;error exit
;we have found string "Pid:"
as_60:
  add	esi,5		;move past "Pid:"
  call	ascii_to_dword
  mov	[attach_pid],ecx
  xor	eax,eax
  jmp	short as_exit1 
as_exit0:
  mov	eax,-1
as_exit1:
  push	eax
  mov	eax,[temp_buf_ptr]
  call	m_release
  pop	eax
as_exit2:
  ret  
;----------------------------------------------------------
mem_window_setup:
  mov	eax,[app_eip]	;set initial memory window adr
  mov	[mem_top_adr],eax
  ret
;----------------------------------------------------------
dis_window_setup:
  mov	al,[bottom_screen+screen.top]
  mov	[select_line#],al

  mov	eax,[app_eip]
  mov	[dis_win_top],eax

  mov	[symbol_process],dword symbol_handler ;sym lookup
  ret  
;----------------------------------------------------------

;----------------------------------------------------------
setup_display:
  call	read_window_size
  mov	ecx,reset_msg
  call	crt_str
  mov	eax,[crt_rows]
  mov	[menu_line],al

  dec	eax		;menu line
  mov	[bottom_screen+screen.bottom],al 	;set bottom win end
  push	eax
  lea	edi,[bottom_screen+screen.abottom]
  call	byte_to_ascii				;store ascii bottom win end
  pop	eax

  sub	al,9					;move to top of bottom win
  mov	[bottom_screen+screen.top],byte al	;save bottom win top
  push	eax
  lea	edi,[bottom_screen+screen.atop]
  call	byte_to_ascii				;save ascii bottom win top
  pop	eax

  dec	al					;move to top win end
  mov	[top_screen+screen.bottom],byte al	;save top win end
  push	eax
  lea	edi,[top_screen+screen.abottom]
  call	byte_to_ascii				;save ascii top win end
  pop	eax
;setup top win cursor
;  mov	esi,cursor_template		
;  mov	edi,ts_cursor	
;  call	str_move				;store top win cursor
;setup bottom win cursor
;  xor	eax,eax
;  mov	al,[bottom_screen+screen.top]		;get bottom win top
;  lea	edi,[ct_row]
;  call	byte_to_ascii				;ascii for bottom win top
;  mov	esi,cursor_template
;  mov	edi,bs_cursor
;  call	str_move				;store bottom win cursor
;setup menu line
  mov	al,1		;column for menu line
  mov	ah,[menu_line]
  call	move_cursor	;move cursor to menu line
  mov	bl,20h		;center character
  mov	eax,30003131h	;color
  mov	ecx,[crt_columns]
  call	crt_horizontal	;write menu line
;setup reg win column
  mov	eax,[crt_columns]
  sub	eax,24
  mov	[reg_win_start_col],eax
  dec	eax
  mov	[dis_win_end_col],eax
sd_exit:
  ret
;-------------
;---------------------------------------
signal_install:
  mov	ebp,signal_table
  call	install_signals
  ret

signal_uninstall:
  mov	dword [sig_mod1],0
  call	signal_install
  mov	dword [sig_mod1],winch_signal
  ret

winch_signal:
  call	read_window_size
  mov	byte [win_select],-1	;abort for now
  ret


;-------------------------------------------
  [section .data]

;cursor_template:
; db 1bh	;esc
; db '['
;ct_row:
; db '01'
; db ';'
;ct_column:
; db '001'
; db 'H'
; db 0

;---------------------------------------
reset_msg:	db 1bh,'c',0
;----------
  [section .data]
signal_table:
  db	28
sig_mod1:
  dd	winch_signal
  dd	0
  dd	0
  dd	0
  db	0		;end of install table

LastTargetParm	times 100 db 0
LastTarget	times 200 db 0
parse_attach	db	0
attach_pid	dd	0

temp_buf_size	equ	100000
temp_buf_ptr	dd	0

  [section .text]

