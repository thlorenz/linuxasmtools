
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
;
;>1 utility
;  AsmTimer - Time execution of a program
; INPUTS
;    usage: asmtimer [file]<Enter>
;    No inputs are required for AsmTimer
; OUTPUT
;    none
; NOTES
;   source file:  asmtimer.asm
;    
;<
; * ----------------------------------------------
;
;
  extern crt_clear
  extern env_stack
  extern string_form
  extern str_move
  extern read_stdin
  extern kbuf
  extern ascii_to_dword
  extern stdout_str
  extern dword_to_l_ascii
  extern crt_str
;  extern sys_shell_cmd
  extern move_cursor
  extern read_termios_0
  extern output_termios_0
  extern reset_clear_terminal

struc event
.computed_time    resd	 1	;stop_time - start_time
.kernel_user_time resd	 1	;from rusage struc first entry (dword)
.kernel_system_time resd 1	;from rusage struc second entry
.run_number	  resd	 1
.start_time	  resd	 1
.stop_time	  resd	 1
event_struc_size:
endstruc

  global main,_start
main:
_start:
  cld
  mov	eax,[background_color]
  call	crt_clear
  call	env_stack

  mov	edx,termios
  call	read_termios_0
  mov	ecx,no_wrap
  call	stdout_str

  pop	ebx			;get parameter count
  dec	ebx			;dec parameter count
  jz	short top		;jmp if no parameters entered
  pop	esi			;get ptr to our executable name

 mov	edi,buf1_start
build_parm_lp:
  pop	esi			;get next parameter
  or	esi,esi
  jz	top
  call	str_move
  mov	byte [edi],' '	;force space at end
  inc	edi
  jmp	short build_parm_lp

top:
  mov	ebp,time_tbl_pointers
  call	string_form
  mov	eax,[kbuf]		;get key
  cmp	al,0ah			;enter key
  je	enter_key
  cmp	al,0dh
  je	enter_key
  cmp	al,-1			;mouse?
  jne	other_key
  shr	eax,16			;set al=colun ah=row
  cmp	ah,7
  jne	other_key		;jmp if not row 7
  cmp	al,9
  ja	other_key		;jmp if not <enter> click
  jmp	short form_ready
enter_key:
  cmp	[active_def],dword string1_def
  jne	form_ready
  mov	[active_def],dword string2_def
  jmp	top			;go get more data
other_key:
  jmp	do_exit			;assume all othrs are cancel

form_ready:
  call	extract_data_from_form
  call	setup_database
  call	timer			;start timing
  jc	error
  call	compute_averages
  call	sort_array		;also set fastest and slowest
  call	display_results
  call	read_stdin		;get key
  mov	eax,[kbuf]		;eax=key code
  cmp	al,'r'  
  je	top			;jmp if another timing
do_exit:
  mov	edx,termios
  call	output_termios_0

;  mov	eax,[background_color]
;  call	crt_clear
;  mov	ax,0101h
;  call	move_cursor
  call	reset_clear_terminal

  xor	ebx,ebx
  mov	eax,1
  int	byte 80h				;exit
;
error:
  mov	eax,[background_color]
  call	crt_clear
  mov	ecx,err1
  call	crt_str
  call	read_stdin
  jmp	do_exit  
;--------------------------------------------------------------------
extract_data_from_form:
  mov	ebx,buf1_end            ;point to end of buffer
;find end of execution string
edff_lp1:
  dec	ebx
  cmp	word [ebx],' '
  je	edff_lp1		;loop till first valid char found
;move execution string
  mov	esi,buf1_start    
  mov	edi,program_to_time
ediff_lp2:
  lodsb
  stosb
  cmp	esi,ebx
  jbe	ediff_lp2		;loop till string moved
  xor	eax,eax
  stosd				;put zero at end of execution string
;convert "repeat_count" to binary
  mov	esi,buf2_start
  call	ascii_to_dword		;result in ecx
  mov	[repeat_count],ecx
  ret
;--------------------------------------------------------------------
setup_database:
  mov	[repeat_counter],dword 1	;starting value
  mov	[array_stuff],dword array
  mov	[array_fastest],dword 0
  mov	[array_slowest],dword 0
  mov	[index_stuff],dword index_list
  mov	[index_list],dword array
  mov	[average_computed_time],dword 0
  mov	[average_user_time],dword 0
  mov	[average_system_time],dword 0

  xor	eax,eax
  mov	edi,index_list
  mov	ecx,array_buf_end
  sub	ecx,edi			;compute length of .bss buffers
  rep	stosb			;clear buffers
  ret
;--------------------------------------------------------------------
; inputs:
;    array_stuff  ;ptr to current array stuff point
timer:
;get current time and save it
  call	get_time		;returns milliseconds in eax
  mov	edi,[array_stuff]
  mov	[edi+ event.start_time],eax
;execute program
  mov	esi,program_to_time
  call	sys_run_wait
  jnz	timer_done1		;jmp if  error
  push	eax

;save times, get current time and save it, get user & system time
  call	get_time
  mov	edi,[array_stuff]
  mov	[edi + event.stop_time],eax

  mov	eax,[ru_utime_u]		;get microseconds
  xor	edx,edx
  mov	ebx,1000
  call	quad_divide			;compute miliseconds
  mov	[edi + event.kernel_user_time],eax
  mov	eax,[ru_stime_u]		;get microseconds
  xor	edx,edx
  mov	ebx,1000
  call	quad_divide			;compute miliseconds
  mov	[edi + event.kernel_system_time],eax

  mov	eax,[repeat_counter]
  mov	[edi + event.run_number],eax	;update array ptr

  mov	ebx,[index_stuff]
  mov	[ebx],edi			;update index ptr

  pop	eax
;program error? report now
;update loop counters, index_stuff, array_stuff, loop_counter
  add	[array_stuff],dword event_struc_size
  add	[index_stuff],dword 4		;move to next index position

  mov	eax,[repeat_counter]
  cmp	eax,[repeat_count]
  je	timer_done2
  inc	eax				;bump  repeat counter
  mov	[repeat_counter],eax
  jmp	timer
timer_done1:
  stc
  jmp	short timer_done
timer_done2:
  clc				;go do it again
timer_done:
  ret  
;--------------------------------------------------------------------
sort_array:
  mov	ebp,index_list
  xor	edx,edx			;sort on first column
  mov	ecx,[repeat_count]	;get sort length
  call	sort_dword_array3  
  ret
;--------------------------------------------------------------------
; compute:  stop_time - start_time -> computed_time
;           average_computed_time
;           average_user_time
;           average_system_time
compute_averages:
  mov	esi,array
  xor	eax,eax
  mov	[repeat_counter],eax
  mov	[average_computed_time],eax
  mov	[average_user_time],eax
  mov	[average_system_time],eax
ca_loop:
  mov	eax,[esi + event.stop_time]
  sub	eax,[esi + event.start_time]
  mov	[esi + event.computed_time],eax

  add	[average_computed_time],eax
  mov	eax,[esi +  event.kernel_user_time]
  add	[average_user_time],eax
  mov	eax,[esi + event.kernel_system_time]
  add	[average_system_time],eax

  add	esi,dword event_struc_size
  mov	eax,[repeat_counter]
  inc	eax
  mov	[repeat_counter],eax
  cmp	eax,[repeat_count]
  jne	ca_loop

  xor	edx,edx
  mov	eax,[average_computed_time]
  mov	ebx,[repeat_count]
  call	quad_divide
  mov	[average_computed_time],eax

  xor	edx,edx
  mov	eax,[average_user_time]
  mov	ebx,[repeat_count]
  call	quad_divide
  mov	[average_user_time],eax

  xor	edx,edx
  mov	eax,[average_system_time]
  mov	ebx,[repeat_count]
  call	quad_divide
  mov	[average_system_time],eax
  ret  
;--------------------------------------------------------------------
; input: see database
display_results:
  mov	esi,array
  xor	eax,eax
  mov	[repeat_counter],eax
  mov	eax,[background_color]
  call	crt_clear

  mov	ecx,title_msg
  call	stdout_str

dr_loop:
  mov	eax,[esi + event.run_number]
  mov	edi,run_insert
  push	esi
  mov	esi,2
  call	dword_to_l_ascii
  pop	esi

  mov	eax,[esi + event.computed_time]
  mov	edi,comput_insert
  push	esi
  mov	esi,8
  call	dword_to_l_ascii
  pop	esi


  mov	eax,[esi + event.kernel_user_time]
  mov	edi,user_insert
  push	esi
  mov	esi,8
  call	dword_to_l_ascii
  pop	esi


  mov	eax,[esi + event.kernel_system_time]
  mov	edi,system_insert
  push	esi
  mov	esi,8
  call	dword_to_l_ascii
  pop	esi

  push	esi
  mov	ecx,result_msg
  call	stdout_str
  pop	esi

  add	esi,dword event_struc_size
  mov	eax,[repeat_counter]
  inc	eax
  mov	[repeat_counter],eax
  cmp	eax,[repeat_count]
  jne	dr_loop

  ;--

  mov	ecx,av_title_msg
  call	stdout_str

  mov	eax,[average_computed_time]
  mov	esi,8
  mov	edi,av_comp_insert
  call	dword_to_l_ascii

  mov	eax,[average_user_time]
  mov	esi,8
  mov	edi,av_user_insert
  call	dword_to_l_ascii

  mov	eax,[average_system_time]
  mov	esi,8
  mov	edi,av_system_insert
  call	dword_to_l_ascii

  mov	ecx,av_result_msg
  call	stdout_str

;--

  mov	esi,[index_list]	;get smallest run
  mov	eax,[esi + event.computed_time]
  mov	esi,8
  mov	edi,m_stuff
  call	dword_to_l_ascii

  mov	eax,[average_user_time]
  add	eax,[average_system_time]
  mov	esi,8
  mov	edi,s_stuff
  call	dword_to_l_ascii

  mov	ecx,best_msg
  call	stdout_str
  ret
;--------------------------------------------------------------------
; get_time - get current time
;  inputs: none
;  output: eax = time in miliseconds
;
get_time:
  mov	eax,78			;get time function
  mov	ebx,time_block		;area to store time
  xor	ecx,ecx			;no time zone info
  int	80h
  cmp	byte [first_call_flag],0
  jne	gt_10			;jmp if not first time
  inc	byte [first_call_flag]
  mov	eax,[seconds]
  mov	[base_seconds],eax	;save base
gt_10:
;compute miliseconds
  mov	eax,[seconds]		;compute seconds delta
  sub	eax,[base_seconds]
  mov	ebx,1000
  mul	ebx			;convert seconds to miliseconds
  mov	[computed_miliseconds],eax

  mov	eax,[microseconds]
  xor	edx,edx
  mov	ebx,1000
  call	quad_divide
  add	[computed_miliseconds],eax
  
  mov	eax,[computed_miliseconds]
  ret  
;---
  [section .data]
first_call_flag	db	0

time_block:
seconds:	dd	0
microseconds:	dd	0

base_seconds:	dd	0	;from first call

computed_miliseconds: dd	0

  [section .text]
;--------------------------------------------------------------------

%include "sys_run.inc"
;%include "sys_shell_cmd.inc"
%include "sort_dword_array3.inc"
%include "quad_divide.inc"

;********************************************************************
;********************************************************************

  [section .data]

no_wrap	db 1bh,'[?7l',0
background_color dd 30003730h
err1: db 0ah,'Executable not found',0ah
      db ' press any key to continue',0
;----------------------------------------------------------------
; The screen form follows.
;          info block is defined as follows:
;
;          struc in_block
;           .iendrow resb 1 ;rows in window
;           .iendcol resb 1 ;ending column
;           .istart_row resb 1 ;starting row
;           .istart_col resb 1 ;startng column
;           .icursor resd 1 ;ptr to string block with active cursor
;           .icolor1 resd 1 ;body color
;           .icolor2 resd 1 ;highlight/string color
;           .itext  resd 1 ;ptr to text
;          endstruc
;
;          the text pointed at by .itext has normal text and
;          imbedded string using the following format:
;
;          struc str_def
;           .srow  resb 1 ;row
;           .scol  resb 1 ;col
;           .scur  resb 1 ;cursor column
;           .scroll  resb 1 ;scroll counter
;           .wsize  resb 1 ;columns in string window
;           .bsize  resb 1 ;size of buffer, (max=127)
;          endstruc


time_tbl_pointers:
 db 15	;ending row
 db 60  ;ending column
 db 1	;starting row
 db 1	;startng column
active_def:
 dd string1_def ;string with cursor
 dd 30003634h	;text color
 dd 30003136h	;string color
 dd test_form	;form def ptr

test_form:
 db '  ***** PROGRAM TIMER (AsmTimer) *****',0ah
 db 0ah
 db 'command to time '
string1_def:
 db -1  ;start of string def
 db 3	;row
 db 17	;column
 db 17	;current cursor posn
 db 0	;scroll
 db 38 ;window size
 dd buf1_end - buf1_start ;buf size (max=127)
 db -2	;end of string def
buf1_start:
 times 250 db " "
buf1_end:
 db ' ',0ah,0ah

 db 'repeat count '
string2_def:
 db -1  ;start of string def
 db 5	;row
 db 14	;column
 db 14	;current cursor posn
 db 0	;scroll
 db 2  ;window size
 dd buf2_end - buf2_start ;buf size (max=127)
 db -2	;end of string def
buf2_start:
 db '1 '
buf2_end:
 db ' ',0ah,0ah

 db '  <Enter>=begin   <ESC>=cancel',0

;-------------- text strings   ----------------

title_msg:
 db 0ah
 db 'All times are in miliseconds.  Kernel times are from',0ah
 db 'the wait4 return status (rusage structure).',0ah
 db ' RUN#  Measured  Kernel    Kernel ',0ah
 db '       Time      User      System ',0ah
 db ' ---   --------  --------  --------',0ah,0

result_msg:
 db ' '
run_insert:
 db '  '
 db '    '
comput_insert:
 db '        '
 db '  '
user_insert:
 db '        '
 db '  '
system_insert:
 db '        '
 db 0ah,0

av_title_msg:
 db 0ah
 db ' average-Measured   average-user  average-system',0ah,0

av_result_msg:
 db ' '
av_comp_insert:
 db '        '
 db '           '
av_user_insert:
 db '        '
 db '      '
av_system_insert:
 db '        '
 db 0ah
 db 0

best_msg:
 db 0ah
 db 'Since Linux is a multiuser system these times are not accurate',0ah
 db 'The actual time is probably the smallest measured and the sum',0ah
 db 'of average system times',0ah
 db 0ah
 db 'Smallest_Measured_time='
m_stuff:
 db '           '
 db 'System_average='
s_stuff:
 db '        ',0ah,0
;-------------- timer database ----------------

repeat_count:	dd	0	;from form
repeat_counter	dd	0	;loop control (1+)
index_stuff	dd	0	;ptr to array index list stuff point

array_stuff	dd	0	;ptr to current array stuff point
array_fastest	dd	0	;ptr to array fastest
array_slowest	dd	0	;ptr to array slowest

average_computed_time:	dd 0
average_user_time:	dd 0
average_system_time:	dd 0

;----------------------------------------------
  [section .bss]

termios:	resb	36

program_to_time: resb	200
index_list:	resd	50
array:		resb	20000
array_buf_end:
