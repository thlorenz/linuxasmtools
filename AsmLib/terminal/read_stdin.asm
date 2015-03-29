
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
;  extern key_status
  extern kbuf
  extern key_flush
;  extern key_poll
  extern mouse_check
  extern raw_set2,raw_unset2

 [section .text]
; NAME
;>1 terminal
;  key_mouse1 - flush and read one key string or mouse click
; INPUTS
;    none
; OUTPUT
;    kbuf has key sequence ending with zero byte
;    if key sequence starts with byte of -1 then
;    it is a mouse click and following bytes are:
;     button(0-3), column(1-x), row(1-x)
;     button = 0=left 1=middle 2=right 3=release
; NOTES
;   source file: read_stdin.asm
;   The keyboard is flushed before reading key data.
;   function crt_open must be called before using!
;<
; * ----------------------------------------------
;*******
;****f* key_mouse/key_mouse2 *
; NAME
;>1 terminal
;  read_stdin - read one key string or mouse click
; INPUTS
;    none
; OUTPUT
;    kbuf has key sequence ending with zero byte
;    if key sequence starts with byte of -1 then
;    it is a mouse click and following bytes are:
;     button(0-3), column(1-x), row(1-x)
;     button = 0=left 1=middle 2=right 3=release
; NOTES
;   file: read_stdin.asm
;   The keyboard is not flushed before reading key data.
;<
; * ----------------------------------------------
;*******
; Note:  The convoluted logic that follows was added
; to keep xterm happy.  For some reason the keys are not
; read as separate entities on xterms.  We need extra
; logic to find start and end of key.
; This problem only appears when a key is held down and
; repeating.
;
  global key_mouse1
  global key_mouse2
  global read_stdin

key_mouse1:
  call	raw_set2
  call	key_flush
  jmp	short km_10
key_mouse2:
read_stdin:
  call	raw_set2
km_10:
poll_keyboard:
  mov	ecx,kbuf
read_more:
  mov	edx,36			;read 20 keys
  mov	eax,3				;sys_read
  mov	ebx,0				;stdin
  int	byte 0x80
  or	eax,eax
  js	rm_exit
  add	ecx,eax
  mov	byte [ecx],0		;terminate char
  or	eax,eax
  jz	rm_exit

  push	ecx
  mov	eax,162			;nano sleep
  mov	ebx,delay_struc
  xor	ecx,ecx
  int	byte 80h

  mov	word [kpoll_rtn],0
  mov	eax,168			;poll
  mov	ebx,kpoll_tbl
  mov	ecx,1			;one structure at poll_tbl
  mov	edx,20			;wait xx ms
  int	byte 80h
  test	byte [kpoll_rtn],01h
  pop	ecx
  jnz	read_more
;strip any extra data from end
  mov	esi,kbuf
  cmp	byte [esi],1bh
  je	mb_loop
  cmp	byte [esi],0c3h		;alt keys on debian xterm start with c3
  je	mb_loop
  cmp	byte [esi],0c2h
  je	mb_loop			;jmp if meta key
  inc	esi
  jmp	short rm_20
;check for end of escape char
mb_loop:
  inc	esi
  cmp	[esi],byte 0
  je	rm_20			;jmp if end of char
  cmp	byte [esi],0c2h
  je	rm_20			;jmp if meta char
  cmp	byte [esi],0c3h
  je	rm_20			;jmp if meta char
  cmp	byte [esi],1bh
  jne	mb_loop			;loop till end of escape sequence
rm_20:
  mov	byte [esi],0		;terminate string
  call	mouse_check		;check if mouse data read
rm_exit:
  call	raw_unset2
  ret 
;------------------
  [section .data]
kpoll_tbl	dd	0	;stdin
		dw	-1	;events of interest
kpoll_rtn	dw	-1	;return from poll

delay_struc:
  dd	0	;seconds
  dd	1	;nanoeconds
  [section .text]



