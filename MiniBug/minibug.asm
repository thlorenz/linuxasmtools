;------------------- file: minibug.asm ---------------------------

;%define LOG
;-----------------------------------------------------------------
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

%include "m_struc.in"
  extern crt_clear
  extern reset_terminal
  extern env_stack
  extern trace_pid
  extern trace_pid
  extern trace_wait
  extern trace_regsget
  extern trace_attach
  extern traceme
  extern trace_peek_bytes
  extern trace_regsset
  extern trace_step
  extern trace_continue
  extern read_termios_0
  extern output_termios_0
  extern terminfo_read
  extern terminfo_decode_setup
  extern install_signals
  extern term_type
  extern read_window_size
  extern crt_str
  extern move_cursor
  extern dwordto_hexascii
  extern crt_set_color
  extern crt_write
  extern dis_one
  extern trace_peek
  extern crt_rows,crt_columns
  extern read_stdin
  extern kbuf
  extern terminfo_key_decode2
  extern is_alpha
  extern byteto_hexascii
  extern blk_del_bytes
  extern trace_poke_bytes
  extern mov_color
  extern symbol_process
  extern get_text
  extern scroll_region
  extern reset_clear_terminal
  
[section .text]
  global _start
  global main
_start:
  cld
  call	env_stack		;setup env ptr
  call	save_our_termios	;(see m_setup)
  call	save_app_termios	;(see m_setup)

  mov	eax,30003770h
  call	crt_clear
;  call	reset_terminal
;  call	set_termios

  call	keyboard_setup		;(see m_setup)
  call	signal_install		;(see m_signals)
  call	m_setup			;memory setup (lib function)
  call	parse			;(see m_setup)
  js	exit_err
  call	display_setup
  call	load_app		;(see m_load_app)
  js	exit_err
  mov	eax,LastTarget
  call	elfdecode		;(see m_elfdecode)
;  call	adjust_starting_eip	;(see m_load_app) !!!disabled
  call	map_setup		;(see m_dismap)
resize_entry:
  call	display_setup		;(see m_setup)
  call	shrink_app_win
  mov	[window_resize],byte 0
main_loop:
;  call	eip_tracking		;kills find command
  cmp	[window_resize],byte 0
  jne	resize_entry		;jmp if window resize
  mov	eax,win_select_list	;window display list
  add	eax,[win_select]	;lookup current window
  call	[eax]			;call display handler
  call	read_stdin
  cmp	[window_resize],byte 0
  jne	resize_entry
  mov	esi,key_decode_tables
  add	esi,[win_select]
  mov	esi,[esi]		;get decode table
  mov	edx,kbuf
  call	terminfo_key_decode2
  or	eax,eax
  jz	main_loop		;jmp if decode error
  call	eax
  cmp	[program_abort],byte 0
  jne	exit1
  jmp	short main_loop
exit_err:
  mov	ecx,usage_msg
  call	crt_str
exit1:
  call	reset_terminal
;move cursor
;  mov	ah,[crt_rows]
;  mov	al,1
;  call	move_cursor
;  mov	eax,30003730h
;  call	crt_clear
  call	reset_clear_terminal
;kill the target program
  mov	eax,37
  mov	ebx,[trace_pid]
  or	ebx,ebx
  jz	exit2			;jmp if child not forked yet
  mov	ecx,9			;kill signal
  int	byte 80h
exit2:
  call	restore_our_termios
;  call	unset_termios

  xor	ebx,ebx			;set return code
  mov	eax,1
  int	byte 80h
;-------------------------------------------------------------------
;--------------------------------------------------------
set_termios:
  mov	edx,origional_termios
  call	read_termios_0
  mov	esi,a_line
  mov	edi,b_line
  mov	ecx,20
  rep	movsb

  mov	edx,new_termios
  call	output_termios_0
  ret
;--------------------------------------------------------
unset_termios:
  mov	edx,origional_termios
  call	output_termios_0
  ret
;-------------
  [section .data]
origional_termios:
a_iflag:	dd 0
a_oflag:	dd 0
a_cflag:	dd 0
a_lflag:	dd 0
a_line:		db 0
a_cc:	times 19 db 0
new_termios:
b_iflag:	dd 100h
b_oflag:	dd 05
b_cflag:	dd 0bfh
b_lflag:	dd 08a3bh
b_line:		db 0
b_cc:	times 19 db 0

  [section .text]
;--------------------------------------------------------

;-------------------------------------------------------------------
; commands
;-------------------------------------------------------------------

select_reg_win:
  mov	[win_select],byte 4
  ret

select_mem_win:
  mov	[win_select],byte 8
  ret

select_break_win:
  mov	[win_select],byte 12
  ret

select_stack_win:
  mov	[win_select],byte 16
  ret

select_help_win:
  mov	[win_select],byte 20
  ret
;---------------------------------------------------

;move to next window
next_window:
  mov	eax,[win_select]
  add	eax,byte 4
  cmp	eax,24		;overflow?
  jb	nw_exit		;jmp if ok
  xor	eax,eax
nw_exit:
  mov	[win_select],eax
  ret
;-------------------------------------------------------------------
next_mini_window:
  mov	al,[mini_win_select]
  inc	al
  cmp	al,4		;overflow?
  jb	nmw_exit	;jmp if ok
  xor	eax,eax
nmw_exit:
  mov	[mini_win_select],al
  ret
  
;-------------------------------------------------------------------
break_here:
  xor	eax,eax
  mov	al,[select_line#]
  sub	al,[mini_win_top_line] ;compute index
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
  ret
;-------------------------------------------------------------------
find:
  mov	eax,[hash_table_ptr]
  mov	ebx,[eax]	;top (chained entries)
  mov	[symbol_table_ptr],ebx
  mov	ecx,[eax+4]	;end
  mov	[sym_table_end],ecx
  sub	ecx,ebx
  mov	[sym_table_size],ecx
;get string to search for
  mov	eax,pre_string		;11 byte pre msg
  mov	ebx,search_buffer	;destination for string
  mov	cl,[crt_columns]	;max window size
  sub	cl,11			;adjust for pre_strning
  call	get_user_string		;get string
  call	partial_search
  jecxz	find_exit		;jmp if no match
  mov	[dis_win_top],ecx  
find_exit:
  ret  
;------------------------------------------------------------
;search symbol table
; input: search_buffer (has string)
;        [symbol_table_ptr]
;        [sym_table_size]
;        [sym_table_end]
; output: [search_ptr] - set to last match or 0 if end of table found
;         ecx = address from symbol, or  zero if failed
;       ebp - preserved
; the symbol table file starts with data + hash as follows:
;  .entries_ptr dd ;ptr to symbol entries
;  .avail_entries dd ;ptr to free space
;  .field         dd ; index into records (ignore)
;  .mask	  dd ; size of hash 
;  .hash_table  (variable size)
;  (.start of entries here)
partial_search:
  xor	eax,eax
  mov	[search_ptr],eax

;-------------------------------------------------------------
;input: [search_ptr] - last search loc. 0=start from top
;        (see partial_search)
;output:[search_ptr] updated
;       ecx = results
;       ebp - preserved 
partial_search_again:
  mov	eax,search_buffer
  mov	ecx,[app_eax]
  cmp	[eax],dword 'eax'
  je	got_register
  mov	ecx,[app_ebx]
  cmp	[eax],dword 'ebx'
  je	got_register
  mov	ecx,[app_ecx]
  cmp	[eax],dword 'ecx'
  je	got_register
  mov	ecx,[app_edx]
  cmp	[eax],dword 'edx'
  je	got_register
  mov	ecx,[app_esi]
  cmp	[eax],dword 'esi'
  je	got_register
  mov	ecx,[app_edi]
  cmp	[eax],dword 'edi'
  je	got_register
  mov	ecx,[app_ebp]
  cmp	[eax],dword 'ebp'
  je	got_register
  mov	ecx,[app_esp]
  cmp	[eax],dword 'esp'
  je	got_register
  mov	ecx,[app_eip]
  cmp	[eax],dword 'eip'
  jne	psa_symbol
got_register:
  jmp	psc_exit2

psa_symbol:  
  push	ebp
  mov	edi,[search_ptr]
  or	edi,edi
  jnz	psc_10		;jmp if search in process
  mov	eax,[symbol_table_ptr]
  mov	edi,eax
  add	eax,[sym_table_size]
  mov	[sym_table_end],eax
;edi points to entries:
;  dd chain
;  dd address of sym
;  db type
;  db name string
psc_10:
psc_lp:
  cmp	edi,[sym_table_end]
  jae	psc_fail		;jmp if end of table
      
  add	edi,4			;move to data entry
  mov	ecx,[edi]		;get symbol address
  push	ecx			;save symbol address
  add	edi,5			;move to symbol text
  mov	esi,search_buffer
  push	edi			;save sym table string start
  call	str_search
  pop	edi			;restore sym table string start
  pop	ecx			;restore symbol address
  pushf				;save str_search result falg
;scan to end of this record
psc_lp2:
  inc	edi
  cmp	byte [edi],0		;end of string?
  jne	psc_lp2			;loop till end of string
  inc	edi
psc_20:
  mov	[search_ptr],edi	;save search point
  popf
  jc	psc_lp			;jmp if no match
  jmp	short psc_exit		;exit with ecx=address
;name not found, restart search
psc_fail:
  xor	ecx,ecx
  mov	[search_ptr],ecx
psc_exit:
  pop	ebp
psc_exit2:
  ret
  
;-------------------
  [section .data]


pre_string: db 'find text: ',0
;---------------
search_ptr: dd 0
sym_table_end: dd 0	;ptr to end of symbol table
symbol_table_ptr dd 0
sym_table_size	dd 0

search_buffer	times 20 db 0
;----------------
  [section .text]
;-------------------------------------------------------------------
;input: eax=pre string msg, length 11 bytes
;       ebx=buffer to hold output string
;       cl=window/buffer size
;output: string in buffer
;
get_user_string:
;intialize input buffer
  push	eax
  push	ecx
  mov	edi,string_buf
  mov	al,' '
  mov	ecx,string_buf_size
  rep	stosb
  pop	ecx
  pop	eax
;entry with pre-set string in string_buf
;eax=pre msg ptr
;ebx=output buffer
; cl=window/buffer size
edit_user_string:
  mov	[pre_msg_ptr],eax
  mov	[results_buf_ptr],ebx

  mov	[st_len],cl		;store window size
  mov	[st_buf_size],cl	;store buffer size

  mov	eax,[crt_columns]
  sub	al,11
  cmp	al,cl			;is window too big for screen?
  jae	eus_20			;jmp if window size ok
  mov	[st_len],al		;store window size
eus_20:
  mov	ah,[mini_win_end_line]
  mov	[st_row],ah
  mov	al,12
  mov	[st_col],al
  mov	[st_col+1],al
  mov	al,1
  call	move_cursor
  mov	ecx,[pre_msg_ptr]	;pre_string
  call	crt_str
  mov	ebp,string_table
  call	get_text
;move data to callers buffer
  mov	esi,string_buf
  mov	edi,[results_buf_ptr]
  xor	ecx,ecx
  mov	cl,[st_buf_size]	;get buffer size
eus_lp:
  lodsb
  cmp	al,' '
  je	eus_end
  stosb
  loop	eus_lp
eus_end:
  mov	[edi],byte 0

;  xor	ecx,ecx
;  mov	cl,[st_col+1]	;get current column
;  sub	cl,[st_col]	;compute string size
;  mov	esi,string_buf
;  mov	edi,[results_buf_ptr]
;  rep	movsb
;  mov	[edi],byte 0	;terminate string
  ret
;------------
  [section .data]
pre_msg_ptr: dd 0
results_buf_ptr: dd 0


string_table:
  dd	string_buf
st_buf_size:
  dd	string_buf_size
  dd	menu_color
st_row:
  db	0		;row
st_col:
  db	40		;column
  db    40		;initial column
st_len:
  dd	24		;window length
st_scroll:
  dd	0		;scroll

string_buf_size	equ	140
string_buf:
  times	string_buf_size db ' '
  db	0,0		;extra byte at end of stirng

  [section .text]
;-------------------------------------------------------------------
find_next:
  call	partial_search_again
  jecxz	fn_exit
  mov	[dis_win_top],ecx
fn_exit:
  ret
;-------------------------------------------------------------------
quit:
  mov	[program_abort],byte 1
  ret
;-------------------------------------------------------------------
mini_help:
  or	[mini_win_select],byte 80h
  ret
;-------------------------------------------------------------------
cmd_key_up:
  mov	al,[select_line#]
  cmp	al,[mini_win_top_line]
  jne	cku_up
  call	find_prev
  jc	cku_exit		;exit if error
  mov	[dis_win_top],eax
  jmp	short cku_exit
cku_up:
  dec	byte [select_line#]
cku_exit:
;  or	[app_mode],byte 10h	;force display update
  ret

;----------------------------------------------------------
cmd_key_down:
  mov	al,[select_line#]
  inc	al
  cmp	al,[mini_win_end_line]
  jb	ckd_down
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
;  or	[app_mode],byte 10h	;force display update
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



;-----------------------------------------------------------------
show_main_win:
  mov	eax,menu_txt		;get text for main menu
  test	[app_mode],byte 2	;app dead?
  jz	smw_10			;jmp if app alive
  mov	eax,dead_menu
smw_10:
  call	show_menu_line
  call	show_dis_window
  call	show_mini_window
  call	show_popup		;show popup msg box
  jc	show_main_win		;restore display if pop up occured
  ret
;-------------------------------------------------------------------
show_mini_window:
  mov	al,[mini_win_select]
  test	al,80h
  jz	dl_04				;jmp if no help
;show help
  and	al,7fh				;remove help flag
  mov	[mini_win_select],al
  mov	ecx,mini_help_msg
  call	show_mini_help
  jmp	short dl_tail
dl_04:
  cmp	al,0	;reg window?
  jne	dl_10
  call	reg_window
  jmp	short dl_tail
dl_10:
  cmp	al,1	;memory window?
  jne	dl_20
  call	mem_window
  jmp	short dl_tail
dl_20:
  cmp	al,2	;break window?
  jne	dl_30
  call	break_window
  jmp	short dl_tail
dl_30:
  cmp	al,3	;stack window?
  jne	dl_tail
  call	stack_window
dl_tail:
  ret

;---------------------------------------------------------
enable_mini_help:
  mov	[pop_help_flag],byte 1
  ret
;---------------------------------------------------------
;input: ecx=help message, 11 lines, 23 bytes each, no eol
show_mini_help:
  push	ecx
  mov	eax,[aux_win_color]
  call	crt_set_color
  mov	al,[mini_win_top_line] ;get row
  mov	[help_row],al
  pop	ecx
help_lp:
  mov	ah,[help_row]
  mov	al,[reg_win_start_col]
  push	ecx
  call	move_cursor
  pop	ecx
  inc	byte [help_row]
  mov	edx,24
  call	crt_write
  add	ecx,24		;move to next line
  cmp	[ecx],byte 0
  jne	help_lp
  mov	[pop_help_flag],byte 0
  ret
;--------
  [section .data]
help_row	dd	0
help_buf	dd	0
help_adr	dd	0	;address in app memory
mini_help_msg:
 db 'w-next win  alt keys    '
 db 'W-next min  --------    '
 db 'g-go        m-memory win'
 db 's-step      h-help win  '
 db 'o-st over   r-reg win   '
 db 'b-brk here  s-stack win '
 db 'f-find      d-break win '
 db 'h-manual                '
 db 'up/down                 '
 db 'pgup/pgdn               '
 db 'enter-find again        ',0
  [section .text]

extern dis_block
;----------------------------------------------------------
stack_window:
  mov	eax,[aux_win_color]
  call	crt_set_color

  mov	al,[mini_win_top_line] ;get row
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
  cmp	al,[mini_win_end_line]	;menu_line
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
;----------------------------------------------------------
break_window:
  mov	[found_break_flag],byte 0
  mov	eax,[aux_win_color]
  call	crt_set_color

  mov	al,[mini_win_top_line] ;get row
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
  cmp	al,[mini_win_end_line]	;menu_line
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

  mov	al,[mini_win_top_line] ;get row
  mov	[mem_row],al

  mov	edx,[MemWinAdr]
  mov	[mem_adr],edx		;set starting adr
  call	mem_lp
  ret

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
  cmp	al,[mini_win_end_line]	;menu_line
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
  mov	al,[mini_win_top_line] ;get row
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
  sub	edi,ecx        	;compute length
  mov	edx,edi
  call	crt_write
  ret
;----------------------------------------------------------
show_dis_window:
  mov	eax,[dis_win_top]		;get data
  mov	[dis_adr],eax		;save starting eip
  mov	[dis_loop_count],dword 10

  mov	al,[mini_win_top_line] ;get row
  mov	[dis_display_row],al

  mov	edx,[dis_adr]		;address of inst
  mov	esi,dis_raw_inst	;buffer
  mov	[dis_buf_ptr],esi	;save buffer start
  mov	edi,100			;read 100 bytes
  call	trace_peek_bytes

  mov	eax,dis_win_array
  mov	[dis_win_array_ptr],eax
dw_loop:
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
;adjust dis_buf_ptr
  mov	eax,dis_block
  xor	ecx,ecx
  mov	cl,[eax + Dis.inst_len] ;get inst length
  add	[dis_buf_ptr],ecx	;compute next inst
  add	[dis_adr],ecx		;save next inst adr
  inc	dword [dis_display_row] ;bump row
  dec	dword [dis_loop_count]  ;bump loop count
  jnz	dw_loop			;loop till done
  ret
;------------
  [section .data]
dis_adr dd 0		;addr of raw inst in app mem
dis_buf_ptr dd 0	;ptr to raw inst
dis_loop_count dd 0
dis_raw_inst:	times 100 db 0
dis_display_row: dd 0

dis_win_array:	times 11 dd 0	;address in dis win
dis_win_array_ptr: dd 0
select_line#	db 0
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
;set color for address portion
  mov	[line_end],edi		;save end of line
  mov	ebx,[dis_adr]
  call	find_break		;retruns ecx=0 if not found  
  xor	edx,edx			;init lookup flag
  jecxz	sl_20			;jmp if break not found
  or	dl,1			;set break found flag
sl_20:
  mov	bl,[dis_display_row]
  cmp	bl,[select_line#]
  jne	sl_40	;jmp if no select line here
  or	dl,02h			;set select found flag
sl_40:
  shl	edx,2
  add	edx,dis_win_color	;look up color
  mov	eax,[edx]		;get color
  call	crt_set_color
;show address portion
  mov	ecx,lib_buf+100
  mov	edx,8
  call	crt_write
;setup to show body
  xor	edx,edx			;clear lookup flag
  mov	ebx,[dis_adr]
  cmp	ebx,[app_eip]
  jne	sl_60			;jmp if eip not here
  or	dl,1			;set eip here flag
sl_60:
  mov	bl,[dis_display_row]
  cmp	bl,[select_line#]
  jne	sl_80	;jmp if no select line here
  or	dl,02h			;set select found flag
sl_80:
  shl	edx,2
  add	edx,dis_win_color2	;look up color
  mov	eax,[edx]		;get color
  call	crt_set_color

  mov	ecx,lib_buf+108
  mov	edx,[line_end]
  sub	edx,ecx
  call	crt_write
  ret
;----------
  [section .data]
line_end	dd 0
  [section .text]
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
;keep eip inside window
eip_tracking:
;  cmp	[eip_track_flag],byte 0
;  je	eip_exit		;exit if no tracking
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
;input: eax=menu line 
show_menu_line:
  push	eax		;save menu line
  mov	ah,[mini_win_end_line]	;menu_line]	;row
  mov	al,1		;column
  call	move_cursor

  pop	esi		;restore text ptr
  mov	edi,lib_buf
  mov	ecx,[crt_columns]
  call	txt_color
;normal color-space loop
ml_lp:
  lodsb
  cmp	al,0
  je	ml_pad
  cmp	al,' '
  jne	ml_high
ml_space_stuf:
  stosb
  loop	ml_lp
  jmp	short ml_show
;do highlight
ml_high:
  push	eax
  call	high_color
  pop	eax
  stosb
  call	txt_color
  jmp	short ml_tail
;normal color alpha loop
ml_alp:
  lodsb
  cmp	al,0
  je	ml_pad
  cmp	al,' '
  je	ml_space_stuf
  stosb
ml_tail:
  loop	ml_alp
  jmp	short ml_show
;add padding at end
ml_pad:
  mov	al,' '
  stosb
  loop	ml_pad
ml_show:
  mov	ecx,lib_buf	;get message address
  mov	edx,edi
  sub	edx,ecx    	;compute length of line
  call	crt_write
  ret
;-------------
  [section .data]
menu_txt:
 db ' ? win go step over-step break-here find quit help',0
dead_menu:
 db '_--(app_dead)--    ? win break-here find quit help',0

  [section .text]  

txt_color:
  mov	eax,[menu_color]
  jmp	short do_color
high_color:
  mov	eax,[menu_highlight_color]
do_color:
  push	esi
  push	ecx
  call	mov_color
  pop	ecx
  pop	esi
  ret
 

;-----------------------------------------------------------------------
;input: eax=header text
show_header_line:
  push	eax		;save header line
  mov	eax,[menu_color]
  call	crt_set_color
  mov	ah,[mini_win_top_line]	;row
  mov	al,1		;column
  call	move_cursor
  pop	esi		;restore text ptr
  call	pad_and_move_line
  mov	ecx,lib_buf	;get message address
  mov	edx,edi
  sub	edx,ecx    	;compute length of line
  call	crt_write
  ret

;-----------------------------------------------------------------------
;input esi=ptr to text
;output: lib_buf has line with pad
pad_and_move_line:
  mov	edi,lib_buf
  mov	ecx,[crt_columns]
pam_lp1:
  lodsb
  stosb
  cmp	al,0	;end?
  je	pam_part2
  loop	pam_lp1	;loop till end of window
pam_part2:
  mov	al,' '
  jecxz	pam_done
  stosb
  loop	pam_part2
pam_done:
  mov	[edi],byte 0	;terminate string
  ret

;-----------------------------------------------------------------------
;add message to last line of display
; input:  [append_msg_ptr] = byte 1 flag 0=one time  bit1=hold bit2=set dead
;                            byte 2+ asciiz message
append_to_dis:
  mov	ecx,[append_msg_ptr]
  jecxz	atd_exit	;jmp if no append msg
  push	ecx

  mov	al,1
  mov	ah,[mini_win_end_line]	;bs_bottom_row]
  dec	ah
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
;---------------------------------------------------------------------
;return carry if message active
show_popup:
  mov	esi,[pop_msg]	;get message ptr
  or	esi,esi
  jz	sp_exit1
  call	message_box
  xor	esi,esi
  mov	[pop_msg],esi
  stc			;set carry
  jmp	short sp_exit2
sp_exit1:
  clc
sp_exit2:
  ret
;-------------
  [section .data]
pop_msg:	dd 0
  [section .text]


%include "m_elfdecode.in"
%include "m_dismap.in"
%include "m_load_app.in"
%include "m_setup.in"
%include "m_signals.in"
%include "m_trace.in"
%include "m_reg.in"
%include "m_memory.in"
%include "m_stack.in"
%include "m_break.in"
%include "m_help.in"

;-------------------------------------------------------------------
  [section .data]

usage_msg:
  db 0ah,'usage: minibug [-a] [filename]',0ah,0



win_select:	dd 0 ;0=main 4=reg 8=mem 12=break 16=stack 20=help
mini_win_select:db 0 ;0=reg 1=mem 2=break 3=stack
program_abort:	db 0 ;0=no abort
pop_help_flag:  db 0 ;0=no pop help on right of mini win

win_select_list:
  dd show_main_win	;0  (see minibug)
  dd show_reg_win	;4  (see m_reg)
  dd show_mem_win	;8  (see m_mem)
  dd show_break_win	;12 (see m_break)
  dd show_stack_win	;16 (see m_stack)
  dd show_help_win	;20 (see m_help)
  dd show_run_win	;24 (see m_trace)
  dd 0	;error trap

key_decode_tables:
  dd main_key_decode
  dd reg_win_decode_tbl
  dd mem_win_decode_tbl
  dd break_win_decode_tbl
  dd stack_win_decode_tbl
  dd help_win_decode_tbl
  dd run_win_decode_tbl
  dd 0	;end of list

;main loop key decode table
main_key_decode:
  times	10 db 0	;pad
  db 2	;flag

  db '?',0
  dd mini_help

  db 'w',0
  dd next_window

  db 'W',0
  dd next_mini_window

  db 'g',0
  dd go_cmd

  db 's',0
  dd step_cmd

  db ' ',0
  dd step_cmd

  db 'o',0
  dd step_over_cmd

  db 'b',0
  dd break_here

  db 'f',0
  dd find

  db 0ah,0
  dd find_next

  db 0dh,0
  dd find_next

  db 'q',0
  dd quit

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

  db 1bh,'r',0
  dd select_reg_win
  db 0c3h,0b2h,0
  dd select_reg_win

  db 1bh,'m',0
  dd select_mem_win
  db 0c3h,0adh,0
  dd select_mem_win

  db 1bh,'b',0
  dd select_break_win
  db 0c3h,0a2h,0
  dd select_break_win

  db 1bh,'s',0
  dd select_stack_win
  db 0c3h,0b3h,0
  dd select_stack_win

  db 'h',0
  dd select_help_win
  db 1bh,'h',0
  dd select_help_win
  db 0c3h,0a8h,0
  dd select_help_win


  db 0	;end of table

; color format  attribute - foreground - background
;    30-blk 31-red 32-grn 33-brwn 34-blu 35-purple 36-cyan 37-gry
;    attributes 30-normal 31-bold 34-underscore 37-inverse

app_win_color:		 dd 30003037h
menu_color:		 dd 30003730h
menu_highlight_color	 dd 31003731h
dis_win_alert_color:	 dd 30003033h
aux_win_color:		 dd 31003735h
aux_win_menu_color:	 dd 30003234h

;address area table
dis_win_color:		 dd 30003036h	;00 no select  no break    black on cyan
dis_win_break_color:	 dd 30003136h   ;01 no seledt  break       red   on cyan
			 dd 30003033h   ;10 select     no break    black on brown
                         dd 30003133h   ;11 select     break       red   on brown
;body area table
dis_win_color2:       	 dd 30003036h	;00 no select  no eip      black on cyan
dis_win_eip_color:	 dd 30003736h   ;01 no select  eip         green on cyan
dis_win_select_color:	 dd 30003033h   ;10 select     no eip      black on brown
                         dd 30003733h   ;11 select     eip         green on brown

app_win_last_line	dd 0
mini_win_top_line	dd 0
mini_win_top_line2	dd 0
mini_win_end_line	dd 0	;same as menu line
dis_win_end_col		dd 0	;leave room for small win
reg_win_start_col	dd 0	;samll right size win

work_buf_size	equ 8097
work_buf	times work_buf_size db 0
;-------------------------------------------------------------------
  [section .bss]
