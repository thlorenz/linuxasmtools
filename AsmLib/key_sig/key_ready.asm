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

  extern tty_fd
  extern lib_buf
  extern sys_read
  extern ks1,ks2

;---------------------------------------------------
;#1 key_sig
;key_ready - read key from /dev/tty
; INPUT
;   keyboard must be in raw mode to read individual
;   keys.  See key_raw and key_unraw funtions.
; OUTPUT
;   js (negative flag) = ignore this key, either
;      a error occured or it is a mouse release.
; NOTE
;      source file key_read.asm
;#
;-----------------------------------------------------------    
  global key_ready
key_ready:
  mov	ebx,[tty_fd]	;get code for tty
  mov	ecx,ks1
  cmp	[ecx],byte 0
  je	do_read
  mov	ecx,ks2
  cmp	[ecx],byte 0
  je	do_read
  mov	ecx,lib_buf	;key buffers full, dump to lib_buf
do_read:
  mov	edx,13
  call	sys_read	;read keys
;we are getting a fffffff5 (try again) error here when
;program is first started?  For now we just ignore
;all errors and keep trying.
  or	eax,eax
  js	kr_exit		;exit if error
  add	eax,ecx		;compute end of key
  mov	[eax],byte 0	;terminate key string
  call	fix_mouse	;return sign flag + if not release
kr_exit:
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
  jne	mc_exit				;jmp if not mouse
; read release key
;  mov	eax,3				;sys_read
;  mov	ebx,0				;stdin
;  lea	ecx,[ecx+6]
;  mov	edx,20				;buffer size
;  int	0x80				;read key
; format data
  cmp	byte [ecx+3],23h		;release key
  je	mc_exit1			;jmp if release key
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
  xor	eax,eax			;clear sign bit
  jmp	short mc_exit2
mc_exit1:
  or	eax,byte -1		;set sign flag
mc_exit2:
  ret 
