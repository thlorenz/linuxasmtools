
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
  extern move_cursor
  extern crt_color_at
  extern lib_buf

 [section .text]


;****f* crt/crt_window *
; NAME
;>1 crt
;   crt_window - display one window/page of data
; INPUTS
;    esi = ptr to information block as follows
;          dword - color for page
;          dword - display data ptr
;          dword - end of all display data, (not end of this page)
;                  points at 0ah char beyond last data item.
;          dword - scroll count, 0=left edge not scrolled
;          byte  - total window columns 1+
;          byte  - total window rows 1+
;          byte  - starting row 1+
;          byte  - starting column 1+
; OUTPUT
;    none
; NOTES
;    source file crt_window.asm
;    buffer lib_buf is used to build each line displayed.
;    This buffer is a temp buffer available for general use.
;    lib_buf is 600 bytes long.
;<
;  * -------------------------------------------------------
;*******
  global crt_window
crt_window:
  mov	edi,page_inputs
  mov	ecx,5
  rep	movsd			;move input data block
  mov	esi,[data_ptr]
;
; start new line
;
cp_1:
  mov	ecx,[scroll_cnt]	;scroll (file line) right count
  mov	dl,[starting_col]	;starting loc for window
  mov	dh,[win_cols]		;total columns in window
  mov	edi,lib_buf		;data storage area
;
; registers: ecx = scroll
;            dl = diplsy column
;            dh = remaining columns in this window
;            esi = data ptr
;            edi = stuff ptr
;            
cp_2:
  cmp	esi,[data_end]
  jb	cp_4			;jmp if not at end of file
;
; fill screen with blanks
;
cp_3:
  mov	al,20h			;get space
cp_3a:
  call	stuff_char
  jnz	cp_3a			;loop till line filled
  call	cp_show_line
  jnz	cp_1			;loop till last line displayed
  jmp	short cp_exit		;exit
;
; check if more data for this line
;
cp_4:
  cmp	byte [esi],0ah		;check if at end of line
  jne	cp_10			;jmp if current line has data
;
; fill remainder of current lib_buf with blanks
;
  mov	al,20h			;get space
cp_5:
  call	stuff_char
  jnz	cp_5			;loop till line filled
  call	cp_show_line
  jz	cp_exit			;exit if end of window
;
; move to end of current input line
;
cp_6:
  cmp	esi,[data_end]
  je	cp_10
  lodsb
  cmp	al,0ah
  jne	cp_6
  jmp	cp_1
;
; add next input char to lib_buf
;  
cp_10:
  lodsb
  cmp	al,9
  je	cp_20			;jmp if tab
  cmp	al,20h			;legal char
  jb	cp_fix			;jmp if illegal char
  cmp	al,7eh
  jb	cp_20			;jmp if character ok
cp_fix:
  mov	al,' '
cp_20:
  call	stuff_char
  jnz	cp_2			;jmp if not end of line
  call	cp_show_line
  jnz	cp_6			;jmp if not end of window

;  jz	cp_exit			;exit if last line displayed
;
; check if at end of llne
;

cp_exit:
  ret  

;---------------------------------------------------
; inputs:  ecx,edx,esi,edi preserved
;          [color]
;          [lib_buf]
;          [starting_row]
;          edi = suff ptr
; output: zero flag set if window done

cp_show_line:
  push	ecx
  push	edx
  push	esi
  push	edi
  
  mov	eax,[color]
  mov	bl,[starting_col]
  mov	bh,[starting_row]
  mov	ecx,lib_buf
  mov	byte [edi],0		;terminate msg in lib_buf
  call	crt_color_at

  pop	edi
  pop	esi
  pop	edx
  pop	ecx

  inc	byte [starting_row]
  dec	byte [win_rows]
  ret

;---------------------------
; input:   al  = character
;          dl = current display column
;          dh = remaing display locations for this line
;          ecx = scroll count
;          edi = buffer store ptr for line
; output: if (zero flag) end of line reached
;         if (non zero flag) 
;             either character stored
;                 or ecx decremented if not at zero
;
stuff_char:
  cmp	al,09h		;check if tab
  jne	sc_40		;jmp if not tab
;
; expand tab
;
tab_loop:
  mov	al,20h
  call	stuff_char
  jz	sc_90		;exit if window edge encountered
  xor	eax,eax		;clear eax
  mov	al,dl
  sub	al,[starting_col]
  add	eax,[scroll_cnt]
  test	al,7
  jnz	tab_loop
  or	edx,edx		;clear zero flag
  jmp	short sc_90	;exit
;
sc_40:
  jecxz	sc_80		;jmp if scroll done
;
; scrolling data
;
  dec	ecx
  or	edx,edx		;clear zero flag
  jmp	short sc_90	;exit
;
; stuff character in line buffer
;
sc_80:
  stosb
  inc	dl		;bump display column
  dec	dh		;dec total columns in this window
sc_90:
  ret
 

;---------------------------
  [section .data]
page_inputs:
color		dd	0	;color
data_ptr	dd	0	;ptr to display data
data_end	dd	0	;end of buffer ptr, not end of this page
scroll_cnt	dd	0	;scroll position 0=left edge
win_cols	db	0	;number of columns in window 1+
win_rows	db	0	;number of rows in  window 1+ (counted down)
starting_row	db	0	;position for first row 1+
starting_col	db	0	;position for first column 1+
  [section .text]

