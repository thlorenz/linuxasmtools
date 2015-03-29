;---------------------------------------------------
;>1 dcache
;dcache_write_block - write block to cache
;  write block and handle, tabs, line-feeds, truncate
;  at edge of screen, stop at zero char or
;  last line of screen.
;
; INPUT
;    esi = block ptr
;    ecx = block length
;    color and cursor location already set
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
;                 ecx= count of input data remaining
;                 dh=row dl=col (track input data)
;                 esi=input data ptr
;                 edi=index into image
;                 ebp=image top
;                 
;---------------------------------------------------
;>1 dcache
;dcache_write_fblock - write block to cache and fill
;  same as dcache_write_block, with addition of fill
;  from end of block to right edge of display.
;
; INPUT 
;   esi = block ptr
;   ecx = block length
;   color and cursor location already set
;
; OUTPUT
;   ah=color al=char out
;   dh=row   cl=column (next write positon)
;   esi=ptr beyond last input char written
;   edi=image index
;   ebp=top of image buffer
;<
; registers kept: ah=color al=char out
;                 ebx -scratch
;                 ecx= count of input data remaining
;                 dh=row dl=col (track input data)
;                 esi=input data ptr
;                 edi=index into image
;                 ebp=image top
;                 
;---------------------------------------------------
  extern image
  extern fill_flag
  extern current_index
  extern index_to_rowcol
  extern image_write_color
  extern dcache_columns
  extern stuff
  extern rowcol_to_index
  extern dcache_rows

  global dcache_write_fblock,dcache_write_block
dcache_write_fblock:
  mov	al,1
  jmp	short dcache_bentry
dcache_write_block:
  mov	al,0		;no fill
dcache_bentry:
  mov	[fill_flag],al
  mov	ebp,[image]
  mov	eax,[current_index]
  call	index_to_rowcol
  mov	edx,eax		;dh=row dl=col
  mov	edi,[current_index]
  mov	ah,[image_write_color]
dwb_loop:
  jecxz	dwb_fill	;jmp if end of block
  cmp	dl,[dcache_columns]
  ja	dwb_scan	;jmp=check if more lines
  lodsb			;get char to write
  cmp	al,9		;tab?
  je	dwb_tab		;jmp if tab
  cmp	al,0ah
  je	dwb_fill	;jmp if end of line
tab_bentry:
  call	stuff
  dec	ecx
  jmp	short dwb_loop
; we are at right edge, skip over input data
; till end of line, or end of block
dwb_scan:
  dec	ecx
  jecxz	dwb_fill
  lodsb
  cmp	al,0ah
  jne	dwb_scan
; we are at end of line or end of input data
; check if fill to edge or display needed
dwb_fill:
  cmp	[fill_flag],byte 0
  je	dwb_fill2	;jmp if no fill
  mov	al,0a0h		;space + flag
dwb_fill_loop:
  cmp	dl,[dcache_columns]
  ja	dwb_fill2
  call	stuff
  jmp	short dwb_fill_loop
; check if more lines or done
dwb_fill2:
  jecxz	dwb_exit	;exit if done
; another line of data is available
  inc	dh		;bump row
  mov	dl,1		;set column
;compute index from row/col
  push	eax
  push	ecx
  mov	eax,edx
  call	rowcol_to_index
  mov	edi,eax		;index to edi
  pop	ecx
  pop	eax

  cmp	dh,[dcache_rows] ;end of display?
  jne	dwb_loop	;jmp if screen has room
dwb_exit:
  mov	[current_index],edi
  ret

dwb_tab:
  mov	al,dl		;get column
  and	al,07h		;isolate column
  cmp	al,7h		;at tab?
  mov	al,0a0h		;preload space
  je	tab_bentry	;jmp if tab completion
  dec	esi		;move back to tab char
  jmp	tab_bentry	;continue tab expansion

