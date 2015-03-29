
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

  extern  blk_make_hole
  extern  blk_del_bytes

;****f* blk/paragraph *
; NAME
;>1 blk
;   paragraph - formats one paragraph
; INPUTS
;    esi = pointer inside paragraph somewhere
;    edi = start of buffer with all paragraphs
;    ebp = end of text data, (all paragraphs)
; OUTPUT
;    ebp = new end of text data
;    edi = end of reformated paragraph
; NOTES
;    file paragraph.asm
;    The paragraph function first finds the start and end of
;    current text block.  Next, it creates a hole at top to
;    place reformated data.  It is critical that text data
;    area can expand without overflowing work area.
;     
;    The start of all text must have a 0ah character infront
;    of the buffer.  the end of all text is expected to also
;    have a 0ah terminator.
;<
;  * --------------------------------------------------
;*******
 [section .text]

 global paragraph

; (#p#) paragraph     ***********************************

paragraph:
;
par_01a:
  mov	[end_of_text],ebp	;save end of text buffer, not
  mov	[start_of_text],edi
  mov	ecx,-1		;set boundry search up
;  mov	esi,[fbuf_cursor_ptr]
  call	para_check
  mov	esi,edx
par_01b:
  dec	esi
  cmp	byte [esi],0ah
  jne	par_01b
  inc	esi
  mov	[top_of_para],esi ;save top
;
; go look for bottom of paragraph
;
  mov	ecx,1
  call	para_check
  mov	[end_of_para],edx
  cmp	edx,[top_of_para]
  jne	p_05
  jmp	par_60  
;
; make hole to give us some work room
;
p_05:
  mov	eax,100
  mov	edi,[top_of_para]
  push	edi
  push	ebp
  mov	ebp,[end_of_text]
;  call	make_hole
  call	blk_make_hole
  mov	[end_of_text],ebp	;save new end point
  pop	ebp
  pop	edi		;edi points to top of work area (fill)
  mov	esi,[top_of_para]
  add	esi,100
  mov	ebp,[end_of_para]
  add	ebp,100
;
;     edi - top fill ptr
;     esi - top of paragraph
;     ebp - end of paragraph
;
  mov	bl,[left_margin]
  mov	bh,[right_margin]
;
; this is the top of loop to format one line
;
par_06:
  mov	dl,1			;current column
;
; adjust for left margin by stuffing blanks till start of paragraph reached
;
par_08:
  mov	al,' '
  cmp	dl,[left_margin]	;dl=current column
  je	par_09			;jmp if at left margin starting point
  stosb				;store space
  inc	dl			;bump column
  jmp	par_08			;loop till left margin reached
;
; skip leading blanks at line beginning
;
par_09:
  cmp	byte [esi],' '		;blank at beginning of line?
  jne	par_10			;jmp if non-blank found
  inc	esi
  jmp	par_09			;remove leading blanks
;
; loop to move data [esi] -> [edi] till right_margin reached.
; replace 0ah with space
; 
par_10:
  cmp	esi,ebp
  jae	par_50			;jmp if paragraph formatted
  lodsb				;get next char.
  cmp	al,0ah
  jne	par_10a			;jmp if not 0ah
  mov	al,' '			;substitute space
par_10a:
  cmp	al,' '
  jne	par_11			;jmp if not space
  cmp	byte [edi-1],al		;did we store a space last?
  jne	par_11
  jmp	par_10			;skip this space
par_11:
  stosb
  inc	dl
  cmp	dl,[right_margin]
  jne	par_10			;loop till margin reached
;
; we have reached right margin.  now backtrack if cutting word in half
;
  cmp	al,' '
  je	par_12			;jmp if last character was space
  cmp	byte [esi],' '		;is next char a space
  jne	par_20			;jmp if partial word
  lodsb				;get space and ignore it
par_12:
  mov	al,0ah
  stosb
  jmp	par_06			;continue fill
;
; we are at right margin and a word is split, check if whole line is one word
;
par_20:
  push	edi			;save stuff ptr
  mov	ah,dl			;get right margin in -ah-
  shr	ah,1			;compute center of line
par_24:
  dec	ah
  jz	par_30			;jmp if this word too big to split
  dec	edi
  cmp	byte [edi],' '
  jne	par_24			;loop till beginning of word found
  pop	edi			;restore edi
  jmp	par_40			;go move word to next line
;
; split this big word and hope for best
;
par_30:
  pop	edi
  jmp	par_12
;
; we are still at right margin and it is possible to move split word to next line.
; go back to beginning of partial word and blank it out
;
par_40:
  mov	al,' '
  dec	esi
  dec	edi
;  mov	byte [edi],al		;blank partial word
  cmp	byte [edi],al
  jne	par_40			;loop till beginning of word found
;
; we are sitting on space before last word
;
  inc	esi			;skip over space
  mov	al,0ah
  stosb
  jmp	par_06			;go do next line  
;
; paragraph now formated, close hole
;  edi - points at end of good paragraph
;  esi/ebp - point at end of work area
;
par_50:
  mov	eax,esi		;get end of block
  sub	eax,edi		;compute size of hole
;  call	DeleteByte	;close hole
  mov	ebp,[end_of_text]
  call	blk_del_bytes
  mov	[end_of_text],ebp	;set end of data ptr

par_60:
  mov	edi,[end_of_para]
par_exit:
  mov	ebp,[end_of_text]
  ret  

;--------------
; assist with check for begin/end of paragraph
;  input: esi = current locaton in buffer
;         ecx = 1(search forward)  -1(search backwards)
; output:  esi = pointer to current char
;          edx = pointer to last text char (paragraph area)
;
para_check:
  mov	bl,0
  mov	edx,esi		;preload paragraph start
para_lp:
  cmp	cl,1
  je	pc_2		;jmp if forward scan
  cmp	esi,[start_of_text]
  jmp	pc_4		;
pc_2:
  cmp	esi,[end_of_text]
pc_4:
  je	pc_stop
pc_lp:
  mov	al,[esi]	;get current char
  cmp	al,09h		;check if tab
  je	pc_30		;go ignore tabs
  cmp	al,' '
  je	pc_30  		;jmp to ignore space
  cmp	al,0ah
  je	pc_got_a
  mov	bl,0		;set consecutive 0a count to zero
  mov	edx,esi		;save text ptr
  jmp	pc_30
pc_got_a:
  inc	bl
  cmp	bl,2
  je	pc_exit
pc_30:
  add	esi,ecx
  cmp	esi,[start_of_text]
  je	pc_exit
  cmp	esi,[end_of_text]
  je	pc_exit
  jmp	pc_lp
pc_stop:
  mov	edx,esi
pc_exit:
  ret
;****f* blk/margins *
; NAME
;>1 blk
;  margins - sets margins for paragraph function
; INPUTS
;  * ah = left margin, 1=left most column
;  * al = right margin, (right most column)
; OUTPUT
;  * none
; NOTES
;  * file: paragraph.asm
;<
;  * -----------------------------------------------
;*******
  global margins
margins:
  mov	byte [left_margin],ah
  mov	byte [right_margin],al
  ret
;---------------------------------------------------
 [section .data]
top_of_para	dd	0	;points at first data char
end_of_para	dd	0	;points at first 0ah pair
left_margin	db	1
right_margin	db	65
end_of_text	dd	0	;points to end of all paragraphs
start_of_text	dd	0	;points to start of all paragraphs
  [section .text]

