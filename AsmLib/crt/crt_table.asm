
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
  extern lib_buf

  extern norm_text_color,bold_edit_color
  extern high_text_color,asm_text_color
  extern status_color,status_color1,status_color2
  extern exit_screen_color
  extern left_column
  extern mov_color
  extern crt_rows,crt_columns
  extern move_cursor,crt_str,str_move

  [section .text]

	%define stdin 0
	%define stdout 0x1
	%define stderr 0x2
 [section .text]

;****f* crt/crt_table *
;
; NAME
;>1 crt
;  crt_table - display screen of data using table
; INPUTS
;    esi = ptr to table data
;    [win_rows] - global variable set by crt_open
;    [left_column] - global dword for scroll right-left, set by caller
;    [lib_buf] - temp buffer used internaly
;    colors described below are contained in file lib_data.asm and
;      can be modified.
; OUTPUT
; 
; NOTES
;   file crt_table.asm
;   Tables contain a mix of color information, line information, and
;   negative codes indicating the process for ajacent data.  If a
;   mouse click occurs on the screen, the table can be scaned for
;   a negative number that signals the process to run.
;   The caller can change colors as user clicks on various areas.
;   The a_todo program edit mode uses this function.
;    
;   codes:  0 - end of table
;           1 - normal color
;           2 - edit/select field color
;           3 - active edit/select field color
;           4 - button color color
;           5 - blank all rows from here to [window_rows]
;           9 - add blanks to end of line, init for next line
;          -x - process code for mouse clicks
;    
;   sample table --------------------
;    
;   db -67	;trap to catch clicks at upper left corner of screen
;   edit_table:
;   db 1,'  ',-73,4,'Previous(PgUp)',1,'  '
;   db -74,4,'Next(PgDn)',1,'  ',-65,4,'Delete(F8)',1,'  '
;   db -67,4,'Abort edits(F9)',1,'  ',-66,4,'Done(F10)',1,9
;   db 1,9
;   db 1,'todo state:   ',-1,2
;   pending
;   db 'Pending',1,'   ',-2,2
;   completed
;   db 'completed',1,'   ',-3,2
;   deleted
;   db 'deleted',1,9
;   db 1,9
;   db	1,9
;   db 5
;   db 0
;   edit_table_end
;
;     see also: crt_table_loc, cursor_to_table
;<
; * ----------------------------------------------
;*******
  global crt_table
crt_table:
  mov	dh,1			;row
td_next_line:
  mov	edi,lib_buf		;storage buffer
  mov	dl,1			;column
  mov	ecx,[left_column]	;get scroll count
td_lp:
  lodsb
  test	al,80h
  jnz	td_lp			;jmp/ignore special processing codes
  cmp	al,9
  jbe	td_20			;jmp if function found
  jecxz	td_10			;jmp if left column scroll not needed
  dec	ecx
  jmp	short td_lp
td_10:
  stosb				;store data
  inc	dl
  jmp	td_lp
td_20:
  cmp	al,9
  jne	td_15
  jmp	td_30			;jmp if tail needed
td_15:
  cmp	al,5
  jne	td_21
  jmp	td_40			;jmp if end of data
td_21:
  mov	ebx,[norm_text_color]
  cmp	al,1
  jne	td_2x
  jmp	td_50			;jmp if color 1
td_2x:
  mov	ebx,[bold_edit_color]
  cmp	al,2
  jne	td_22
  jmp	td_50			;jmp if color 2
td_22:
  mov	ebx,[high_text_color]
  cmp	al,3
  je	td_50			;jmp if color 3
  mov	ebx,[status_color]	;button color
  cmp	al,4
  je	td_50			;jmp if color 4
  cmp	al,0
  je	td_90			;jmp if end of table
;
; write blanks to end of line, init for next line
;
td_30:
  call	display_tail
  inc	dh			;bump row
  jmp	td_next_line
;
; we are at end of data, fill remaining lines with blanks
;
td_40:
  mov	dl,[crt_rows]
  inc	dl
  cmp	dl,dh
  jbe	td_90			;exit if done
  mov	edi,lib_buf		;storage buffer
  mov	ecx,[left_column]	;get scroll count
  mov	dl,1			;start from column 1
  call	display_tail
  inc	dh
  jmp	td_40
;
; handle colors
;
td_50:
  mov	eax,ebx
  push	edx
  call	mov_color
  pop	edx
  jmp	td_lp
;
td_90:
  ret

;---------------------------------------
; fill blanks to end of screen, display line,  and init for next line
;
display_tail:
  push	edx
;
; write blanks to end of line
;
  mov	al,' '
dt10:
  cmp	dl,[crt_columns] ;check if at end of line
  ja	dt20		;jmp if at end
  stosb
  inc	dl
  jmp	short dt10	;loop till line filled out
dt20:
  mov	byte [edi],0	;terminate text in lib_buf
  mov	eax,edx
  mov	al,1		;display from column 1
  call	move_cursor
  mov	ecx,lib_buf
  call	crt_str
  pop	edx
  ret

;****f* crt/crt_table_loc *
; NAME
;>1 crt
;   crt_table_loc - use table ptr to find crt row/col
; INPUTS
;    esi = ptr to top of table
;    edi = ptr any location inside table
; OUTPUT
;    ah = row
;    al = column
; NOTES
;    source file crt_table.asm
;    see also: crt_table, cursor_to_table
;<
;  * ----------------------------------------------
;*******
  global crt_table_loc
crt_table_loc:
  mov	byte [edit_click_row],1
  mov	byte [edit_click_column],1
ttc_lp:
  cmp	esi,edi			;compare esi (trial) to target (edi)
  je	ttc_exit		;jmp if done
  mov	al,[esi]		;get table entry
  cmp	al,0			;check if end of table
  je    ttc_exit		;exit if end
  test	al,80h			;check if process code
  jnz	ttc_next		;jmp if process code
  cmp	al,9
  ja	ttc_text		;jmp if normal text char
  je	ttc_line		;jmp if end of line
  jmp	ttc_next		;ignore all others
ttc_line:
  inc	byte [edit_click_row]
  mov	byte [edit_click_column],1
  jmp	ttc_next
ttc_text:
  inc	byte [edit_click_column]
ttc_next:
  inc	esi
  jmp	ttc_lp
ttc_exit:
  mov	ah,[edit_click_row]
  mov	al,[edit_click_column]
  ret

  [section .data]
edit_click_row:	db	0
edit_click_column db	0
  [section .text]

;****f* crt/cursor_to_table *
;
; NAME
;>1 crt
;  cursor_to_table - find table location from cursor row/col
; INPUTS
;     esi = ptr to top of table
;     cl = target column
;     ch = target row 
; OUTPUT
;     esi = table pointer for target row/column
; NOTES
;    file crt_table.asm
;    see also: crt_table, crt_table_loc
;<
;  * ----------------------------------------------
;*******
  global cursor_to_table
cursor_to_table:
  mov	bh,1			;set startng row
  mov	bl,1			;set starting column
ctt_lp1:
  cmp	ch,bh			;check if target row (ch) matches current (bh)
  je	ctt_lp2			;jmp if correct row found
  lodsb				;get next table entry
  cmp	al,9			;check if end of line
  je	ctt_02			;jmp if eol  
  cmp	al,0
  je	ctt_exit		;jmp if click outside table
  jmp	ctt_lp1
ctt_02:
  inc	bh			;bump row
  jmp	ctt_lp1			;loop till row found
;
; correct row found, now look for column match
;
ctt_lp2:
  lodsb
ctt_08:
  cmp	al,9
  jb	ctt_lp2			;jmp if control byte
  je	ctt_exit		;jmp if no match on this line
  test	al,80h
  jnz	ctt_lp2			;jmp if process code
  cmp	cl,bl			;check if target column (cl) matches curent (bl)
  je	ctt_match		;jmp if column found
  inc	bl			;bump column
  jmp	ctt_lp2
ctt_match:
;why was this put in? it screws up "form"
;  inc	esi			;? adjustment from debugging scession
ctt_exit:
  ret
;---------------------------------------------
