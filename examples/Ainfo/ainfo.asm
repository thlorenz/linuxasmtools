
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
;  Ainfo - view .info files by wrapping "info" program
;    Ainfo provides a simple interface to view
;    .info format files.  
; INPUTS
;    usage: ainfo <in-file>
;    The input file must be in .info format as
;    recognized by the "info" executable.     
; OUTPUT
;    none
; NOTES
;   source file:  ainfo.asm
;    
;   Ainfo calls the library function sys_wrap to
;   execute "info" and feed it keystrokes.  This
;   allows the user interface to be modified and
;   the keyboard redefined.
;
;   The arrow keys now move to topics as follows:
;   UP - move up to topic within page
;   DOWN - move down to topic within page
;   RIGHT - enter topic
;   LEFT - return to previous topic
;
;   PGDN - move down within page
;   PGUP - move up with page
;   ESC - exit (also "q" exits)
;
;   Ainfo is called by AsmMgr to view .info files.
;<
; * ----------------------------------------------
;**********  file  view_info *******************
;
; view .info files by calling "info" and transposing
; the keyboard:
;   up = esc-tab
;   down = tab
;   left = u
;   right = enter
;   esc = q
; all other keys ignored.
; the top line of display has overwrite of menu as:
;__ up=up down=down right=enter left=leave esc=exit  __
;
  extern env_stack
  extern read_termios_0
  extern output_termios_0

  extern sys_wrap_shell
;%include "sys_wrap_shell.inc"
  extern str_move
  extern stdout_str
  extern read_stdin
  extern str_end
  extern str_compare
  extern save_norm_cursor
  extern move_cursor
  extern restore_norm_cursor
  extern crt_str
  extern read_window_size
  extern crt_columns
  extern crt_rows
  extern crt_clear
  extern reset_clear_terminal

  global main,_start
main:
_start:
  call	env_stack
  call	set_termios
  call	parse
;  jnz	view_done		;exit if no file
;terminate menu line
  call	read_window_size
  mov	ecx,reset_msg
;  call	stdout_str
;  mov	eax,31003634h
;  call	crt_clear

  xor	eax,eax
  mov	al,[crt_columns]
  add	eax,top_line
  mov	byte [eax],0
  
  call	wrap
view_done:
  mov	eax,30003730h
  call	crt_clear

  call	unset_termios
  call	reset_clear_terminal
  xor	ebx,ebx			;set success return code
  mov	eax,1
  int	80h
reset_msg: db 1bh,'c',0
;--------------------------------------------------------
set_termios:
  mov	edx,origional_termios
  call	read_termios_0
  mov	esi,c_line
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
c_iflag:	dd 0
c_oflag:	dd 0
c_cflag:	dd 0
c_lflag:	dd 0
c_line:		db 0
c_cc:	times 19 db 0
new_termios:
b_iflag:	dd 100h
b_oflag:	dd 05
b_cflag:	dd 0bfh
b_lflag:	dd 08a3bh
b_line:		db 0
b_cc:	times 19 db 0

  [section .text]
;--------------------------------------------------------
wrap:
;  mov	eax,shel_cmd
  mov	esi,shel_cmd
  mov	ebx,feed_process
  mov	ecx,output_process	;output capture
;  mov	dl,0			;set flag to run program
  call	sys_wrap_shell
;the shell exited, check if error state
  push	eax
  or	al,al
  jz	launch_30		;jmp if no error reported
  je	launch_30		;jmp if error expected (ignore it)
;  mov	byte [ignore_error_flag],0
  mov	ecx,shell_err_msg
  call	stdout_str
  call	read_stdin
launch_30:
  pop	eax
  ret
;------------------
  [section .data]
shell_err_msg:
  db 'wrap error',0
  [section .text]
;-------------------------------------------------------
; input:  ecx=buffer edx=output count
output_process:
  cmp	edx,8097
  jne	op_write_buffer	;jmp if not partial buffer
;this is the end of write data, append to buffer data
  mov	edi,[buf_ptr]
  or	edi,edi
  jnz	op_append_buffer
  mov	edi,buffer
op_append_buffer:
;this partial write block, append to buffer
  mov	esi,ecx
  mov	ecx,edx
  cld
  rep	movsb
  mov	[buf_ptr],edi	;save ptr for next time
  jmp	op_exit1	;exit without writing

;this is the final write block, check if buffer has data
op_write_buffer:
  mov	edi,[buf_ptr]
  or	edi,edi
  jz	op_write_now	;jmp if buffer empty, and not partial write
;append data to buffer and write
  mov	esi,ecx
  mov	ecx,edx
  cld
  rep	movsb

  mov	ecx,buffer
  mov	edx,edi		;get final buffer loc
  sub	edx,ecx		;compute buffer count
  mov	dword [buf_ptr],0
;
; input:  ecx=buffer edx=output count
op_write_now:
  mov	eax,4		;write
  mov	ebx,1		;write to stdout
  int	80h
;
  call	save_norm_cursor
  mov	al,1
  mov	ah,[crt_rows]
  call	move_cursor
  mov	ecx,top_line
  call	crt_str
  call	restore_norm_cursor
op_exit1:
  mov	edx,0		;disable output
op_exit:
  ret
;-------------
  [section .data]
top_line: db '-- movement keys = up,down,right,left -- other keys = pgup,pgdn,esc ----------------------------------------------------------------------------',0
buf_ptr	dd	0	;0=empty buffer
  [section .text]
;-------------------------------------------------------
feed_process:

  extern log_hex
  mov	eax,[ecx]
  call	log_hex
  cld

; input: ecx=buffer edx=read length
  mov	al,[ecx]		;get first byte of key
  cmp	al,03			;is this a ctrl-c
  jne	fw_decode		;jmp if not abort key
  mov	edx,-1
  jmp	fw_exit
fw_decode:
  mov	esi,key_table       	;get key control table
  cld
fw_decode_loop:
  mov	[table_ptr],esi
  mov	edi,ecx 		;edi=key data from sys_wrap
  call	str_compare		;compare two strings
  je	fw_match		;jmp if strings match
;strings do not match
  mov	esi,[table_ptr]
  call	str_end			;move to zero byte at end of match str
  inc	esi
  call	str_end			;move to zero byte at end of replace str
  inc	esi
  cmp	byte [esi],0		;at end of table?
  jne	fw_decode_loop		;loop if more table entries
;no match for this key press, return null key
  xor	edx,edx			;zero buffer length
  jmp	fw_exit

;no_match: db "no match",0ah,0
;got_match: db "got match",0ah,0

;key found, esi=ptr to zero at end of table string
fw_match:
  inc	esi			;move to replacement string
  mov	edi,ecx			;get data buffer ptr
  mov	edx,-1			;set length to -1
key_stuff_loop:
  lodsb
  stosb
  inc	edx
  or	al,al
  jnz	key_stuff_loop
fw_exit:			;not shell, not ctrl-c,
  ret
;------------------------
  [section .data]
;the following align fixes a problem when in  rxvt terminall.
;for some reason the memory is mapped wrong and the key table
;is not seen by code?
;
  align 4
table_ptr:	dd	0
; the rxvt terminal failed if the following db is not present?
; this must be a memory problem with ?

;	db	0

key_table:
  db	1bh,0,'q',0			; esc -> q (exit)
  db	'q',0,'q',0			; q   -> q (exit)
 
  db 1bh,4fh,41h,0,1bh,09h,0		; pad_up -> esc-tab
  db 1bh,5bh,41h,0,1bh,09h,0		; pad_up -> esc-tab
  db 1bh,4fh,78h,0,1bh,09h,0		; pad_up -> esc-tab

  db 1bh,4fh,42h,0,09h,0		; pad_down -> tab
  db 1bh,5bh,42h,0,09h,0		; pad_down -> tab
  db 1bh,4fh,72h,0,09h,0		; pad_down -> tab

  db 1bh,4fh,43h,0,0ah,09h,0		; pad_right -> enter
  db 1bh,5bh,43h,0,0ah,09h,0		; pad_right -> enter
  db 1bh,4fh,76h,0,0ah,09h,0		; pad_right -> enter

  db 1bh,4fh,44h,0,'l',0		; pad_left -> l
  db 1bh,5bh,44h,0,'l',0		; pad_left -> l
  db 1bh,4fh,74h,0,'l',0		; pad_left -> l

  db ' ',0,' ',0			; space(page down)
  db 1bh,5bh,36h,7eh,0,' ',0;pad_pgdn
  db 1bh,4fh,36h,7eh,0,' ',0;pad_pgdn
  db 1bh,4fh,73h,0,' ',0    ;pad_pgdn
  db 7fh,0,7fh,0			; backspace(page up)
  db 08h,0,08h,0			; backspace(page up)
  db 1bh,5bh,35h,7eh,0,7fh,0;pad_pgup
  db 1bh,4fh,35h,7eh,0,7fh,0;pad_pgup
  db 1bh,4fh,79h,0,7fh,0    ;pad_paup
  db	0


  [section .text]


;--------------------------------------------------------
; parse - set parsed_file
;  inputs: esp = origional esp at program entry with one push
;  output: if eax=0 then parse_file has name
;          if eax non zero then error
;
parse:
  mov	esi,esp			;get ptr to parameters
  lodsd				;clear return address from stack
  lodsd				;get parameter count
  mov	ecx,eax
  cmp	cl,2
  jne	pcl_err			;jmp if parameter error
  lodsd				;get ptr to executable file name
  lodsd				;get ptr to parameter 1
  mov	esi,eax
;save ptr to file name
  mov	edi,parsed_file
  call	str_move
  xor	eax,eax			;set success
pcl_err:
  or	eax,eax
  ret

;-----------------------
  [section .data]
shel_cmd: db 'info',0
;shel_cmd: db 'info '
parsed_file: times 200 db 0
  [section .text]
;------------------------
 [section .bss]
buffer	resb	9000
 [section .text]
