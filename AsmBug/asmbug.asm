
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
;%define TRACE 
;------------------ abug ---------------------------


;
; input:  abug <-h> <-a> <filename> <parameters>
;         where:
;                -a = attach to running file with name <filename>
;                <filename> = name of executable in local directory
;                <parameters> parameters used by program being tested
;
;         if no <filename> is provided, asmbug checks if setup files exist, and if
;         found the debug scession continues,  If not found an error is given.
;
  extern read_one_byte
  extern x_get_input_focus
  extern window_kill
  extern env_stack
  extern m_setup
  extern m_allocate
  extern m_release
  extern m_close
;%include "memory.inc"

  extern str_move
  extern block_write_all
  extern block_read_all
  extern dword_to_ascii
  extern dwordto_hexascii
  extern parse_token
  extern lookup_token
  extern lib_buf
  extern hexascii_to_dword
  extern ascii_to_dword
  extern crt_str
  extern enviro_ptrs
  extern env_exec
  extern file_access
  extern dir_current
;  extern view_file
  extern str_end
  extern process_search
;  extern sys_run_wait
  extern window_write_line
  extern window_write_table
  extern window_write_table_setup
  extern file_delete
  extern delay
  extern x_flush
  extern x_disconnect
  extern color_id_table
  extern install_signals
  extern read_termios_0
  extern output_termios_0
  extern term_type
 extern window_create
;%include "window_create.inc"

;%include "system.inc"
%include "window.inc"

  extern reset_clear_terminal

global _start
_start:
  cld
  call	env_stack
  call	read_window_size
  call	terminal_type
  cmp	[term_type],byte 3	;xterm?
  jne	abug_exitj
  mov	edx,termios
  call	read_termios_0
  call	m_setup			;setup  the memory manager
  call	read_history
;  js	abug_exitj
  mov	ebp,signal_table
  call	install_signals
  call	parse
  js	abug_exitj
  call	m_close
  mov	eax,LastTarget
  call	elf_prep
  jns	abug_01			;jmp if error
  mov	ecx,[msg_ptr]
  add	ecx,byte 2
  call	crt_str
  cmp	[error_code],byte -7
  jne	abug_exitj		;jmp if not  old source error
abug_01:
;  mov	eax,bss_end		;managed_memory
  call	m_setup			;setup  the memory manager
  call	read_files		;read files describing target
  js	abug_exitj
  call	win_setup		;create and adjust windows
  js	abug_exitj
  call	lookup_color_id		;translate colors into cid's
  call	message_setup
  call	pop_up_setup
  call	launch_target
  js	abug_exitj
  call	goto_local_eip
  call	hunt_setup
find_code:
  call	code_hunt
  jz	find_data		;jmp if code hunt successful
  mov	[msg_ptr],dword tricky_code
find_data:
  call	data_hunt
  jns	show_all_windows
abug_exitj:
  jmp	abug_exit2
show_all_windows:
  mov	[win_bit_map],byte 3fh	;enable display of all windows
show_changed_windows:
  cmp	[window_delay_count],dword 0
  je	show_now		;jmp if time to show
  dec	dword [window_delay_count]
  jmp	short abug_04		;skip display 
show_now:
  mov	ebp,win_block
  call	show_windows
  mov	eax,[msg_ptr]
  or	eax,eax
  jz	abug_02
  call	message_append
abug_02:
;  cmp	[window_resize],byte 0
;  je	abug_04		;jmp if no resize
;  call	adjust_app_size
abug_04:
  call	check_app
  call	check_socket
  or	eax,eax
  jz	abug_tail
  call	eax
abug_tail:
  test	[event_mode],byte 1	;exit request?
  jnz	abug_exit
;check if we stopped on data statement
  mov	edx,[r1_eip]
  call	code_hunt_if		;do code hunt if necessary

abug_10:
  call	x_flush
  mov	eax,5
  call	delay
  jmp	show_changed_windows
  
abug_exit:
  cmp	[parse_attach],byte 0
  jne	abug_exit1	;jmp if this was attach
  call	kill_app
abug_exit1:
  call	restore_app_screen_size
  call	write_history
abug_exit2:
;  call	delete_elf_prep_files
;keyboard input in AsmMgr gets a bad char. if we
;do not kill the window and wait for focus?
  mov	ebp,win_block
  call	window_kill  
  call	app_win_restore
  call	x_flush
  call	x_get_input_focus
  call	delete_elf_prep_files
  mov	eax,100
  call	delay
  mov	ecx,clear_msg
  call	crt_str
%ifdef TRACE
  mov	eax,7
  mov	ebx,[trace_pid]
  mov	ecx,0
  mov	edx,1	;WHNOHANG
  call	log_hex
  call	log_eol
%endif
  mov	edx,termios
  call	output_termios_0
  call	reset_clear_terminal

  mov	eax,1
  int	byte 80h
;-----------------
  [section .data]
clear_msg:
;  db 0ah,1bh,'[46S',0	;scroll to create blank screen
;the following codes were sent to the screen, but a reset
;causes xterms to beep (1bh,0ch) and that is irritating.
;so a different string was used to clear the display.
;  db 0ah,1bh,'c',0ah,1bh,'[46S',0
;  db 1bh,0ch,0ah,0
 db 1bh,'[2J',0ah,0
  [section .text]
;---------------------------

;---------------------------
message_setup:
  mov	edx,[ebp+win.s_text_rows] ;get row
  sub	edx,1
  mov	[mt_row1],dl
  mov	[mt_row2],dl
;set foreground color
;  mov	eax,[codeMenuForButton]
;  call	lookup_color
;  mov	[mt_foreground],al	;store color
;set background color
;  mov	eax,[codeMenuBButton]
;  call	lookup_color
;  mov	[mt_background],al	;store color
	
  ret
;----------------------------------------
lookup_color:
  mov	edi,color_id_table	;ptr to color table
  mov	ecx,18
  repne	scasd			;search for color
  sub	edi,color_id_table
  mov	eax,edi
  sub	al,4
  ret
;---------------------------
;eax=msg ptr -> (event_mode,msg_length,string)
message_append:
  push	eax
  mov	ebp,win_block
  mov	ebx,[codeMenuForButton]
  mov	ecx,[codeMenuBButton]
  call	window_id_color
  pop	esi
  lodsb
  or	[event_mode],al		;or bits into event_mode
  jz	ma_20			;jmp if normal status
  push	esi
;  mov	ebx,[popButFColor]
;  mov	ecx,[popButBColor]
  mov	ebx,[cursorFColor]
  mov	ecx,[cursorBColor]
  call	window_id_color
  pop	esi

ma_20:
  mov	edi,mt_len
  lodsb				;get length
  stosb
  xor	ecx,ecx
  mov	cl,al			;move message length
  rep	movsb
  xor	eax,eax
  stosw				;put zero at end of table
  mov	esi,msg_table
  call	window_write_table

  xor	eax,eax
  mov	[msg_ptr],eax
  and	[event_mode],byte ~2	;remove warning bit
  ret


;--------------
  [section .data align=4]
msg_table:
;  db	16	;color set
;mt_foreground:
;  db	16	;foreground color
;mt_background:
;  db	00	;background color

  db	4	;fill line
  dw	0	;column
mt_row1:
  dw	0	;row
  db	64	;fill length
  db	' '	;fill char

  db	12	;write string
  dw	0	;column
mt_row2:
  dw	0	;row
mt_len:
  db	0	;str length
mt_string:
  times 67 db 0	;string

tricky_code: db 2,tc_size
tc_start: db 'tricky code'
tc_size	equ $ - tc_start

  [section .text]
;---------------------------
;show windows that have changed
; input: [win_bit_map] set
; output: {win_bit_map] cleared
show_windows:
sw_10:
  test	byte [win_bit_map],byte 1+4
  jz	sw_20
  call	show_regs
sw_20:
  test	byte [win_bit_map],byte 1+2
  jz	sw_30
  call  show_code
sw_30:
  test	byte [win_bit_map],byte 1+8
  jz	sw_40
  call	show_memory
sw_40:
  test	byte [win_bit_map],byte 1+10h
  jz	sw_50
  call	show_breaks
sw_50:
  mov	byte [win_bit_map],byte 0	;clear all bits
  ret
;------
  [section .data]
win_bit_map: db 0 ;1=menu 2=code 4=regs 8=memory 10=breaks 20h=center eip
  [section .text]
;---------------------------
kill_app:
  mov	eax,37
  mov	ebx,[trace_pid]
  or	ebx,ebx
  jz	ka_skip			;jmp if child not forked yet
  mov	ecx,9			;kill signal
  int	byte 80h
ka_skip:
  ret
;---------------------------
;see 1setup_parse.inc for files
delete_elf_prep_files:
  mov	ebx,header_file
  call	file_delete
  mov	ebx,abug_image
  call	file_delete
  mov	ebx,abug_fimage
  call	file_delete
  mov	ebx,abug_sym
  call	file_delete
  mov	ebx,abug_comment
  call	file_delete
  mov	ebx,abug_externs
  call	file_delete
  mov	ebx,abug_lib
  call	file_delete
  ret
;---------------------------
;abug_externs: db '.abug_externs.dat',0
;abug_lib:     db '.abug_lib.dat',0
;----------------------------------------------------------
; dynamic linked programs do not start at entry point, they
; may have some pre code that needs to be skipped over.
goto_local_eip:
  xor	eax,eax
  cmp	[attach_pid],eax
  jnz	gle_exit		;jmp if attach active
  mov	edx,[preamble+pre.elf_phys_exec_entry]
  cmp	[r1_eip],edx	;start address ok
  je	gle_exit			;jmp if start address ok
  call	add_break
  call	insert_breaks
  xor	esi,esi			;normal restart
  call	trace_continue
  call	trace_wait
;  call	check_state		;al=state T(54)=stopped
  mov	esi,regs_1
  call	trace_regsget
  dec	dword [r1_eip]		;adjust for break byte
  call	remove_breaks
  mov	edx,[preamble+pre.elf_phys_exec_entry]
  call	remove_break
gle_exit:
  ret
;-----------------------------------------------------------
;input: al = type code 1=exec 2=write 4=read 8=bss
;output: if "jnz" true then ebx=ptr to head struc
;        if "jz" true then pheader not found 
find_pheader_type:
  lea	esi,[preamble+pre.pheader_ptrs]
fpt_lp:
  mov	ebx,[esi]	;get pointer
  or	ebx,ebx
  jz	fpt_fail	;jmp if not found
  test	[ebx+head.p_flags],al ;check type
  jnz	fpt_found	;jmp if found
  add	esi,4
  jmp	short fpt_lp
fpt_fail:
fpt_found:
  ret

 
;----------------------------------------------------------

;input: edx=physical address
;output: none
code_hunt_if:
  call	physical2offset
  call	offset2flag_ptr
  test	byte [edx],80h		;code here?
  jnz	chi_exit		;jmp if known code here
  or	byte [edx],80h		;set code here
  mov	byte [do_hunt],1
  mov	[hunt_initial_offset],ebp
  call	code_hunt
chi_exit:
  ret
;---------------------------
;eax = error ptr
show_error:
  push	eax
  mov	ecx,pre_msg
  call	crt_str
  pop	ecx
  call	crt_str
  mov	ecx,post_msg
  call	crt_str
  call	read_one_byte
  ret
;--------
  [section .data]
pre_msg: db 0ah,'AsmBug error ',0
post_msg: db 0ah,'Press <enter> to continue ',0ah,0
  [section .text]
;---------------------------
sighup_signal:
  mov	[msg_ptr],dword sighup_msg  
   ret

  [section .data]
sighup_msg: db 2,sm_size
sm_start: db 'sighup signal, ignored'
sm_size	equ $ - sm_start

;window_resize	db 0	;0=no winch 1=had winch
;winch_expected_flag db 0 ;0=not expected 1=ignore next winch
window_delay_count dd 0

  [section .text]

;winch_signal:
;  cmp	[winch_expected_flag],byte 0
;  je	winch_resize
;  mov	[winch_expected_flag],byte 0
;  jmp	short winch_exit
;winch_resize:
;  mov	[window_resize],byte 1
;  mov	[window_delay_count],byte 2000
;winch_exit:
;  ret
;---------------------------

;%include "x_disconnect.inc"
%include "1setup_parse.inc"
%include "1setup_app.inc"
%include "1setup_win.inc"
%include "1setup_history.inc"
%include "1setup_codehunt.inc"
%include "1setup_datahunt.inc"
%include "2brk.inc"
%include "2code.inc"
%include "2mem.inc"
%include "2reg.inc"
%include "3event_trace.inc"
%include "3event_socket.inc"
%include "4reg_win.inc"
%include "4brk_win.inc"
%include "4mem_win.inc"
%include "4code_win.inc"
%include "4common.inc"
%include "5help.inc"
%include "5reg_pop.inc"
%ifdef TRACE
%include "TRACE.inc"
%endif
;----------------------------

  [section .data]

app_mode:	db	0	;4=app stopped  8=app died 12=running  16=stepOver
event_mode:	db	0	;(or'ed bits) 1=exit request  2=warning state 4=forced stop
msg_ptr		dd	0	;-> (event_mode),(msg_size),(msg string)
send_signal	dd	0	;signal to send app

;When sighup is sent to asmbug it aborts.  This occured when trying to us
;asmbug in asmfile. By capturing sighup we are doing a "nohup"
signal_table:

  db	1		;sighup
sig_mod2:
  dd	sighup_signal
  dd	0
  dd	0
  dd	0

  db 0	;temp

;  db	28		;winch
;  dd	winch_signal
;  dd	0
;  dd	0
;  dd	0

;  db	0		;end of install table

termios:	times 44 db 0
;  [section .bss]

%include "../ElfDecode/elfdecode.inc"
