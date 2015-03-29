  [section .text align=1]
  extern sys_exit

;--- dcache_test --------------------------------
;
; included tests:
;  0. dcache_clear,dcache_flush
;  1. dcache_size & dcache_setup test
;  2. key test
;  3. dcache_write_repeat
;  4. dcache_write_string, dcache_write_fstring
;  5. dcache_write_block, dcache_write_fblock
;  6. dcache_write_line, dcache_write_fline
;  7. dcache_set_color, dcache_read_color,
;     dcache_color_range
;  8. dcache_read_char, dcache_set_all_writes
;  9. dcache_read_cursor, dcache_buf_cursor,
;     dcache_screen_cursor
;
%include "dcache_colors.inc"
  extern read_stdin
  extern stdout_str
  
  global _start,main
main:
_start:
  call	dcache_size	;get eax=buffer size ebx=screen size
  mov	ebx,test_buffer
  mov	cl,grey_char+blue_back
  call	dcache_setup
  js	do_exit
  call	dcache_flush

  mov	ax,0202h
  call	move_cursor
  mov	ecx,start_msg
  call	stdout_str
  call	read_stdin


  mov	eax,key
  call	key_put
  call	key_check
  call	key_read
  call	key_read


  mov	al,35q
  call	dcache_set_color
  mov	ax,0705h	;row col
  call	dcache_buf_cursor
  mov	al,'x'		;repeat char
  mov	ah,0		;horizontal
  mov	ecx,3
  call	dcache_write_repeat
  call	dcache_flush

  mov	al,35q
  call	dcache_set_color
  mov	ax,0806h	;row col
  call	dcache_buf_cursor
  mov	al,'x'
  mov	ah,1
  mov	ecx,3
  call	dcache_write_repeat
  call	dcache_flush

  mov	al,35q
  call	dcache_set_color
  mov	ax,0303h	;row col
  call	dcache_buf_cursor
  mov	esi,dws_msg
  call	dcache_write_fstring
  call	dcache_flush

  mov	ah,2		;row
  mov	al,2		;col
  mov	ch,35q		;color
  mov	cl,3		;range
  call	dcache_color_range
  mov	ah,2		;row
  mov	al,6		;column
  mov	cl,3
  mov	ch,35q
  call	dcache_color_range

  call	dcache_flush


do_exit:
  call	sys_exit	;library call example

 [section .data]

test_buffer	times 18096 db 0

start_msg: db 0ah
 db ' If screen is all blue the basic functions',0ah
 db ' dcache_setup, dcache_flush are working.',0ah
 db ' -- select test by number --',0ah
 db '  1. dcache_setup test',0ah
 db '  2. key test',0ah
 db '  3. dcache_write_repeat',0ah
 db '  4. dcache_write_string, dcache_write_fstring',0ah
 db '  5. dcache_write_block, dcache_write_fblock',0ah
 db '  6. dcache_write_line, dcache_write_fline',0ah
 db '  7. dcache_set_color, dcache_read_color,',0ah
 db '     dcache_color_range',0ah
 db '  8. dcache_read_char, dcache_set_all_writes',0ah
 db '  9. dcache_read_cursor, dcache_buf_cursor,',0ah
 db '     dcache_screen_cursor',0

test_color	db 14q
dwl_msg:	db 'dwl',0ah
	db 'error if this displayed',0ah
	db 0

dws_msg:	db	0ah
 db	'hello',0ah
 db	'1',0ah
 times 100 db 'x'
		db 0
key	db 'k',0
;--- end of temp test code -----------------------
;-------------------------------------------------

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
;   along with this program.  If not, see <http://www.gnu.org/licenses/.


  [section .text align=1]

;---------------------------------------------------
;>1 dcache
;key_fread - flush any pending keys then read /dev/tty
; INPUT
;   none
; OUTPUT
;    ecx=ptr to key string if eax not negative
;    eax=error code or number of characters read
;    if mouse press, key string format is:
;       [ecx]  = ff,bb,cc,rr (flag,button,column,row)
;       where: ff =   -1 (byte)
;              bb =   (byte) 0=left but  1=middle 2=right 3=release
;              cc =   binary column (byte)
;              rr =   binary row (byte)  
; NOTE 
;   source file key_read.asm
;   The "key" routines work together and other keyboard
;   functions should be avoided.  The "key" family is:
;   key_fread - flush and read
;   key_read - read key
;   key_check - check if key avail.
;   key_put - push a key back to buffer
;<
key_fread:
  call	open_tty
  xor	eax,eax
  mov	[avail2],eax	;remove any stored key
  mov	[avail1],eax	;remove any stored key

  mov	eax,ebx		;move fd to eax
  xor	edx,edx		;set immediate return
  call	poll_fd		;jz=no events js=err

  jz	key_read	;jmp if no more keys
  call	read_one_byte
  jmp	short key_fread

;---------------------------------------------------
;>1 dcache
;key_read - read key from /dev/tty
; INPUT
;   none
; OUTPUT
;   ecx=ptr to key string if eax not negative
;   eax=error code or plus if good read
;     if mouse press, key string format is:
;     [ecx]  = ff,bb,cc,rr (flag,button,column,row)
;        where: ff =   -1 (byte)
;               bb =   (byte) 0=left but  1=middle 2=right 3=release
;               cc =   binary column (byte)
;               rr =   binary row (byte)
; NOTE
;      source file key_read.asm
;      The "key" routines work together and other keyboard
;      functions should be avoided.  The "key" family is:
;      key_fread - flush and read
;      key_read - read key
;      key_check - check if key avail.
;      key_put - push a key back to buffer
;<    
  extern sys_read

key_read:
  call	open_tty
  mov	ecx,[avail1]
  jecxz	kr_10		;jmp if cache empty
  jmp	short kr_exit	;exit if got key
kr_10:
;switch tty to raw mode
  mov	ebx,[tty_fd]	;get code for tty
  mov	ecx,5401h
  mov	edx,lib_buf
  mov eax,54
  int	80h
  and	byte [edx + termio_struc.c_lflag],~0bh ;set raw mode
  or	byte [edx + termio_struc.c_iflag +1],01 ;
  and	byte [edx + termio_struc.c_iflag+1],~14h ;disable IXON,IXOFF
;ebx = fd
;edx = termios ptr
  mov	ecx,5402h
  mov	eax,54
  int	80h

  mov	ecx,ks1		;key buffer
  mov	edx,13
  call	sys_read	;read keys
  or	eax,eax
  js	kr_exit2	;exit if error
  add	eax,ecx		;compute end of key
  mov	[eax],byte 0	;terminate key string
  call	fix_mouse
kr_exit:
  mov	eax,[avail2]
  mov	[avail1],eax
  xor	eax,eax
  mov	[avail2],eax
kr_exit2:
  push	ecx
;switch tty to un-raw mode
  mov	edx,lib_buf
  or	byte [edx + termio_struc.c_lflag],0bh ;unset raw mode
;ebx = fd
;edx = termios ptr
  mov	ecx,5402h
  mov	eax,54
  int	80h
  pop	ecx
  ret
;-----------------------------------
;fix_mouse - reformat keyboard data if mouse click info
; INPUTS
;   [ecx]  has mouse escape sequenes
;          1b,5b,4d,xx,yy,zz
;            xx - 20=left but  21=middle 22=right 23=release
;            yy - column+20h
;            zz - row + 20h
; OUTPUT
;   [ecx]  = ff,button,column,row
;             where: ff = db -1
;                    button = 0=left but  1=middle 2=right 3=release
;                    column = binary column (byte)
;                    row = binary row (byte)  

fix_mouse:
  cmp	word [ecx],5b1bh		;check if possible mouse
  jne	mc_exit				;jmp if not mouse
  cmp	byte [ecx+2],4dh
  jne	mc_exit			;jmp if not mouse
; read release key
  mov	eax,3				;sys_read
  mov	ebx,0				;stdin
  lea	ecx,[ecx+6]
  mov	edx,20				;buffer size
  int	0x80				;read key
; format data
  mov	edi,ecx
  mov	byte [edi],-1
  inc	edi			;signal mouse data follows
  mov	al,[ecx+3]
  and	al,3
  stosb 			;store button 0=left 1=mid 2=right
  mov	al,[ecx+4]
  sub	al,20h
  stosb				;store column 1+
  mov	al,[ecx+5]
  sub	al,20h
  stosb				;store row
mc_exit:
  ret 
;---------------------------------------------------
;>1 dcache
;key_check - check if key available, but do not read it
; INPUT
;   none
; OUTPUT
;   ecx=zero if no keys
;   ecx=ptr to key string if key avail.
; NOTE
;    source file key_check.asm
;    he "key" routines work together and other keyboard
;    functions should be avoided.  The "key" family is:
;    key_fread - flush and read
;    key_read - read key
;    key_check - check if key avail.
;    key_put - push a key back to buffer
;<
  extern poll_fd
  extern read_one_byte

key_check:
  call	open_tty
  mov	ecx,[avail1]	;any keys waiting
  xor	eax,eax
  cmp	eax,ecx		;is key waiting
  jne	kc_exit		;exit if key avail
;no key in buffer, check /dev/tty
  mov	eax,ebx		;move fd to eax
  xor	edx,edx		;set immediate return
  call	poll_fd		;jz=no events js=err
  jz	kc_none		;jmp if no keys waiting
  call	key_read
  jns	kc_exit
  xor	ecx,ecx		;set no key waiting if error
  jmp	short kc_exit
kc_none:
  xor	ecx,ecx
kc_exit:
  ret
;---------------------------------------------------
;>1 dcache
;key_put - insert key back into buffer
;we can put a max of two key strings, each a max of 13 bytes
; INPUT
;   eax=ptr to key string (zero terminated)
; OUTPUT
;   none
; NOTE
;   source file key_put.asm
;   The "key" routines work together and other keyboard
;   functions should be avoided.  The "key" family is:
;   key_fread - flush and read
;   key_read - read key
;   key_check - check if key avail.
;   key_put - push a key back to buffer
;<
  extern str_move

key_put:
  mov	esi,[avail1]
  or	esi,esi
  jz	kp_20		;jmp if no stored keys
;move avail1 > avail2
  mov	edi,ks2
  mov	[avail2],edi	;set avail2
  call	str_move	;avail1 > avail2 move key
;move "put" key to avail1
kp_20:
  mov	edi,ks1
  mov	[avail1],edi
  mov	esi,eax
  call	str_move
  ret
;---------------------------------------------------

struc termio_struc
.c_iflag: resd 1
.c_oflag: resd 1
.c_cflag: resd 1
.c_lflag: resd 1
.c_line: resb 1
.c_cc: resb 19
endstruc
;termio_struc_size:

open_tty:
  mov	ebx,[tty_fd]
  cmp	ebx,dword 1
  jne	ot_exit		;jmp if tty open
  mov	ebx,tty_dev
  mov	ecx,2		;mode = read/write
  mov	edx,0666h	;premissions
  call	sys_open
  or	eax,eax
  js	ot_exit		;jmp if no /dev/tty
  mov	[tty_fd],eax
ot_exit:
  ret
;-------
  [section .data]
;next key always in avail1 if available
;we always read into avail1
avail1:	dd 0	;ptr to available key string or zero
avail2: dd 0	;ptr to available key string of zero
ks1:	times 14 db 0 ;key string 1
ks2:	times 14 db 0 ;key stirng 2

;---------------------------------------------------
;---------------------------------------------------
;>1 dcache
;dcache_write_repeat - write repeat to cache
;  stops at edge of screen
;
; INPUT
;    al = repeat char
;    ah = repeat flag, 0=horizontal 1=vertical
;    ecx = repeat count
;    color and cursor location already set
;
;  OUTPUT
;     buffer cursor at end of last write
;     ah=repeat color al=repeat char
;     ecx=0
;     dh=row dl=column
;     edi=image index
;     edp=image buffer
;<
; registers kept: ah=color al=char out
;                 ebx -scratch
;                 ecx -repeat count
;                 dh=row dl=col (track input data)
;                 esi=scratch
;                 edi=index into image
;                 ebp=image top
;                 
dcache_write_repeat:
  push	eax
  mov	[repeat_flag],ah	;0=horizontal
  mov	ebp,[image]
  mov	eax,[current_index]
  call	index_to_rowcol
  mov	edx,eax		;dh=row dl=col
  mov	edi,[current_index]
  pop	eax		;restore char to display
  mov	ah,[image_write_color]
dwr_loop:
  jecxz	dwr_tail	;jmp if end of block
  cmp	dh,[dcache_rows]
  ja	dwr_tail	;jmp if at bottom of display
  cmp	dl,[dcache_columns]
  ja	dwr_tail	;jmp=check if more lines
  call	stuff
  dec	ecx
  cmp	[repeat_flag],byte 0
  je	dwr_loop	;jmp if horizontal repeat
  dec	dl
  inc	dh
  push	eax		;save color and char
  mov	eax,edx		;get row/col in eax
  call	rowcol_to_index
  mov	edi,eax		;set new index
  pop	eax		;restore color and char
  jmp	short dwr_loop
; we are done with repeat
dwr_tail:
;compute index from row/col
  cmp	dh,[dcache_rows] ;end of display?
  je	dwr_exit	;jmp if at bottom of screen
  cmp	[repeat_flag],byte 0	;horizontal rep?
  je	dwr_set			;if horizontal rep, stay on line
;this is vertical repeat, move to next line
  inc	dh		;vert repeat, move to next line
  mov	dl,1		;column 1
dwr_set:
  push	eax
  push	ecx
  mov	eax,edx
  call	rowcol_to_index
  mov	edi,eax		;index to edi
  pop	ecx
  pop	eax
dwr_exit:
  mov	[current_index],edi
  ret

;-------------
  [section .data]
repeat_flag:	db 0	;0=horizontal 1=vertical
  [section .text]

;---------------------------------------------------
;>1 dcache
;dcache_write_string - write string to cache
;  write string and handle, tabs, line-feeds, truncate
;  at edge of screen, stop at zero char or
;  last line of screen.
;
; INPUT
;    esi = string ptr
;    color and cursor location already set
;
; OUTPUT
;     ah=color al=char out
;     dh=row   cl=column (next write positon)
;     esi=ptr beyond last input char written
;     edi=image index
;     ebp=top of image buffer
;<          
; registers kept: ah=color al=char out
;                 ebx -scratch
;                 ecx -scratch
;                 dh=row dl=col (track input data)
;                 esi=input data ptr
;                 edi=index into image
;                 ebp=image top
;                 
;---------------------------------------------------
;>1 dcache
;dcache_write_fstring - write string to cache and fill
;  same as dcache_write_string, with addition of fill
;  from end of string to right edge of display.
;
; INPUT
;   esi = string ptr
;   color and cursor location already set
;
; OUTPUT
;    ah=color al=char out
;    dh=row   cl=column (next write positon)
;    esi=ptr beyond last input char written
;    edi=image index
;    ebp=top of image buffer
;<          
; registers kept: ah=color al=char out
;                 ebx -scratch
;                 ecx -scratch
;                 dh=row dl=col (track input data)
;                 esi=input data ptr
;                 edi=index into image
;                 ebp=image top
;                 
dcache_write_fstring:
  mov	al,1
  jmp	short dcache_entry
dcache_write_string:
  mov	al,0		;no fill
dcache_entry:
  mov	[fill_flag],al
  mov	ebp,[image]
  mov	eax,[current_index]
  call	index_to_rowcol
  mov	edx,eax		;dh=row dl=col
  mov	edi,[current_index]
  mov	ah,[image_write_color]
dws_loop:
  cmp	dl,[dcache_columns]
  ja	dws_scan	;jmp=check if more lines
  lodsb			;get char to write
  cmp	al,9		;tab?
  je	dws_tab		;jmp if tab
  jb	dws_fill	;jmp if end of string
  cmp	al,0ah
  je	dws_fill	;jmp if end of line
tab_entry:
  call	stuff
  jmp	short dws_loop
; we are at right edge, skip over input data
; till end of line, or end of string
dws_scan:
  lodsb
  cmp	al,0ah
  je	dws_fill	;jmp if end of line
  cmp	al,0
  jne	dws_scan
; we are at end of line or end of input data
; check if fill to edge or display needed
dws_fill:
  cmp	[fill_flag],byte 0
  je	dws_fill2	;jmp if no fill
  mov	al,0a0h		;space + flag
dws_fill_loop:
  cmp	dl,[dcache_columns]
  ja	dws_fill2
  call	stuff
  jmp	short dws_fill_loop
; check if more lines or done
dws_fill2:
  cmp	byte [esi -1],0ah ;end of line
  jne	dws_exit	;exit if done
; another line of data is available
  inc	dh		;bump row
  mov	dl,1		;set column
;compute index from row/col
  push	eax
  mov	eax,edx
  call	rowcol_to_index
  mov	edi,eax		;index to edi
  pop	eax

  cmp	dh,[dcache_rows] ;end of display?
  jne	dws_loop	;jmp if screen has room
dws_exit:
  mov	[current_index],edi
  ret

dws_tab:
  mov	al,dl		;get column
  and	al,07h		;isolate column
  cmp	al,7h		;at tab?
  mov	al,0a0h		;preload space
  je	tab_entry	;jmp if tab completion
  dec	esi		;move back to tab char
  jmp	tab_entry	;continue tab expansion

stuff:
  cmp	ax,[ebp+edi*2]
  je	dws_stuff_tail	;jmp if data unchanged
  or	ax,8080h	;set changed flags
  mov	[ebp+edi*2],ax  ;store data in image
  and	ax,~8080h	;clear flags
dws_stuff_tail:
  inc	edi		;move index
  inc	dl		;move column
  ret

;----------
  [section .data]
fill_flag	db 0	;0=no fill
  [section .text]
;---------------------------------------------------
;>1 dcache
;dcache_write_block - write block to cache
;  write block and handle, tabs, line-feeds, truncate
;  at edge of screen, stop at zero char or
;  last line of screen.
;
; INPUT
;    esi = block ptr
;    ecx = block length
;    color and cursor location already set
;
; OUTPUT
;    ah=color al=char out
;    dh=row   cl=column (next write positon)
;    esi=ptr beyond last input char written
;    edi=image index
;    ebp=top of image buffer
;<
; registers kept: ah=color al=char out
;                 ebx -scratch
;                 ecx= count of input data remaining
;                 dh=row dl=col (track input data)
;                 esi=input data ptr
;                 edi=index into image
;                 ebp=image top
;                 
;---------------------------------------------------
;>1 dcache
;dcache_write_fblock - write block to cache and fill
;  same as dcache_write_block, with addition of fill
;  from end of block to right edge of display.
;
; INPUT 
;   esi = block ptr
;   ecx = block length
;   color and cursor location already set
;
; OUTPUT
;   ah=color al=char out
;   dh=row   cl=column (next write positon)
;   esi=ptr beyond last input char written
;   edi=image index
;   ebp=top of image buffer
;<
; registers kept: ah=color al=char out
;                 ebx -scratch
;                 ecx= count of input data remaining
;                 dh=row dl=col (track input data)
;                 esi=input data ptr
;                 edi=index into image
;                 ebp=image top
;                 
dcache_write_fblock:
  mov	al,1
  jmp	short dcache_bentry
dcache_write_block:
  mov	al,0		;no fill
dcache_bentry:
  mov	[fill_flag],al
  mov	ebp,[image]
  mov	eax,[current_index]
  call	index_to_rowcol
  mov	edx,eax		;dh=row dl=col
  mov	edi,[current_index]
  mov	ah,[image_write_color]
dwb_loop:
  jecxz	dwb_fill	;jmp if end of block
  cmp	dl,[dcache_columns]
  ja	dwb_scan	;jmp=check if more lines
  lodsb			;get char to write
  cmp	al,9		;tab?
  je	dwb_tab		;jmp if tab
  cmp	al,0ah
  je	dwb_fill	;jmp if end of line
tab_bentry:
  call	stuff
  dec	ecx
  jmp	short dwb_loop
; we are at right edge, skip over input data
; till end of line, or end of block
dwb_scan:
  dec	ecx
  jecxz	dwb_fill
  lodsb
  cmp	al,0ah
  jne	dwb_scan
; we are at end of line or end of input data
; check if fill to edge or display needed
dwb_fill:
  cmp	[fill_flag],byte 0
  je	dwb_fill2	;jmp if no fill
  mov	al,0a0h		;space + flag
dwb_fill_loop:
  cmp	dl,[dcache_columns]
  ja	dwb_fill2
  call	stuff
  jmp	short dwb_fill_loop
; check if more lines or done
dwb_fill2:
  jecxz	dwb_exit	;exit if done
; another line of data is available
  inc	dh		;bump row
  mov	dl,1		;set column
;compute index from row/col
  push	eax
  push	ecx
  mov	eax,edx
  call	rowcol_to_index
  mov	edi,eax		;index to edi
  pop	ecx
  pop	eax

  cmp	dh,[dcache_rows] ;end of display?
  jne	dwb_loop	;jmp if screen has room
dwb_exit:
  mov	[current_index],edi
  ret

dwb_tab:
  mov	al,dl		;get column
  and	al,07h		;isolate column
  cmp	al,7h		;at tab?
  mov	al,0a0h		;preload space
  je	tab_bentry	;jmp if tab completion
  dec	esi		;move back to tab char
  jmp	tab_bentry	;continue tab expansion
;---------------------------------------------------
;>1 dcache
;dcache_write_line - write line to cache
;  write line and handle, tabs, line-feeds, truncate
;  at edge of screen, stop at zero char or
;  last line of screen.
;
; INPUT
;   esi = line ptr
;   color and cursor location already set
;
; OUTPUT
;   ah=color al=char out
;   dh=row   cl=column (next write positon)
;   esi=ptr beyond last input char written
;   edi=image index
;   ebp=top of image buffer
;<
; registers kept: ah=color al=char out
;                 ebx -scratch
;                 ecx -scratch
;                 dh=row dl=col (track input data)
;                 esi=input data ptr
;                 edi=index into image
;                 ebp=image top
;                 
;---------------------------------------------------
;>1 dcache
;dcache_write_fline - write line to cache and fill
;  same as dcache_write_line, with addition of fill
;  from end of line to right edge of display.
;
; INPUT
;   esi = line ptr
;   color and cursor location already set
;
; OUTPUT
;   ah=color al=char out
;   dh=row   cl=column (next write positon)
;   esi=ptr beyond last input char written
;   edi=image index
;   ebp=top of image buffer
;<
; registers kept: ah=color al=char out
;                 ebx -scratch
;                 ecx -scratch
;                 dh=row dl=col (track input data)
;                 esi=input data ptr
;                 edi=index into image
;                 ebp=image top
;                 
dcache_write_fline:
  mov	al,1
  jmp	short dcache_xentry
dcache_write_line:
  mov	al,0		;no fill
dcache_xentry:
  mov	[fill_flag],al
  mov	ebp,[image]
  mov	eax,[current_index]
  call	index_to_rowcol
  mov	edx,eax		;dh=row dl=col
  mov	edi,[current_index]
  mov	ah,[image_write_color]
dwl_loop:
  cmp	dl,[dcache_columns]
  ja	dwl_scan	;jmp=flush any unsued text
  lodsb			;get char to write
  cmp	al,9		;tab?
  je	dwl_tab		;jmp if tab
  jb	dwl_fill	;jmp if end of line
  cmp	al,0ah
  je	dwl_fill	;jmp if end of line
tab_xentry:
  call	stuff
  jmp	short dwl_loop
; we are at right edge, skip over input data
; till end of line, or end of line
dwl_scan:
  lodsb
  cmp	al,0ah
  je	dwl_fill	;jmp if end of line
  cmp	al,0
  jne	dwl_scan
; we are at end of line or end of input data
; check if fill to edge or display needed
dwl_fill:
  cmp	[fill_flag],byte 0
  je	dwl_fill2	;jmp if no fill
  mov	al,0a0h		;space + flag
dwl_fill_loop:
  cmp	dl,[dcache_columns]
  ja	dwl_fill2
  call	stuff
  jmp	short dwl_fill_loop
dwl_fill2:
;compute index from row/col
  push	eax
  mov	eax,edx
  call	rowcol_to_index
  mov	edi,eax		;index to edi
  pop	eax

dwl_exit:
  mov	[current_index],edi
  ret

dwl_tab:
  mov	al,dl		;get column
  and	al,07h		;isolate column
  cmp	al,7h		;at tab?
  mov	al,0a0h		;preload space
  je	tab_xentry	;jmp if tab completion
  dec	esi		;move back to tab char
  jmp	tab_xentry	;continue tab expansion
;---------------------------------------------------
;>1 dcache
;set color for image write functons
; INPUT
;   al=color
; OUTPUT
;   all register unchanged
; NOTE
;   color format.
;   aafffbbb  aa-attr fff-foreground  bbb-background
;    0-blk 1-red 2-grn 3-brwn 4-blu 5-purple 6-cyan 7-gry
;    attributes 0-normal 1-bold 4-underscore 7-inverse
;<
dcache_set_color:
  mov	[image_write_color],al
  ret
;---------------------------------------------------
;>1 dcache
;dcache_read_color - read color at location
; INPUT
;   ah=row  al=col
;   ecx=range
;   edi=storage adr
; OUTPUT
;   eax,ebx,ecx,edi modified
;   edi points beyond last color char.
; NOTE
;   color format.
;   aafffbbb  aa-attr fff-foreground  bbb-background
;    0-blk 1-red 2-grn 3-brwn 4-blu 5-purple 6-cyan 7-gry
;    attributes 0-normal 1-bold 4-underscore 7-inverse
;<        
dcache_read_color:
  call	rowcol_to_index  ;eax=index ebx-modified
  mov	ebx,[image]
drx_loop:
  mov	ax,[ebx+ecx*2]	;get data
  and	ah,7fh		;remove modified flag
  mov	al,ah
  stosb
  loop	drx_loop  
  ret
;---------------------------------------------------
;>1 dcache
;dcache_read_char - read range of characters
; INPUT
;   ah=row  al=col
;   ecx=range
;   edi=storage adr
; OUTPUT
;   eax,ebx,ecx modified
;   edi points beyond last char stored.
;<
decache_read_char:
  call	rowcol_to_index  ;eax=index ebx-modified
  mov	ebx,[image]
drc_loop:
  mov	ax,[ebx+ecx*2]	;get data
  and	al,7fh		;remove modified flag
  stosb
  loop	drc_loop  
  ret
;---------------------------------------------------
;>1 dcache
;dcache_read_cursor - read current cursor position for next write
; INPUT
;   none
; OUTPUT
;   ah=row al=col
;<
dcache_read_cursor:
  mov	eax,[current_index]
  call	index_to_rowcol
  ret
;---------------------------------------------------
;>1 dcache
;dcache_set_all_writes - set write all on next flush
; INPUT
;   none
; OUTPUT
;   none
;<
dcache_set_all_writes:
  mov	ecx,[display_size]
  mov	edi,[image]
dsaw_loop:
  mov	ax,[edi+ecx*2]	;get data
  or	ax,8080h	;set changed flags
  stosw
  loop	dsaw_loop
  ret
;---------------------------------------------------
;>1 dcache
;dcache_color_range - set range of colors
; INPUT
;   ah=row  al=col
;   ch=color cl=length of range
; OUTPUT
;   none
; NOTE
;   color format.
;   aafffbbb  aa-attr fff-foreground  bbb-background
;    0-blk 1-red 2-grn 3-brwn 4-blu 5-purple 6-cyan 7-gry
;    attributes 0-normal 1-bold 4-underscore 7-inverse
;<
dcache_color_range:
  push	ecx
  call	rowcol_to_index	;retruns index in eax
  pop	ebx		;get color + len
  mov	edi,[image]
  lea	edi,[edi+eax*2]	;compute stuff adr
  xor	ecx,ecx
  mov	cl,bl		;set range in ecx
  or	bh,80h		;set changed flag on color
dcr_range:
  mov	ax,[edi]	;get image data
  mov	ah,bh		;insert color
  or	al,80h		;set changed flag on data also
  stosw			;store data back
  loop	dcr_range
  ret

;---------------------------------------------------
; !!! users never need this !!! don't document
;send current color to display
; input: al = color byte
;color format.
;   aafffbbb  aa-attr fff-foreground  bbb-background
;    0-blk 1-red 2-grn 3-brwn 4-blu 5-purple 6-cyan 7-gry
;    attributes 0-normal 1-bold 4-underscore 7-inverse
dcache_current_color:
  mov	ah,[on_screen_color]
  call	color_byte_expand	;out eax=screen string
  mov	ecx,eax		;msg to ecx
  call	stdout_str
  ret
;---------------------------------------------------
;>1 dcache
;dcache_buf_cursor - set cursor for next write to buffer
; INPUT
;   ah=row  al=col
; OUTPUT
;   eax = index set
; NOTE
;
;<
dcache_buf_cursor:
  call	rowcol_to_index
  mov	[current_index],eax
  ret
;---------------------------------------------------
  extern move_cursor
;>1 dcache
;dcache_screen_cursor - set buffer cursor and display cursor
; INPUT
;   al=column 1+  ah=row 1+
; OUTPUT
;
; NOTE
;<
dcache_screen_cursor:
  push	eax
  call	move_cursor
  pop	eax
  call	dcache_buf_cursor
  ret
;---------------------------------------------------
;>1 dcache
;dcache_flush - write screen buffer to display
; INPUT
;   none
; OUTPUT
; NOTE
;<

  extern sys_write
  extern lib_buf
;
; register usage: ecx = buffer index (cursor)
;                 edx = screen index (screen cursor)
;                 esi = image buffer
;                 edi = stuff buffer ptr
;                 ebp = stuff buffer stop point
;
dcache_flush:
  xor	ecx,ecx		;start index at 0
  mov	edx,[on_screen_cursor_index]
  mov	esi,[image]
  mov	edi,lib_buf
  mov	ebp,lib_buf+700-14-10
;main loop
df_main_loop:
  mov	ax,[esi+ecx*2]
  or	al,al
  jz	df_flush_exit	;exit if end of image
;the data sign bit is set if data or color change
  jns	df_next_index	;skip if no changes
  or	ah,ah
  jns	df_stuff	;jmp if no color change
;stuff color
df_color_change:
  and	ah,7fh		;remove flag bit
  cmp	ah,[on_screen_color]
  je	df_stuff	;skip color update if ok
  mov	[on_screen_color],ah ;set new color
  push	eax
  push	esi
  push	ecx
  call	color_byte_expand	;only eax set (modified)
  mov	esi,eax
  mov	ecx,13
  rep	movsb
  pop	ecx
  pop	esi
  pop	eax 
;stuff char
df_stuff:
  cmp	ecx,edx		;is buf cursor = screen cursor?
  je	df_stuff2
;move cursor
  push	eax
  mov	eax,ecx
  call	index_to_rowcol
  push	esi
  push	edx
  push	ecx
  push	edi
  push	eax
  mov	word [vt_row],'00'
  mov	word [vt_column],'00'
  mov	edi,vt_column+2
  call	quick_ascii
  pop	eax
  xchg	ah,al
  mov	edi,vt_row+2
  call	quick_ascii
  mov	esi,vt100_cursor
  mov	ecx,10
  pop	edi
  rep	movsb
  pop	ecx
  pop	edx
  pop	esi
  pop	eax
  mov	edx,ecx		;set on screen cursor
df_stuff2:
  and	al,7fh
  stosb			;store it
  inc	edx		;bump on screen cursor
;check if end of stuff buffer
  cmp	edi,ebp
  jb	df_reset_flags
  call	write_out_buf
  mov	edi,lib_buf ;restart stuff
;reset flags
df_reset_flags:
  and	[esi+ecx*2],word ~8080h  ;reset flags
df_next_index:
  inc	ecx
  jmp	df_main_loop
df_flush_exit:
  call	write_out_buf
  mov	[on_screen_cursor_index],edx
  ret
;---------------------------------------------------
; input: al=ascii
;        edi=stuff end point
quick_ascii:
  push	byte 10
  pop	ecx
  and	eax,0ffh		;isolate al
to_entry:
  xor	edx,edx
  div	ecx
  or	dl,30h
  mov	byte [edi],dl
  dec	edi  
  or	eax,eax
  jnz	to_entry
  ret
;---------------------------------------------
  [section .data]
vt100_cursor:
  db	1bh,'['
vt_row:
  db	'000'		;row
  db	';'
vt_column:
  db	'000'		;column
  db	'H'
vt100_end:
  db	0		;end of string
  
 [section .text]
;---------------------------------------------------
write_out_buf:
  push  ecx
  push	edx
  mov	ecx,lib_buf
  mov	edx,edi
  sub	edx,ecx		;compute accumulations
  mov	ebx,[tty_fd]
  call	sys_write
  pop	edx
  pop	ecx
  ret
;---------------------------------------------------
;>1 dcache
;dcache_clear - clear screen buffer
; INPUT
;   al=color
; OUTPUT
;   
; NOTE
;   clear only sets display buffer, the function
;   dcache_flush must be called to update display
;<
dcache_clear:
;write default color
  call	dcache_current_color

  mov	ecx,[display_size]
  mov	edi,[image]
  mov	ah,[on_screen_color]
  or	ah,80h
  mov	al,0a0h	;space + flag
  rep	stosw
  xor	eax,eax
  stosw				;terminate buffer
  ret
;---------------------------------------------------
;>1 dcache
;  dcache_size - compute screen size in chars
; INPUTS
;    none
; OUTPUT
;    ebx = screen size
;    eax = suggested buffer size
; NOTES
;    source file: dcache_size.asm
;<
; * ----------------------------------------------
struc wnsize_struc
.ws_row:resw 1
.ws_col:resw 1
.ws_xpixel:resw 1
.ws_ypixel:resw 1
endstruc
;wnsize_struc_size

  global dcache_size 
dcache_size:
;get display size
  xor	ebx,ebx		;get code for stdin
  mov	ecx,5413h
  mov   edx,winsize
  mov	eax,54
  int	80h

  mov	eax,[edx]


  mov	[dcache_rows],ax
;;  mov	[dcache_rows],word 2	;;;; temp for testing
  shr	eax,16
  mov	[dcache_columns],ax

;compute index size.
  mul	word [dcache_rows]  
  mov	ebx,eax		;move size of index
  inc	eax		;allow for ending word
  shl	eax,1		;multiply by 2
  ret
;-------------
  [section .data]
winsize:
s_row:	dw 0
s_col:	dw 0
s_xpixel: dw 0
s_ypixel: dw 0

  [section .text]
;---------------------------------------------------
;>1 dcache
;  dcache_setup - setup for cached display
; INPUTS
;   ;eax = size of buffer, a suggested size
;          can be obtained from dcache_size. A
;          larger size allows for resized windows
;   ;ebx = buffer pointer for tables
;   ;dl = blank screen color code
; OUTPUT
;   ;js if error (buffer too small by neg about in eax)    
; NOTES
;    source file: dcache_setup.asm
;
;    The dcache keeps a image of display data and
;    only updates the display when dcache_flush is
;    called.  It is best to only use dcahe routines
;    for display handling, or avoid all dcache functions.
;
;    Typically the dcache is used as follows:
;    1. call dcache_size to get suggested buffer size
;    2. call dchahe_setup with allocated buffer
;    3. build windowed display using write calls
;    4. after display is built, call dcache_flush.
;    5. If display is resized (winch signal) start
;       again at step 1.
;
;    Using dcache provides very fast displays and
;    provides a easy format to minipulate data.
;    Dcache does not work well for non-windowed
;    displays (text scrolling)
;<
; * ----------------------------------------------
;*******

  extern sys_open
  extern stdout_str

;termio_struc_size:
  global dcache_setup
dcache_setup:
  mov	[image],ebx	;start of buffers
  mov	[current_index],ebx	;start pointer
  mov	[on_screen_color],cl
;send SIGWINCH to all processes
;  mov	eax,37	;kill
;  xor	ebx,ebx	;all processes
;  mov	ecx,28	;sigwinch
;  int	80h
;get display size
  call	dcache_size		;get display -> ebx
  mov	[display_size],ebx	;save size
;open /dev/tty
  cmp	[tty_fd],byte 1
  jne	wrap_setup	;jmp if tty already open
  call	open_tty

;set terminal to wrap mode
wrap_setup:
  mov	ecx,wrap_string
  call	stdout_str
;fill buffers
  mov	al,[on_screen_color]
  call	dcache_clear
;write default cursor position, out buffer ptrs
  xor	eax,eax
  mov	[current_index],eax	;restart index
  call	index_to_rowcol
  call	dcache_screen_cursor
  cmp	al,al			;clear sign flag
dcache_setup_exit:
  ret
;-------------------
  [section .data]
wrap_string: db 1bh,'[?7h',0	;wrap mode
  [section .text]
;-----------------------------------------------------
;---------------------------------------------------
;input: al=col 1+ ah=row 1+
rowcol_to_index:
  dec	al
  dec	ah
  push	eax
  mov	al,ah
  mul	byte [dcache_columns]	;ax = row * col
  pop	ebx
  xchg	eax,ebx
  movzx eax,al		;isolate column
  add	eax,ebx		;add rows*width+column
  ret
;---------------------------------------------------
; input: eax = index
; output: al=col 1+  ah=row 1+
index_to_rowcol:
  xor	edx,edx
  cmp	eax,[dcache_columns]
  jae	itr_1
  xchg	eax,edx
  jmp	short itr_2
itr_1:
  div	dword [dcache_columns]
itr_2:
  inc	eax
  inc	edx
  mov	ah,al	;move rows to ah
  mov	al,dl	;move columns to al
  ret
;---------------------------------------------------
; input: ah=color byte aafffbbb aa=atr fff=fore bbb=back
; output: eax=ptr to color string, length=13
color_byte_expand:
  push	eax
  and	ah,7
  or	ah,30h
  mov	[vcs1],ah
  pop	eax

  shr	ah,3
  push	eax
  and	ah,7
  or	ah,30h
  mov	[vcs2],ah
  pop	eax

  shr	ah,3
;  and	ah,1
  or	ah,30h
  mov	[vcs_atr],ah
  mov	eax,vt100_color_str
  ret
;----------------
  [section .data]

vt100_color_str:
  db	1bh,'['
vcs_atr:
  db	0,'m'
  db	1bh,'[4'
vcs1:			;background
  db	0		;ascii color number
  db	'm'
  db	1bh,'[3'
vcs2:			;foreground
  db	0		;ascii color number
  db	'm'
  db	0
  
 [section .text]
;---------------
;---------------------------------------------------
;---------------------------------------------------
;color format.
;   aafffbbb  aa-attr fff-foreground  bbb-background
;    0-blk 1-red 2-grn 3-brwn 4-blu 5-purple 6-cyan 7-gry
;    attributes 0-normal 1-bold 4-underscore 7-inverse
;-----------------------------------------------------
  [section .data]
  global dcache_rows,dcache_columns
dcache_rows: dd 0
dcache_columns: dd 0

  global display_size
display_size:    dd 0	;size in characters

;image buffer ends with "0"
;format (word) bit 15 = color changed flag
;                  14-8 = color code
;                  7  = data changed flag
;                  6-0 = char
image:  dd 0 ;ptr to image table

;the following use buffer cursor, actual screen cursor
;can be set with dcache_screen_cursor;
current_index: dd 0 ;ptr for writes to buffers
on_screen_cursor_index: dd 0 ;actual screen cursor location
on_screen_color: db 0 ;aafffbbb a=atr f=fore b=back
image_write_color: db 0

  [section .text]
