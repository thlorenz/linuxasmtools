
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
 extern enviro_ptrs
 extern find_env_variable
 extern env_home
 extern str_move
 extern file_simple_read
 extern file_access

  [section .text]

;>1 terminfo
;  terminfo_read - search for terminfo and read into memory
; INPUTS
;     the routine env_stack must be executed before.
;     eax = work buffer ptr of size 4096
; OUTPUT
;     eax = 0 if success
;     The following globals are available if success
;      [terminfo_flags] - ptr to flags, see terminfo_get_flag
;      [terminfo_numbers] - ptr to values, see terminfo_get_numbers
;      [terminfo_str_index] - ptr to index, see terminfo_get_strings
;      [terminfo_strings] - ptr to top of string table, (terminfo_get_strings)
;     The work buffer will contain terminfo if success
; NOTES
;   source file: terminfo_read.asm
;   see asmref terminfo entry for more information
;<
; * ----------------------------------------------

;*******
  global terminfo_read
terminfo_read:
  mov	[work_buf_ptr],eax
  mov	ebx,[enviro_ptrs]
  or	ebx,ebx
  jz	tr_err			;jmp if enviro ptr not setup
;find terminal name at $TERM
  mov	ecx,term_env		;search for $TERM
  mov	edx,term_name+3		;put results here
  call	find_env_variable
;adjust name with '/x/'
  mov	al,[term_name+3]
  mov	[term_name+1],al
;find $HOME path
  mov	edi,[work_buf_ptr]	;put results here
  call	env_home		;get home path, edi points at end
;build path $home/term
  mov	esi,tinfo_name
  call	str_move
  mov	esi,term_name
  call	str_move
;can we access this file?
  call	check_for_file
  jz	tr_found		;jmp if file found
;check if file at /etc/terminfo
  mov	esi,term_etc
  call	build_path_and_check
  jz	tr_found
;check if file at /lib/terminfo
  mov	esi,term_lib
  call	build_path_and_check
  jz	tr_found
;check if file at /usr/terminfo
  mov	esi,term_usr
  call	build_path_and_check
  jz	tr_found
tr_err:
  or	eax,byte -1
  jmp	short tr_exit		;exit if file not found
;file was found, path in [work_buf_ptr]
tr_found:
  mov	ebx,[work_buf_ptr]	;file path
  mov	edx,4096		;buffer size
  mov	ecx,ebx			;put data here
  call	file_simple_read
;setup global pointers to data
  mov	eax,[work_buf_ptr]	;base ptr
  mov	ebx,eax			;address build
  xor	ecx,ecx
  mov	cx,[eax+2]		;get name size
  add	ebx,ecx			;compute flag
  add	ebx,byte 12		;  section adr (size of header)
  mov	[terminfo_flags],ebx	;save flag ptr
  mov	cx,[eax+4]		;flag section size
  add	ebx,ecx			;compute end of flags
;we need to check if on even boundry, to do this
;we need to find our offset into the file, not the current
;address
  mov	ecx,ebx
  sub	ecx,[work_buf_ptr]
  test	cl,1			;end with even address?
  jz	even_end
  inc	ebx			;make ebx even
even_end:
  mov	[terminfo_numbers],ebx	;save start of numbers
  mov	cx,[eax+6]		;get number section entries
  shl	ecx,1			;make byte count
  add	ebx,ecx			;compute end of numbers
  mov	[terminfo_str_index],ebx
  xor	ecx,ecx
  mov	cx,[eax+8]		;get str index size
  shl	ecx,1			;convert to byte size
  add	ebx,ecx			;compute start of strings
  mov	[terminfo_strings],ebx
  xor	ecx,ecx
  mov	cx,[eax+10]		;get size of string table
  add	ebx,ecx
  mov	[terminfo_strings_end],ebx
  xor	eax,eax
tr_exit:
  ret  
;-----------------------------
check_for_file:
  mov	ebx,[work_buf_ptr]
  mov	ecx,4
  call	file_access
  or	eax,eax
  ret
;-----------------------------
;input: esi = path start
build_path_and_check:
  mov	edi,[work_buf_ptr]
  call	str_move
  mov	esi,term_name
  call	str_move
  call	check_for_file
  ret

;----------
  [section .data]
  global terminfo_flags,terminfo_numbers,terminfo_str_index,terminfo_strings
  global terminfo_strings_end
terminfo_flags		dd 0 ;ptr to flags, see terminfo_get_flag
terminfo_numbers	dd 0 ;ptr to values, see terminfo_get_numbers
terminfo_str_index	dd 0 ;ptr to index, see terminfo_get_strings
terminfo_strings	dd 0 ;ptr to top of string table, (terminfo_get_strings)
terminfo_strings_end	dd 0 ;ptr to end of strings
term_env	db 'TERM',0
work_buf_ptr	dd 0
term_name	db '/x/'
		times 20 db 0
term_etc	db '/etc/terminfo',0
term_lib	db '/lib/terminfo',0
term_usr	db '/usr/share/terminfo',0
tinfo_name	db '/.termios',0
  [section .text]
;-------------------------------------------------
%ifdef DEBUG

  extern env_stack
  global main,_start
main:
_start:
  call	env_stack
  mov	eax,buf
  call	terminfo_read
  mov	eax,1
  int	byte 80h

;---------
  [section .data]
buf	times 4096 db 0
  [section .text]
%endif

