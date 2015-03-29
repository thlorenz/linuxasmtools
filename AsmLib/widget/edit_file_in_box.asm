
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

struc window_def
.page_color	resd	1	;window color
.display_ptr	resd	1	;top of display page
.end_ptr		resd	1	;end of file
.scroll_count	resd	1	;right/left window scroll count
.win_columns	resb	1	;window columns (1 based)
.win_rows	resb	1	;window rows (1 based)
.start_row	resb	1	;starting window row (1 based)
.start_col	resb	1	;starting window column (1 based)
.outline_color	resd	1
endstruc

;------------------------------
;****f* widget/edit_file_in_box *
; NAME
;>1 widget
;   edit_file_in_box - edit small file inside box
; INPUTS
;    ebx = ptr to full path of file or local file
;    ecx = buffer size needed for file
;    esi = pointer to structure below
;      dd window color (see notes)
;      dd data pointer. (set by edit_file_in_box )
;      dd end of data ptr, beyond last display char.
;         (end of data is set by edit_file_in_box )
;      dd initial scroll left/right position
;      db columns inside box
;      db rows inside box
;      db starting row (upper left corner row)
;      db starting column (upper left corner column)
;      dd outline box color (see notes)
;         (set to zero to disable outline)
;    lib_buf is used to build display lines
;    keyboard is assumed to be in "raw" mode, see: crt_open
;     
;    example: 
;        call	crt_open
;        mov	ebx,filename
;        mov	ecx,1024	;file buffer size
;        mov	esi,boxplus     ;parameter block
;        call	edit_file_in_box
;        call	crt_close
;        mov	eax,1
;        int	80h
;      
;        [section .data]
;      filename: db 'local_file',0
;      
;      boxplus:
;      	dd	30003436h	;window color
;      	dd	0		;filled in
;      	dd	0		;filled in
;      	dd	0		;scroll
;      	db	50		;columns
;      	db	10		;rows
;      	db	3		;starting row
;      	db	3		;starting column
;      	dd	30003131h	;color for outline box
;      
; OUTPUT
;   eax = negative system error# or positive if success
; NOTES
;    source file edit_text_in_box.asm
;    -
;    usage: keys are up,down,right,left,enter
;    -      The tab,pgup,pgdn keys are ignored
;    -      All other keys pop up a menu
;    -
;    The current window width is not checked, edit_text_in_box
;    will attempth display even if window size too small.
;    -
;    Tabs are not handled and should not be used.
;    - 
;    color = aaxxffbb aa-attr ff-foreground  bb-background
;    30-blk 31-red 32-grn 33-brn 34-blu 35-purple 36-cyan 37-gry
;    attributes 30-normal 31-bold 34-underscore 37-inverse
;<
;  * ---------------------------------------------------
;*******
  extern mmap_open_rw
  extern mmap_close
  extern top_ptr,end_ptr
  extern edit_text_in_box

  global edit_file_in_box
edit_file_in_box:
  push	ecx		;save buffer size
  call	mmap_open_rw
  mov	[file_descriptor],ebx
  pop	edx		;get buffer size
  js	eb_exit		;exit if error
; ecx = ptr to file contents, eax=file length, ebx=ptr to mmap block 
; edx = buffer length
  add	edx,ecx			;compute buffer end ptr now in edx
  mov	[esi + window_def.display_ptr],ecx
  add	eax,ecx			;compute file end ptr
  mov	[esi + window_def.end_ptr],eax	;save file end ptr
  mov	ecx,edx			;ecx = buffer end ptr
  
  call	edit_text_in_box

eb_exit1:
  mov	eax,[file_descriptor]
  mov	ebx,[top_ptr]		;get file data address
  mov	ecx,[end_ptr]		;compute file
  sub	ecx,ebx			;  size
  call	mmap_close
eb_exit:
  ret

;---------
  [section .data]
file_descriptor dd 0
  [section .text]

