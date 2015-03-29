
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

  extern crt_open,crt_close
  extern sys_win_alt,sys_win_normal
  extern reset_terminal
  extern mouse_enable
  extern sys_wrap
  extern kbuf
  extern crt_str
  extern key_mouse2
  extern str_move
  extern is_raw_term
  extern output_termios_0
  extern save_cursor
  extern restore_cursor
  extern delay

  [section .text]

struc wnsize_struc
.ws_row:resw 1
.ws_col:resw 1
.ws_xpixel:resw 1
.ws_ypixel:resw 1
endstruc
;wnsize_struc_size

struc termio_struc
.c_iflag: resd 1
.c_oflag: resd 1
.c_cflag: resd 1
.c_lflag: resd 1
.c_line: resb 1
.c_cc: resb 19
endstruc
;termio_struc_size:
    
;****f* sys/sys_wrap_plus *
; NAME
;>1 sys
;   sys_wrap_plus - wrap around an executable and capture in/out
;           commands.  Also, restore terminal state.
; INPUTS
;    eax = ptr to shell command string
;    ebx = ptr to optional input (feed) process (see notes) 
;    ecx = ptr to optional output capture process (see notes)
;     dl = flags, bit(0) 01h - if set sys_wrap will call shell
;     -           -             and assume eax is zero.
;     -           -             WARNING - eax is ignored  
;     -           -       00h - sys_wrap will assume eax is pointer
;     -           -             to command string with program to
;     -           -             execute.
;     -           bit (1) 02h - if set use alternate screen
;     -           bit (2) 04h - if set do crt_close then before
;     -                         returning do  crt_open
;     -           bit (3) 08h - if set do term reset before exit
;     -                         (screen will be cleared)
;     -           bit (4) 10h - if set save and restore cursor
;     -                         (only works if using alt screen)
;    env_stack function must be called prior to using this function
;          to find default shell.  If env_stack is not called
;          sys_wrap will try using /bin/sh as shell.
; OUTPUT
;    al has status, 0 = success 
; NOTES
;    file sys_wrap_plus.asm
;     
;    The optional feed process can be set to zero if not needed.
;    If a feed process address is given, it is called after data
;    has been read.  The buffer address is in ecx and the number
;    of bytes read is in edx.  The data has a zero at end.  The
;    feed process can change the data and bye count.  If the byte
;    count is set negative the wrapped child will be aborted.
;    summary:  input:  ecx=buffer      output:  ecx=buffer
;    -                 edx=byte count           edx=count or abort
;    After returning the data will be an input to executing child.
;    -
;    The optional capture process is handled like the feed process,
;    except the byte count (edx) can not be used to abort a process.
;    After returning the data will be sent to stdout.
;    -
;    The input data buffer and output data buffer use lib_buf) which
;    can have a maximum size of 599 bytes.
;<
;  * ---------------------------------------------------
;*******
  extern termios    
  global sys_wrap_plus
sys_wrap_plus:
  push	eax
  push	ebx
  push	ecx
  mov	[swp_flag],dl		;save flags
  test	dl,4
  jz	swp_10			;jmp if crt_open not active
  cmp	dword [termios+termio_struc.c_lflag],0 ;double check user flag
  je	swp_10			;jmp if crt_close possible
  call	crt_close
swp_10:
  test	byte [swp_flag],2	;check if alt window wanted
  jz	swp_20			;jmp if no alt window
  call	sys_win_alt		;select alternate window
  test  byte [swp_flag],10h	;check if cursor save/restore
  jz	swp_20			;jmp if no cursor restore
  call	restore_cursor
  mov	ecx,clean_cmd2
  call	crt_str
swp_20:
  pop	ecx
  pop	ebx
  pop	eax
;  * eax = ptr to program string
;  * -     this is normal shell command string
  mov	dl,[swp_flag]		;restore flags
  test	dl,1			;check if shell only
  jz	swp_30			;jmp if cmd string
  xor	eax,eax			;force eax to zero
swp_30:
  call	sys_wrap
  push	eax			;save copy return code
  test	byte [swp_flag],2
  jz	swp_40			;jmp if not alt window in use
  test	byte [swp_flag],10h
  jz	swp_35			;jmp if cursor not saved
  test	byte [swp_flag],1	;was this a interactive shell?
  jz	swp_32			;jmp if not shell
  mov	ecx,clean_cmd1		;clean up 'exit' left on screen
  call	crt_str
swp_32:
  call	save_cursor
swp_35:
  call	sys_win_normal
swp_40:
;  call	reset_terminal
  test	byte [swp_flag],8
  jz	swp_50			;jmp if no reset
  call	full_reset
swp_50:
  test	byte [swp_flag],4	;check if crt was open
  jz	swp_60			;jmp if crt_open call inactive
  call	crt_open
swp_60:
  call	mouse_enable
  pop	eax			;restore copy return code
 ret

clean_cmd1: db 1bh,'[2A',0	;up one
clean_cmd2: db 1bh,'[0J'	;clear below
            db 0		;new line
;----------------------------------
full_reset:
  mov	ecx,reset_cmd
  call	crt_str
  ret
reset_cmd: db 1bh,'c',0
;---------------
  [section .data]
swp_flag:  db	0
  [section .text]

;------------
