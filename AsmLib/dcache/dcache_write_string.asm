
;---------------------------------------------------
;>1 dcache
;dcache_write_string - write string to cache
;  write string and handle, tabs, line-feeds, truncate
;  at edge of screen, stop at zero char or
;  last line of screen.
;
; INPUT
;    esi = string ptr
;    color and cursor location already set
;
; OUTPUT
;     ah=color al=char out
;     dh=row   cl=column (next write positon)
;     esi=ptr beyond last input char written
;     edi=image index
;     ebp=top of image buffer
;<          
; registers kept: ah=color al=char out
;                 ebx -scratch
;                 ecx -scratch
;                 dh=row dl=col (track input data)
;                 esi=input data ptr
;                 edi=index into image
;                 ebp=image top
;                 
;---------------------------------------------------
;>1 dcache
;dcache_write_fstring - write string to cache and fill
;  same as dcache_write_string, with addition of fill
;  from end of string to right edge of display.
;
; INPUT
;   esi = string ptr
;   color and cursor location already set
;
; OUTPUT
;    ah=color al=char out
;    dh=row   cl=column (next write positon)
;    esi=ptr beyond last input char written
;    edi=image index
;    ebp=top of image buffer
;<          
; registers kept: ah=color al=char out
;                 ebx -scratch
;                 ecx -scratch
;                 dh=row dl=col (track input data)
;                 esi=input data ptr
;                 edi=index into image
;                 ebp=image top
;                 
;-------------------------------------------------
  extern fill_flag
  extern image
  extern index_to_rowcol
  extern rowcol_to_index
  extern current_index
  extern image_write_color
  extern dcache_columns
  extern dcache_rows

  global dcache_write_fstring,dcache_write_string
dcache_write_fstring:
  mov	al,1
  jmp	short dcache_entry
dcache_write_string:
  mov	al,0		;no fill
dcache_entry:
  mov	[fill_flag],al
  mov	ebp,[image]
  mov	eax,[current_index]
  call	index_to_rowcol
  mov	edx,eax		;dh=row dl=col
  mov	edi,[current_index]
  mov	ah,[image_write_color]
dws_loop:
  cmp	dl,[dcache_columns]
  ja	dws_scan	;jmp=check if more lines
  lodsb			;get char to write
  cmp	al,9		;tab?
  je	dws_tab		;jmp if tab
  jb	dws_fill	;jmp if end of string
  cmp	al,0ah
  je	dws_fill	;jmp if end of line
tab_entry:
  call	stuff
  jmp	short dws_loop
; we are at right edge, skip over input data
; till end of line, or end of string
dws_scan:
  lodsb
  cmp	al,0ah
  je	dws_fill	;jmp if end of line
  cmp	al,0
  jne	dws_scan
; we are at end of line or end of input data
; check if fill to edge or display needed
dws_fill:
  cmp	[fill_flag],byte 0
  je	dws_fill2	;jmp if no fill
  mov	al,0a0h		;space + flag
dws_fill_loop:
  cmp	dl,[dcache_columns]
  ja	dws_fill2
  call	stuff
  jmp	short dws_fill_loop
; check if more lines or done
dws_fill2:
  cmp	byte [esi -1],0ah ;end of line
  jne	dws_exit	;exit if done
; another line of data is available
  inc	dh		;bump row
  mov	dl,1		;set column
;compute index from row/col
  push	eax
  mov	eax,edx
  call	rowcol_to_index
  mov	edi,eax		;index to edi
  pop	eax

  cmp	dh,[dcache_rows] ;end of display?
  jne	dws_loop	;jmp if screen has room
dws_exit:
  mov	[current_index],edi
  ret

dws_tab:
  mov	al,dl		;get column
  and	al,07h		;isolate column
  cmp	al,7h		;at tab?
  mov	al,0a0h		;preload space
  je	tab_entry	;jmp if tab completion
  dec	esi		;move back to tab char
  jmp	tab_entry	;continue tab expansion

;-------------------------------------------
  global stuff
stuff:
  cmp	ax,[ebp+edi*2]
  je	dws_stuff_tail	;jmp if data unchanged
  or	ax,8080h	;set changed flags
  mov	[ebp+edi*2],ax  ;store data in image
  and	ax,~8080h	;clear flags
dws_stuff_tail:
  inc	edi		;move index
  inc	dl		;move column
  ret

