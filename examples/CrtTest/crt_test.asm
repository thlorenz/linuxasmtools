
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
;------------ crt_test ---------------------------
;
; usage crt_test [char]
;                if any char entered, program displays and exits
;                if no char entered, menu appears
;%define bug

struc termios_struc
.c_iflag: resd 1
.c_oflag: resd 1
.c_cflag: resd 1
.c_lflag: resd 1
.c_line: resb 1
.c_cc: resb 19
endstruc
;termios_struc_size:

 [section .text]
  extern env_stack
  extern crt_str
  extern key_mouse2
  extern byte2hexascii
  extern kbuf
  extern read_termios_0
  extern str_move
  extern dword_to_hexascii
  extern dword2hexascii
  extern dword_to_ascii
  extern crt_clear
  extern find_env_variable
  extern lib_buf
  extern terminal_report
  extern read_stdin
  extern terminal_type
;%include "terminal_type.inc"
  extern read_window_size
;%include "read_winsize.inc"
  extern save_cursor,restore_cursor
  extern read_winsize_0
  extern crt_rows
  extern crt_columns
;  extern root_pix_rows
;  extern root_pix_cols
;  extern win_pix_rows
;  extern win_pix_cols

  extern term_type
  extern screen_size
  extern win_size
  extern win_txt_size

  extern read_termios_0
  extern output_termios_0
  [section .text]
;-----------------------------
  global _start
  global main

_start:
main:
  call	env_stack
  mov	edx,termios_save
  call	read_termios_0
  call	crt_clear
;show $TERM variable
  call	show_term
;show termios
  call	show_termios
;show screen size from ioctl
  call	show_size
  call	show_size2
  call	show_size3

  mov	esi,esp			;get stack ptr
  lodsd				;get first entry on stack
  dec	eax			;if count=1 then no parameters
  or	eax,eax
  jnz	crt_exit
menu_loop:
  mov	ecx,eol
  call	crt_str
  call	menu			;returns key in kbuf
  jc	crt_exit
  and	eax,0fh			;isolate number
  shl	eax,2			;convert to dword ptr
  add	eax,table
  mov	eax,[eax]
  call	eax
  jmp	short menu_loop

crt_exit:
  mov	edx,termios_save
  call	output_termios_0
  mov	ecx,eol
  call	crt_str
  xor	ebx,ebx
  xor	eax,eax
  inc	eax
  int	byte 80h		;exit

;---------
  [section .data]
eol: db 0ah,0
;---------
table:
 dd reset	;0
 dd clear	;1
 dd status	;2
 dd cursor	;3
 dd draw_on	;4
 dd draw_off	;5
 dd norm_screen	;6
 dd alt_screen	;7
 dd lib_test	;8
 dd null
  [section .text]       
;-------------------------------------------------------
reset:	;0
  mov	ecx,reset_msg
  call	crt_str
  ret
reset_msg:  db  1bh,'c',0
;-------------------------------------------------------
clear:		;1
  mov	ecx,clear_msg
  call	crt_str
  ret
clear_msg: db 1bh,'[2J',0
;-------------------------------------------------------
status:	;2
  mov	ecx,status_msg
  call	crt_str
  mov	ecx,char_msg
  call	terminal_report
  mov	ecx,kbuf+1
  call	crt_str
  mov	ecx,eol
  call	crt_str
  ret
char_msg  db  1bh,'[5n',0  ;cursor posn
status_msg: db 'status ([5n) reports: ',0
;-------------------------------------------------------
cursor:	;3
  mov	ecx,cursor_report
  call	crt_str
  mov	ecx,parm_msg
  call	terminal_report
  mov	ecx,kbuf+1
  call	crt_str
  mov	ecx,eol
  call	crt_str
  ret	
parm_msg: db 1bh,'[6n',0
cursor_report: db 'current cursor report=',0
;-------------------------------------------------------
draw_on:	;4
  mov	ecx,base_msg
  call	crt_str
  call	display_chars
  mov	ecx,g1_select
  call	crt_str
  ret
base_msg: db 1bh,')0',0eh,0	;line draw set
;-------------------------------------------------------
draw_off:	;5
  mov	ecx,g1_select
  call	crt_str
  call	display_chars
  ret
g1_select: db 0fh,0		;normal char set
;-------------------------------------------------------
norm_screen:	;6
  mov	ecx,norm_msg
  call	crt_str
  mov	ecx,norm_msg2
  call	crt_str
  ret
norm_msg  db  1bh,'[?47l',0
norm_msg2: db 0ah,'normal screen select sent',0
;-------------------------------------------------------
alt_screen:	;7
  mov	ecx,alt_msg
  call	crt_str
  mov	ecx,alt_msg2
  call	crt_str
  ret
alt_msg  db  1bh,'[?47h',0
alt_msg2: db 0ah,'alternate screen select sent',0
;-------------------------------------------------------
lib_test:	;8
;-- crt_type
  mov	ecx,ct_msg
  call	crt_str
  call	terminal_type
  mov	ecx,[term_type]
  mov	edi,lib_buf
  call	dword_to_ascii
  mov	word [edi],0ah
  mov	ecx,lib_buf  
  call	crt_str
  mov	ecx,eol
  call	crt_str
;-- read_winsize_0
  mov	ecx,rw_msg
  call	crt_str
  mov edx,buffer
  call	read_winsize_0

  xor	eax,eax
  mov   ax,[edx]
  mov	edi,rw_msg1
  call	dword_to_ascii
  mov	byte [edi],' '
  mov	ecx,rwsize_msg1
  call	crt_str

  xor	eax,eax
  mov	ax,[buffer+winsize_struc.ws_col]
  mov	edi,rw_msg2
  call	dword_to_ascii
  mov	byte [edi],' '
  mov	ecx,rwsize_msg2
  call	crt_str

  xor	eax,eax
  mov	ax,[buffer+winsize_struc.ws_xpixel]
  mov	edi,rw_msg3
  call	dword_to_ascii
  mov	byte [edi],' '
  mov	ecx,rwsize_msg3
  call	crt_str

  xor	eax,eax
  mov	ax,[buffer+winsize_struc.ws_ypixel]
  mov	edi,rw_msg4
  call	dword_to_ascii
  mov	byte [edi],' '
  mov	ecx,rwsize_msg4
  call	crt_str
  mov	ecx,eol
  call	crt_str

;-- terminal_type
  mov	ecx,tr_msg
  call	crt_str
  call	terminal_type
  cmp	al,1
  je	console
  cmp	al,2
  je	clone
  cmp	al,3
  jne	skip_tt
  mov	ecx,xterm_msg
  call	crt_str
  jmp	short skip_tt
console:
  mov	ecx,console_msg
  call	crt_str
  jmp	short skip_tt
clone:
  mov	ecx,clone_msg
  call	crt_str
skip_tt:
  mov	ecx,eol
  call	crt_str
;---- screen_size
  mov	ecx,ss_msg
  call	crt_str
  call	screen_size
  push	ebx		;save pix height
  mov	edi,ss_insert1
  call	dword_to_ascii
  mov	byte [edi],' '
  mov	ecx,ss_msg1
  call	crt_str

  pop	eax
  mov	edi,ss_insert2
  call	dword_to_ascii
  mov	byte [edi],' '
  mov	ecx,ss_msg2
  call	crt_str
  mov	ecx,eol
  call	crt_str
;--win_size
  mov	ecx,ssw_msg
  call	crt_str
  call	win_size
  push	eax		;save pix height
  mov	eax,ebx
  mov	edi,ssw_insert1
  call	dword_to_ascii
  mov	byte [edi],' '
  mov	ecx,ssw_msg1
  call	crt_str

  pop	eax
  mov	edi,ssw_insert2
  call	dword_to_ascii
  mov	byte [edi],' '
  mov	ecx,ssw_msg2
  call	crt_str
  mov	ecx,eol
  call	crt_str
;-- win_txt_size
  mov	ecx,wts_msg
  call	crt_str
  call	win_txt_size
  push	eax		;save pix height
  mov	eax,ebx
  mov	edi,wts_insert1
  call	dword_to_ascii
  mov	byte [edi],' '
  mov	ecx,wts_msg1
  call	crt_str

  pop	eax
  mov	edi,wts_insert2
  call	dword_to_ascii
  mov	byte [edi],' '
  mov	ecx,wts_msg2
  call	crt_str
  mov	ecx,eol
  call	crt_str
   
  ret
;-------
  [section .data]
ct_msg: db 'terminal_type reports: ',0

rw_msg: db 'read_win_size_0 reports: ',0
rwsize_msg1: db 'rows='
rw_msg1:    db 0,0,0,0,0,0,0
rwsize_msg2: db 'cols='
rw_msg2:    db 0,0,0,0,0,0,0
rwsize_msg3: db 'xpix='
rw_msg3:    db 0,0,0,0,0,0,0
rwsize_msg4: db 'ypix='
rw_msg4:    db 0,0,0,0,0,0,0

tr_msg: db 'terminal_type reports: ',0
console_msg db 'console',0
xterm_msg   db 'real xterm',0
clone_msg   db 'xterm clone',0

ss_msg: db 'screen_size reports: ',0
ss_msg1: db 'pix width='
ss_insert1: db 0,0,0,0,0,0,0,0
ss_msg2: db 'pix height='
ss_insert2: db 0,0,0,0,0,0,0,0

ssw_msg: db 'win_size reports: ',0
ssw_msg1: db 'pix width='
ssw_insert1: db 0,0,0,0,0,0,0,0
ssw_msg2: db 'pix height='
ssw_insert2: db 0,0,0,0,0,0,0,0

wts_msg: db 'win_txt_size reports: ',0
wts_msg1: db 'columns='
wts_insert1: db 0,0,0,0,0,0,0,0
wts_msg2: db 'rows='
wts_insert2: db 0,0,0,0,0,0,0,0

  [section .text]
;-------------------------------------------------------
null:
  ret
;-------------------------------------------------------
; inputs; none
; output: if no-carry al=number
;         if carry abort key
menu:
  mov	ecx,menu_msg1
  call	crt_str
menu_ignore:
  call	read_stdin
  mov	al,[kbuf]
  cmp	al,30h
  jb	menu_abort
  cmp	al,39h
  ja	menu_ignore
  clc
  jmp	short menu_exit
menu_abort:
  stc
menu_exit:
  ret
  

;----------------------------
  [section .data]
menu_msg1: db 'menu 0=reset 2=status 4=draw-chars 6=norm-screen  8=lib-test',0ah
menu_msg2: db '     1=clear 3=cursor 5=norm_chars 7=alt-screen   ESC=exit',0ah,0ah,0
  [section .text]
;-------------------------------------------------------
;-------------------------------------------------------

struc winsize_struc
.ws_row:resw 1
.ws_col:resw 1
.ws_xpixel:resw 1
.ws_ypixel:resw 1
endstruc
;wnsize_struc_size

show_size:
  mov ecx,5413h
  mov edx,buffer
  xor	ebx,ebx		;get code for stdin
  mov eax,54
  int	byte 80h

  xor	eax,eax
  mov   ax,[edx]
  mov	edi,size_ins1
  call	dword_to_ascii
  mov	byte [edi],0ah
  mov	ecx,size_msg1
  call	crt_str

  xor	eax,eax
  mov	ax,[buffer+winsize_struc.ws_col]
  mov	edi,size_ins2
  call	dword_to_ascii
  mov	byte [edi],0ah
  mov	ecx,size_msg2
  call	crt_str

  xor	eax,eax
  mov	ax,[buffer+winsize_struc.ws_xpixel]
  mov	edi,size_ins3
  call	dword_to_ascii
  mov	byte [edi],0ah
  mov	ecx,size_msg3
  call	crt_str

  xor	eax,eax
  mov	ax,[buffer+winsize_struc.ws_ypixel]
  mov	edi,size_ins4
  call	dword_to_ascii
  mov	byte [edi],0ah
  mov	ecx,size_msg4
  call	crt_str
  ret
;----------------------------
  [section .data]
size_msg1: db 'ioctl 5413h (screen size) reports',0ah
 db ' rows='
size_ins1: db 0,0,0,0,0,0
size_msg2: db ' columns='
size_ins2: db 0,0,0,0,0
size_msg3: db ' xpix='
size_ins3: db 0,0,0,0,0,0,0
size_msg4: db ' ypix='
size_ins4: db 0,0,0,0,0,0,0
  [section .text]

;----------------------------

show_size2:
  mov	eax,5		;open
  mov	ebx,fb_dev
  xor	ecx,ecx		;read only
  int	byte 80h
  or	eax,eax
  js	ss_exit

  mov	ebx,eax		;fd to ebx
  mov	eax,54		;ioctl
  mov	ecx,4600h	;FBIOGET_VSCREENINFO
  mov	edx,lib_buf
  int	byte 80h

  mov	eax,6		;close
  int	byte 80h
ss_exit:
  mov	ecx,size_msg21
  call	crt_str

  mov	eax,[lib_buf]	;get x (screen width 
  mov	edi,size_ins23
  call	dword_to_ascii
  mov	byte [edi],0ah
  mov	ecx,size_msg23
  call	crt_str

  mov	eax,[lib_buf+4]
  mov	edi,size_ins24
  call	dword_to_ascii
  mov	byte [edi],0ah
  mov	ecx,size_msg24
  call	crt_str
  ret
;----------------------------
  [section .data]
fb_dev:	db "/dev/fb0",0
size_msg21: db 'ioctl 4600h (screen size) reports',0ah,0
size_msg23: db ' xpix='
size_ins23: db 0,0,0,0,0,0,0
size_msg24: db ' ypix='
size_ins24: db 0,0,0,0,0,0,0
  [section .text]
;-----------------------------------
show_size3:
  call	save_cursor
  call	read_window_size
  call	restore_cursor

  mov	eax,[crt_rows]
  mov	edi,size_insa
  call	dword_to_ascii
  mov	byte [edi],0ah
  mov	ecx,size_msga
  call	crt_str

  mov	eax,[crt_columns]
  mov	edi,size_insb
  call	dword_to_ascii
  mov	byte [edi],0ah
  mov	ecx,size_msgb
  call	crt_str

;  mov	eax,[root_pix_rows]
;  mov	edi,size_insc
;  call	dword_to_ascii
;  mov	byte [edi],0ah
;  mov	ecx,size_msgc
;  call	crt_str

;  mov	eax,[root_pix_cols]
;  mov	edi,size_insd
;  call	dword_to_ascii
;  mov	byte [edi],0ah
;  mov	ecx,size_msgd
  call	crt_str

;  mov	eax,[win_pix_rows]
;  mov	edi,size_inse
;  call	dword_to_ascii
;  mov	byte [edi],0ah
;  mov	ecx,size_msge
;  call	crt_str

;  mov	eax,[win_pix_cols]
;  mov	edi,size_insf
;  call	dword_to_ascii
;  mov	byte [edi],0ah
;  mov	ecx,size_msgf
;  call	crt_str
  ret
;----------------------------
  [section .data]
size_msga: db 'read_window_size  reports',0ah
 db ' crt_rows='
size_insa: db 0,0,0,0,0,0
size_msgb: db ' crt_columns='
size_insb: db 0,0,0,0,0
size_msgc: db ' root_pix_rows='
size_insc: db 0,0,0,0,0,0,0
size_msgd: db ' root_pix_cols='
size_insd: db 0,0,0,0,0,0,0
size_msge: db ' win_pix_rows='
size_inse: db 0,0,0,0,0,0,0
size_msgf: db ' win_pix_cols='
size_insf: db 0,0,0,0,0,0,0,0
  [section .text]

;----------------------------
show_term:
  mov	edx,term_ins1
  mov	ecx,term_str
  call	find_env_variable
;  mov	esi,lib_buf
;  mov	edi,term_ins1
;  call	str_move
  mov	byte [edi],0ah
  mov	ecx,term_msg1
  call	crt_str
  ret
;----------------------------
  [section .data]
term_str:  db 'TERM',0
term_msg1: db 0ah,'$TERM='
term_ins1: db 0,0,0,0,0,0,0,0
  [section .text]
;-----------------------------------------------------
show_termios:
  mov	edx,termios_buffer
  call	read_termios_0

  mov	esi,termios_buffer
outer_loop:
  mov	byte [count],8
  mov	edi,buffer
  push	esi
  mov	esi,pre_msg
  call	str_move
  pop	esi
st_loop:
  lodsd
  mov	ebx,eax
  add	edi,7
  call	dword2hexascii
  add   edi,9

  mov	byte [edi],' '
  inc	edi
  dec	byte [count]
  cmp	byte [count],0
  jne	st_loop			;loop till all displayed
  mov	al,0ah
  stosb
  mov	ecx,buffer	;data to write
  call	crt_str
  ret

  [section .data]
pre_msg: db 'termios= ',0
count	db	0
  [section .text]


;------------------------------------------------------
display_mouse_data:
  mov	esi,kbuf
  mov	edi,buffer
  mov	byte [edi],0ah
  inc	edi
  lodsb
dmd_lp:
  mov	bl,al
  add	edi,1
  call	byte2hexascii
  add	edi,3
  mov	byte [edi],' '
  inc	edi
  lodsb			;get next char
  or	al,al
  jnz	dmd_lp
  mov	byte [edi],0	;terminate string
  mov	ecx,buffer
  call	crt_str 
dmd_done:
  ret

;----------------------------
display_chars:
  mov	ecx,char_blk
  call	crt_str
  ret

char_blk: db 0ah
  db 'hex 0123456789abcdef',0ah
  db '--- ----------------',0ah
  db '2x  ',20h,21h,22h,23h,24h,25h,26h,27h,28h,29h,2ah,2bh,2ch,2dh,2eh,2fh,0ah
  db '3x  ',30h,31h,32h,33h,34h,35h,36h,37h,38h,39h,3ah,3bh,3ch,3dh,3eh,3fh,0ah
  db '4x  ',40h,41h,42h,43h,44h,45h,46h,47h,48h,49h,4ah,4bh,4ch,4dh,4eh,4fh,0ah
  db '5x  ',50h,51h,52h,53h,54h,55h,56h,57h,58h,59h,5ah,5bh,5ch,5dh,5eh,5fh,0ah
  db '6x  ',60h,61h,62h,63h,64h,65h,66h,67h,68h,69h,6ah,6bh,6ch,6dh,6eh,69h,0ah
  db '7x  ',70h,71h,72h,73h,74h,75h,76h,77h,78h,79h,7ah,7bh,7ch,7dh,7eh,20h,0ah
;  db '8x  ',80h,81h,82h,83h,84h,85h,86h,87h,88h,89h,8ah,8bh,8ch,8dh,8eh,8fh,0ah
;  db '9x  ',90h,91h,92h,93h,94h,95h,96h,97h,98h,99h,9ah,9bh,9ch,9dh,9eh,9fh,0ah
;  db '8x   codes 80 -> 8f contain control characters',0ah
;  db '9x   codes 90 -> 9f contain control characters',0ah
  db 'ax  ',020h,020h,0a2h,0a3h,0a4h,0a5h,0a6h,0a7h,0a8h,0a9h,0aah,0abh,0ach,0adh,0aeh,0afh,0ah
  db 'bx  ',0b0h,0b1h,0b2h,0b3h,0b4h,0b5h,0b6h,0b7h,0b8h,0b9h,0bah,0bbh,0bch,0bdh,0beh,0bfh,0ah
  db 'cx  ',0c0h,0c1h,0c2h,0c3h,0c4h,0c5h,0c6h,0c7h,0c8h,0c9h,0cah,0cbh,0cch,0cdh,0ceh,0cfh,0ah
  db 'dx  ',0d0h,0d1h,0d2h,0d3h,0d4h,0d5h,0d6h,0d7h,0d8h,0d9h,0dah,0dbh,0dch,0ddh,0deh,0dfh,0ah
  db 'ex  ',0e0h,0e1h,0e2h,0e3h,0e4h,0e5h,0e6h,0e7h,0e8h,0e9h,0eah,0ebh,0ech,0edh,0eeh,0efh,0ah
  db 'fx  ',0f0h,0f1h,0f2h,0f3h,0f4h,0f5h,0f6h,0f7h,0f8h,0f9h,0fah,0fbh,0fch,0fdh,0feh,0ffh,0

;------------------------------------------------------------------
  [section .data]
buffer: times 200 db 0
buffer_size  equ  $ - buffer

termios_buffer: times 60 db 0
termios_save:	times 60 db 0
