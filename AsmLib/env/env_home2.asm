
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
  extern str_move
  extern lib_buf
  extern file_open_rd
  extern file_read
  extern file_close

  [section .text]

;****f* env/env_home2 *
;
; NAME
;>1 env
;  env_home2 - search /proc for $HOME
; INPUTS
;     edi = buffer to store $HOME contents
; OUTPUT
;    edi = ptr to zero at end of $HOME string or
;          unchanged if $HOME not found.
;          $HOME string has a '/' appended to
;          the end.  Thus, it would look like
;          this:   /home/tom/
; NOTES
;    file:  env_home2.asm (see also build_homepath)
;    See also: env_home
;    This version of env_home uses the /proc system
;    to find enviornment strings.
;<
;  * ----------------------------------------------
;*******
  global env_home2
env_home2:
  push	edi
  mov	ebx,proc_path
  mov	edx,20		;max buffer length
  mov	ecx,build_buf2
  mov	eax,85
  int	80h		;read synlink location
  add	eax,build_buf2	;find end of stored data
  mov	edi,eax
  mov	esi,append_path ;add ptr to environ data
  call	str_move

  mov	ebx,build_buf1
  call	file_open_rd

  mov	ebx,eax		;move file handle to ebx
  mov	edx,600
  mov	ecx,lib_buf
fh_08:
 call	file_read

  mov	ecx,550		;max loop size
  mov	esi,lib_buf
fh_10:
  cmp	dword [esi],'HOME'
  jne	fh_12		;jmp if not found yet
  cmp	byte [esi + 4],'='
  jne	fh_12		;jmp if not found yet
  cmp	byte [esi -1],0
  je	fh_20		;jmp if HOME found
fh_12:
  inc	esi
  dec	ecx
  jnz	fh_10		;loop if buffer still has data
;
; move remaining data to top and  read more data
;
  mov	edi,lib_buf
  mov	ecx,50
  rep	movsb

  mov	ecx,lib_buf+50
  mov	edx,550
  jmp	fh_08		;loop  back and keep looking
fh_20:
  add	esi, 5		;move to start of home path
;
; assume edi points at execve_buf
;
  pop	edi
  call	str_move
  mov	al,'/'
  stosb
  mov	byte [edi],0	;put zero at end
  push	edi		;dummy push so next pop is ok
fh_50:
  pop	edi
  call	file_close	;file handle in ebx
  ret  

  [section .data]
proc_path: db "/proc/self",0
append_path: db "/environ",0

build_buf1: db '/proc/'
build_buf2: times 17 db 0
  [section .text]
