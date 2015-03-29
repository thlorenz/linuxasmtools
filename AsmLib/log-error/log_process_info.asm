
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
  extern log_str
  extern log_regtxt
  extern log_hex
  extern log_eol
  extern get_our_process_id
  extern get_proc_info
  extern get_our_group
  extern get_parent_process_id
  extern get_group
;*************************************************************
;>1 log-error
;  log_process_info - log process pid,ppid,gid,pgid
; INPUTS
;    none
; OUTPUT
;    none
; NOTES
;    source file: log_process_info.asm
;<
  [section .text]
;
  global log_process_info
log_process_info:
  mov	esi,lpi_line1
  call	log_str

  call	get_our_process_id
  mov	ebx,1			;get name
  call	get_proc_info		;get name
  push	ebx
  call	terminate_proc
  pop	esi
  call	log_str

  mov	eax,'pid='
  call	log_regtxt
  call	get_our_process_id
  call	log_hex
;  call	log_num

  mov	eax,'gid='
  call	log_regtxt
  call	get_our_group
  call	log_hex
;  call	log_num

  mov	eax,'tgid'
  call	log_regtxt
  call	get_our_process_id
  mov	ebx,-7			;tpgid
  call	get_proc_info
  mov	eax,ebx
  call	log_hex

  mov	eax,'ses='
  call	log_regtxt
  call	get_our_process_id
  mov	ebx,-5			;session
  call	get_proc_info
  mov	eax,ebx
  call	log_hex

  call	log_eol
;--
  mov	esi,lpi_line2
  call	log_str

  call	get_parent_process_id
  mov	ebx,1			;get name
  call	get_proc_info		;get name
  push	ebx
  call	terminate_proc
  pop	esi
  call	log_str

  mov	esi,show_msg1
  call	log_str
  call	get_parent_process_id
  call	log_hex
; call	log_num

  mov	esi,show_msg2
  call	log_str
  call	get_parent_process_id
  mov	ebx,eax
  call	get_group
  call	log_hex
; call	log_num

  mov	eax,'tgid'
  call	log_regtxt
  call	get_parent_process_id
  mov	ebx,-7			;tpgid
  call	get_proc_info
  mov	eax,ebx
  call	log_hex
  
  mov	eax,'ses='
  call	log_regtxt
  call	get_parent_process_id
  mov	ebx,-5			;session
  call	get_proc_info
  mov	eax,ebx
  call	log_hex


  ret
;-----------------------
;ebx = ptr to item
terminate_proc:
  mov	esi,ebx
tp_loop:
  lodsb
  cmp	al,' '
  ja	tp_loop		;loop till end of item
  mov	byte [esi],0
  ret

;-------
  [section .data]
show_msg1: db 'ppid=',0
show_msg2: db 'pgrp=',0
lpi_line1: db 0ah,'us=',0
lpi_line2: db 'parent=',0
  [section .text]

