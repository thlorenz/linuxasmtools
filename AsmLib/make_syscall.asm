
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
  extern env_stack
  extern file_open
  extern file_write
  extern file_close
  extern crt_str
  extern file_read
  extern ascii_to_dword
  extern dword_to_ascii
  extern str_move
  extern blk_find


 global main,_start
main:
_start:
  call	env_stack
;open kernel include file
  mov	ebx,search_paths
open_loop:
  cmp	byte [ebx],0		;end of list?
  je	open_failed		;exit if error
  mov	ecx,0			;open read only
  xor	edx,edx			;permissions
  call	file_open
  or	eax,eax
  jns	s_10			;jmp if file opened
;move to next path
next_path:
  inc	ebx
  cmp	[ebx],byte 0		;end of path
  jne	next_path		;loop till end
  inc	ebx			;point at first char
  jmp	short open_loop
open_failed:
  mov	ecx,open_error
  call	crt_str
  jmp	s_exit			;exit
read_failed:
  mov	ecx,read_error
  call	crt_str
  jmp	s_exit
writable_fail:
  mov	ecx,write_error
  call	crt_str
  jmp	s_exit
;include file was found, now read into memory
s_10:
  mov	[unistd_fd],eax
  mov	ebx,eax		;move fd to ebx
  mov	ecx,unistd_buffer
  mov	edx,unistd_buffer_size
  call	file_read
  or	eax,eax
  js	read_failed
;zero end of data
  add	ecx,eax		;compute data end
  mov	[ecx],byte 0	;zero end
  mov	[unistd_end_ptr],ecx
;close input file
  call	file_close
;main loop to process each entry in unistd.h
sloop:
;find next entry in unistd.h
  mov	ebp,[unistd_end_ptr]	;end of search
  mov	esi,match_str		;search for #define
  mov	edi,[unistd_ptr]	;search start
  mov	edx,1			;search forward
  mov	ch,-1			;match case
  call	blk_find
  jc	s_done			;jmp if last match found
;found #define, now move forward to space
  mov	esi,ebx			;get ptr to #define
;move to name of function
  add	esi,byte match_str_size
;save name, esi points to start
s_20:
  mov	edi,syscall_name_str
name_lp:
  lodsb
  cmp	al,09h	;tab?
  je	name_end
  cmp	al,' '
  je	name_end
  stosb
  jmp	short name_lp
name_end:
  mov	[edi],byte 0	;terminate name
  mov	[unistd_ptr],esi	;update search start for next time
;next is function number, esi points to end of name
to_num:
  lodsb
  cmp	al,09h
  je	to_num	;skip over tabs
  cmp	al,' '
  je	to_num	;skip spaces
;we have found function number, al = first char
  cmp	al,'('	;is this a increment?)
  jne	normal_number
  inc	dword [syscall_number]	;move to next number
  mov	eax,[syscall_number]
  mov	edi,syscall_number_str
  call	dword_to_ascii
  mov	[edi],byte 0		;terminate number
  jmp	build_global

normal_number:
  mov	edi,syscall_number_str
  stosb
move_number_str:
  lodsb
  cmp	al,'0'
  jb	move_number_end
  cmp	al,'9'
  ja	move_number_end
  stosb
  jmp	short move_number_str
move_number_end:
  mov	[edi],byte 0		;terminate number
  
;convert number of binary
  mov	esi,syscall_number_str
  call	ascii_to_dword	;convert string
  mov	[syscall_number],ecx	;store recursion depth
;store function name in header
  mov	esi,syscall_preface
  mov	edi,header_name1
  call	str_move
  mov	esi,header_str
  call	str_move
  mov	eax,'    '
  stosd
  stosd
  stosd
  mov	esi,syscall_preface
  mov	edi,header_name2
  call	str_move
  mov	eax,'    '
  stosd
  stosd
  stosd
  mov	esi,syscall_preface
  mov	edi,header_name3
  call	str_move
  mov	al,':'
  stosb
  mov	eax,'    '
  stosd
  stosd
  stosd

  mov	esi,syscall_number_str
  mov	edi,header_number
  call	str_move
  mov	eax,'    '
  stosd

;open output file
  mov	esi,syscall_preface
  mov	edi,outfile_name
  call	str_move
  mov	eax,'.asm'
  stosd
  mov	[edi],byte 0		;terminate name

  mov	ebx,outfile_preface
  mov	ecx,1102q		;open   read/write,  truncate
  mov	edx,644q		;permissions
  call	file_open
  js	writable_fail		;exit if error
  mov	[outfile_fd],eax
  mov	ebx,eax
  mov	ecx,syscall_header	;length of write
  mov	edx,syscall_header_size	;get data to write
  call	file_write		;write dashes
;write global statement to file
build_global:
  mov	esi,syscall_preface
  mov	edi,global_append
  call	str_move
  mov	al,0ah
  stosb

  mov	ecx,global_str
  mov	edx,edi
  sub	edx,ecx		;compute length of write
  mov	ebx,[outfile_fd]
  call	file_write
;write label: mov eax,xx to file
  mov	edi,output_buf
  mov	esi,syscall_preface
  call	str_move
  mov	esi,inst_str
  call	str_move
  mov	esi,syscall_number_str
  call	str_move
;move return to outbuf
  mov	esi,ret_str
  call	str_move
;write out buffer
  mov	ecx,output_buf
  mov	edx,edi
  sub	edx,ecx		;compute length of write
  mov	ebx,[outfile_fd]
  call	file_write
  mov	ebx,[outfile_fd]
  call	file_close

  jmp   sloop	

s_done:

;copy file to /sys directory here !!!!!


s_exit:
  xor	ebx,ebx
  mov	eax,1
  int	byte 80h  
;-----------------------------------------------------------------
  [section .data]

;search paths
search_paths:
 db '/usr/include/asm-i486/unistd_32.h',0
 db '/usr/include/asm/unistd_32.h',0
 db 0 ;end of list

syscall_header:
 db ';--------------------------------------------------------------',0ah
 db ';>1 syscall',0ah
 db '; '
header_name1: db '                                                          ',0ah
 db ';',0ah
 db ';    INPUTS ',0ah
 db ';     see AsmRef function -> '
header_name2: db '                                                    ',0ah
 db ';',0ah
 db ';    Note: functon call consists of four instructions',0ah
 db ';          ',0ah
 db ';          '
header_name3: db '                                                  ',0ah
 db ';              mov  eax,'
header_number: db '       ',0ah
 db ';              int  byte 80h',0ah
 db ';              or   eax,eax',0ah
 db ';              ret',0ah
 db ';<;',0ah
 db ';------------------------------------------------------------------',0ah             
 db '  [section .text align=1]',0ah
syscall_header_size equ $ - syscall_header

unistd_fd:	dd 0
unistd_end_ptr:	dd 0
unistd_buffer:  times 8096*2 db 0
unistd_buffer_size equ $ - unistd_buffer
unistd_ptr	dd unistd_buffer ;used to parse each entry

syscall_preface: db 'sys_'
syscall_name_str: times 40 db 0
syscall_number_str: times 10 db 0
syscall_number:	dd 0

outfile_preface: db 'syscall/'
outfile_name: times 40 db 0
outfile_fd:   dd 0

output_buf:
  times 160 db 0

open_error: db 0ah,'unistd.h not found, default syscall numbers used',0ah,0
read_error: db 0ah,'unistd.h not read, default syscall numbers used',0ah,0
write_error: db 0ah,'write error, we must reside in writeable directory',0ah
             db     'default syscall numbers will be used',0ah,0

match_str: db 0ah,'#define __NR',0
match_str_size equ $ - match_str

global_str: db 0ah,'  global '
global_append: times 40 db 0
inst_str:   db ':',0ah,09h,'mov',09h,'eax,',0
ret_str:    db 0ah,09h,'int',09h,'byte 80h',0ah,09h,'or',09h,'eax,eax',0ah,09h,'ret',0

header_str	db	' - kernel function',0