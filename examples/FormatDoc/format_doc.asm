
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
;****f* -/format_doc *
; NAME
;>1 utility
;  format_doc - process text file
; INPUTS
;    usage format_doc <in-file> <out-file>
;     
;    a format_doc.ini file must also exist in
;    the local directory, see file format_doc.ini
; OUTPUT
;    the out-file will written with all match-strings
;    replaced with replace-strings
; NOTES
;   file:  format_doc.asm
;    
;   format_doc first finds the match string and then
;   begins executing the actions at end of each entry
;   in format_doc.ini
;   If repeat code is placed at end of actions, they
;   are repeated till the match string is not found.
;   It is important to keep the match string beyond
;   its last match to avoid infinite loops when using
;   the repeat action.
;<
; * ----------------------------------------------
;*******
 extern file_read_all
 extern file_write_close
 extern blk_replace
; extern crt_clear
 extern crt_str
 extern blk_del_bytes
 extern blk_insert_bytes
 extern blk_find

 [section .text]

 global _start
 global main

main:
_start:
format_doc:
  cld
;  mov	eax,30003734h
;  call	crt_clear

  mov	ebp,esp
  pop	eax			;get parameter count
  cmp	eax,3
  je	fd_parse		;jmp if parameter count ok

fd_error:
  mov	ecx,help_msg
  call	crt_str
  jmp	fd_exit

fd_parse:
  pop	eax			;get program name
  pop	eax			;get parameter 1
  mov	[in_file],eax
  pop	eax
  mov	[out_file],eax
  mov	esp,ebp
;
; read the control file format_doc.ini
;
  mov	ebp,control_file
  mov	edx,fbuf_end - fbuf
  mov	ecx,fbuf
  mov	al,1
  call	file_read_all
  js	fd_error		;jmp if failure
  add	eax,fbuf
  mov	ebp,eax			;move file end ptr to ebp
;
; process input data
;
  mov	esi,fbuf
  mov	edi,rtable
;
; find start of "string"
;
fd_p1_lp:
  call	next_quote
  je	fd_20			;jmp if end of file
  jb	fd_p1_lp		;loop if normal char
;
; move string to table
;
fd_p2_lp:
  call	next_quote
  je	fd_20			;jmp if end of file
  ja	fd_string_end		;jmp if end of string1 found
  stosb
  jmp	short fd_p2_lp
;
; terminate string
; 
fd_string_end:
  mov	al,0
  stosb				;put zero at end of match string
  jmp	short fd_p1_lp
;
; terminate table
;
fd_20:
  mov	byte [edi],0		;terminate table
;read file  
  mov	al,0ah
  mov	[pre_fbuf],al
;  mov	dword [file_end_ptr],fbuf

  mov	ebp,[in_file]
  mov	edx,fbuf_end - fbuf	;buffer size
  mov	ecx,fbuf
  mov	al,1			;local file
  call	file_read_all
  js	fd_error		;jmp if failure
  add	eax,fbuf
  mov	ebp,eax			;move file end ptr to ebp
  mov	byte [eax],0ah		;put 0ah at end of table

  call	table_replace
;
; write file and exit
;
  mov	eax,fbuf
  mov	ecx,ebp		;get file end ptr
  sub	ecx,eax		;compute length of write
  mov	ebx,[out_file]
  mov	esi,1
  call	file_write_close
fd_exit:
  mov	ebx,0
  mov	eax,1
  int	80h		;exit  
;---------------------------------------------
; next_quote - scan control table char
;  input: esi = ptr to input file
;         ebp = end of file data
;         edi = store ptr (not used or modified)
;  output: flag je = end of file
;          flag jb = normal char
;          flag ja = end of field found
next_quote:
  cmp	esi,ebp
  je	nq_exit
  lodsb
  cmp	al,22h		;check for "
  jne	nq_cont		;jmp if not quote
  cmp	al,0
  jmp	short nq_exit
;
; check if new-line
;
nq_cont:
  cmp	al,'\'
  jne	nq_normal
  cmp	byte [esi],'n'
  jne	nq_normal
nq_fix_nl:
  lodsb			;get the '0'
  mov	al,0ah
;
; normal character in al
;
nq_normal:
  cmp	al,0ffh
nq_exit:
  ret    
;---------------------------------------------
; process all entries in rtable
;
table_replace:

  mov	esi,rtable
  mov	[table_ptr],esi
;
; get search string
;
tr_main_lp:

  mov	edi,fbuf		;start of buf
  mov	[fbuf_ptr],edi

  mov	esi,[table_ptr]
  cmp	byte [esi],0
  jne	tr_10
  jmp	tr_done			;exit if no more groups
tr_10:
  mov	[find_str_ptr],esi	;pointer to find string	
tr_lp1:
  lodsb
  or	al,al
  jnz	tr_lp1			;loop till end of find-string

  mov	[replace_str_ptr],esi
tr_lp2:
  lodsb
  or	al,al
  jnz	tr_lp2			;scan to end of replace string

  mov	[actions_ptr],esi
tr_lp3:
  lodsb
  or	al,al
  jnz	tr_lp3			;loop till end of actions

  mov	[table_ptr],esi		;save pointer to next group
;
; we now have all three fields parsed
; begin processing of actions
; actions are stored as: n
; 
  call	decode_actions
  jmp	tr_main_lp
;-----------------------------------------------------------
; decode_actions - process one group of actions
;  inputs:  [actions_ptr] - points at actions
;           actions are: n  where n= 1-9
;
decode_actions:
;
; first find the match_string
;
  mov	edi,fbuf
  mov	[last_find],edi
  mov	[last_file_size],ebp

da_repeat:
  mov	esi,[find_str_ptr]
  mov	edx,1			;forward search
  mov	ch,0ffh			;match case
  call	blk_find
  jc	da_abort		;exit if string not found
;  inc	ebx			;adjust search location ???
;
; there are lots of possible infinite loops, check for them
;
  cmp	ebx,[last_find]
  jae	da_ok
  cmp	ebp,[last_file_size]
  jb	da_ok			;jmp if file  decreasing
da_abortx:
  jmp	da_abort2	;abort if possible infinite loop

da_ok:
  mov	[last_find],ebx		;store last find loc
  mov	[last_file_size],ebp
  mov	edi,ebx			;get fbuf ptr
  mov	[fbuf_ptr],edi

  mov	[tmp_fbuf_ptr],edi
  mov	esi,[actions_ptr]
  mov	[tmp_action_ptr],esi

da_cont:
  mov	[fbuf_ptr],edi		;adjust fbuf ptr
  mov	esi,[tmp_action_ptr]	;  
  xor	eax,eax			;clear eax
  lodsb
  cmp	al,"1"
  jb	da_abort
  cmp	al,"9"
  ja	da_abort
  sub	al,"1"			;form index
  shl	al,2
  add	eax,decode_table
  mov	[tmp_action_ptr],esi	;save actions ptr
  jmp	[eax]  

da_abort:
  stc
  jmp	da_exit2
da_exit:
  clc
da_exit2:
  ret
;--------------------------
da_abort2:
  mov	ecx,loop_msg
  call	crt_str
  jmp	fd_exit

;--------------------------
decode_table:
  dd	replace_string		;1
  dd	line_up			;2
  dd	line_down		;3
  dd	replace_line		;4
  dd	insert_line_above	;5
  dd	insert_line_below	;6
  dd	insert_string_infront	;7
  dd	delete_right		;8
  dd	do_forever		;9

replace_string:
  mov	eax,[replace_str_ptr]
  mov	ch,0ffh			;use case
  mov	esi,[find_str_ptr]
  mov	edi,[fbuf_ptr]
; mov	ebp,[fbuf_end_ptr]	;already setup?
  call	blk_replace
  jc	da_exit			;exit if string not found
  jmp	da_cont
	
line_up:
  call	prev_line_start
  jmp	da_cont
line_down:
  call	next_line_start
  jmp	da_cont

replace_line:
  call	next_line_start
  mov	ebx,edi		;save end of this line
  call	prev_line_start
  sub	ebx,edi		;compute length of this line
  mov	eax,ebx		;lenght of cut
  push	edi		;save
; mov	ebp,[file_end_ptr]
  call	blk_del_bytes
;
; now insert replace-string
;
  pop	edi		;get insert point
  mov	eax,[actions_ptr]
  sub	eax,[replace_str_ptr]
  dec	eax		;computed length of new string
  
  mov	esi,[replace_str_ptr]
  call	blk_insert_bytes
  mov	edi,[fbuf_ptr]	;restore origional fbuf ptr
  jmp	da_cont
 
insert_line_above:
  call	prev_line_start
  call	next_line_start

  mov	eax,[actions_ptr]
  sub	eax,[replace_str_ptr]
  dec	eax
  
  mov	esi,[replace_str_ptr]
  call	blk_insert_bytes
  jmp	da_cont  

insert_line_below:
  call	next_line_start

  mov	eax,[actions_ptr]
  sub	eax,[replace_str_ptr]
  dec	eax
  
  mov	esi,[replace_str_ptr]
  call	blk_insert_bytes
  mov	edi,[tmp_fbuf_ptr]	;restore origional fbuf ptr
  jmp	da_cont  

insert_string_infront:
  call	prev_line_start
  call	next_line_start

  mov	eax,[actions_ptr]
  sub	eax,[replace_str_ptr]
  dec	eax
  
  mov	esi,[replace_str_ptr]
  call	blk_insert_bytes
  mov	edi,[tmp_fbuf_ptr]	;restore origional fbuf ptr
  jmp	da_cont  

delete_right:
  mov	edi,[fbuf_ptr]
  mov	ebx,edi
  call	next_line_start
  sub	edi,ebx		;compute length cut area
  dec	edi		;adjust so 0ah kept
  mov	eax,edi		;lenght of cut
  mov	edi,ebx		;start of cut
  mov	[tmp_fbuf_ptr],edi	;save
; mov	ebp,[file_end_ptr]
  call	blk_del_bytes
  mov	edi,[tmp_fbuf_ptr]
  jmp	da_cont

  
do_forever:
  jmp	da_repeat

tr_done:
  ret

;------------------------------------------------
; input: fbuf_ptr
; output: fbuf_ptr, edi
;
prev_line_start:
  mov	edi,[fbuf_ptr]
pls_lp:
  cmp	edi,fbuf
  je	pls_done
  cmp	byte [edi -1],0ah
  je	pls_next
  dec	edi
  jmp	short pls_lp
pls_next:
  dec	edi
pls_lp2:
  cmp	byte [edi -1],0ah
  je	pls_done
  dec	edi
  jmp	pls_lp2
pls_done:
  mov	[fbuf_ptr],edi
  ret
;--------------------------------------------
; inputs: [fbuf_ptr]
; output: [bbuf_ptr], edi
;
next_line_start:
  mov	edi,[fbuf_ptr]
nls_lp:
  cmp	edi,ebp
  jae	nls_exit2		;exit if at end
  cmp	byte [edi],0ah
  je	nls_exit1
  inc	edi
  jmp	short nls_lp
nls_exit1:
  inc	edi
nls_exit2:
  mov	[fbuf_ptr],edi
  ret    

help_msg:
 db " Format_doc usage:    format_doc <in file>  <out file> ",0ah
 db 0ah
 db "the control file format_doc.ini must exist in local directory",0ah
 db "format.ini contains strings paired as follows:",0ah
 db " find-string replacement-string actions",0ah
 db " find string replacement string actions",0ah
 db " (each string must be enclosed with quote )",0ah
 db "  etc. ",0ah
 db " actions are: 1 - replace string",0ah
 db "              2 - move up one line",0ah
 db "              3 - move down one line",0ah
 db "              4 - replace match string line",0ah
 db "              5 - insert replace-string line above",0ah
 db "              6 - insert replace-string line below",0ah
 db "              7 - insert replace-string at front of line",0ah
 db "              8 - delete from match right to end of line",0ah
 db "              9 -  repeat actions",0ah
 db " multiple actions can be specified, but beware of",0ah
 db " infinite loops or impossible sequences",0ah
 db " most problems can be solved by moving the line",0ah
 db " down so match forever or replace forever is avoided",0ah
 db " example line:",0ah
 db "   ?match me?  ?replacement data? ?49?  <- ? is quote",0ah
 db "   replace all occurances of -match me- with -replacement data-",0ah
 db 0

loop_msg:
 db " Possible infinite loop in control table",0ah
 db " check all insert-below or line-up controls",0ah
 db " this occurs with  repeat functions that find and",0ah
 db " replace forever",0ah
 db 0

control_file: db "format_doc.ini",0

;-------------------------------------------------------
  [section .data]

;****f* -/format_doc.ini *
; NAME
;>2
;  format_doc.ini - control table for format_doc
; INPUTS
;  * table entries are repetitiions of the following
;  * three fields:
;  * "match-string" "replacement-string" "actions"
;  * -
;  * the code \n in strings can be used for new-line (0ah)
;  * -
;  * The actions available are:
;  * 1 replace the match string with replace-string
;  * 2 move up one line
;  * 3 move down one line
;  * 4 replace whole llne rather than just the match-string
;  * -  (line needs 0ah at end)
;  * 5 insert line above current line
;  * -  (line needs 0ah at end)
;  * 6 insert line below current line
;  * -  (line needs 0ah at end)
;  * 7 insert replace-string at front of current line
;  * 8 delete right to end of line
;  * - (place at start of actions to remove match ->)
;  * 9 do actions till end of file reached
; OUTPUT
;  * if program hangs or aborts this is almost always due
;  * to infinite loops caused by impossible actions.  Most
;  * problems can be avoided by keeping the match string
;  * pointer beyond last action.  This avoids finding the
;  * same string over and over when repeating actions.
;  * Use the code 3 to move match pointer down.
; NOTES
; * file:  format_doc.ini
; * The format_doc.ini file needs to be in current directory
;<
; * ----------------------------------------------
;*******

rtable:
times 4000 db 0

  [section .bss]

last_file_size	resd	1
last_find	resd	1
find_str_ptr	resd	1
replace_str_ptr	resd	1
actions_ptr	resd	1
tmp_action_ptr	resd	1
table_ptr	resd	1
fbuf_ptr	resd	1
tmp_fbuf_ptr	resd	1

in_file:	resd	1
out_file:	resd	1

;file_end_ptr	resd	1
pre_fbuf resb	1
fbuf	resd	64000
fbuf_end resb	1

 [section .text]
