
;---------------------------------------------------
;>1 dcache
;dcache_write_line - write line to cache
;  write line and handle, tabs, line-feeds, truncate
;  at edge of screen, stop at zero char or
;  last line of screen.
;
; INPUT
;   esi = line ptr
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
;                 ecx -scratch
;                 dh=row dl=col (track input data)
;                 esi=input data ptr
;                 edi=index into image
;                 ebp=image top
;                 
;---------------------------------------------------
;>1 dcache
;dcache_write_fline - write line to cache and fill
;  same as dcache_write_line, with addition of fill
;  from end of line to right edge of display.
;
; INPUT
;   esi = line ptr
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
;                 ecx -scratch
;                 dh=row dl=col (track input data)
;                 esi=input data ptr
;                 edi=index into image
;                 ebp=image top
;
;-------------------------------------------------
  extern fill_flag
  extern image
  extern current_index
  extern index_to_rowcol
  extern stuff
  extern image_write_color
  extern dcache_columns
  extern rowcol_to_index

  global dcache_write_fline,dcache_write_line                 
dcache_write_fline:
  mov	al,1
  jmp	short dcache_xentry
dcache_write_line:
  mov	al,0		;no fill
dcache_xentry:
  mov	[fill_flag],al
  mov	ebp,[image]
  mov	eax,[current_index]
  call	index_to_rowcol
  mov	edx,eax		;dh=row dl=col
  mov	edi,[current_index]
  mov	ah,[image_write_color]
dwl_loop:
  cmp	dl,[dcache_columns]
  ja	dwl_scan	;jmp=flush any unsued text
  lodsb			;get char to write
  cmp	al,9		;tab?
  je	dwl_tab		;jmp if tab
  jb	dwl_fill	;jmp if end of line
  cmp	al,0ah
  je	dwl_fill	;jmp if end of line
tab_xentry:
  call	stuff
  jmp	short dwl_loop
; we are at right edge, skip over input data
; till end of line, or end of line
dwl_scan:
  lodsb
  cmp	al,0ah
  je	dwl_fill	;jmp if end of line
  cmp	al,0
  jne	dwl_scan
; we are at end of line or end of input data
; check if fill to edge or display needed
dwl_fill:
  cmp	[fill_flag],byte 0
  je	dwl_fill2	;jmp if no fill
  mov	al,0a0h		;space + flag
dwl_fill_loop:
  cmp	dl,[dcache_columns]
  ja	dwl_fill2
  call	stuff
  jmp	short dwl_fill_loop
dwl_fill2:
;compute index from row/col
  push	eax
  mov	eax,edx
  call	rowcol_to_index
  mov	edi,eax		;index to edi
  pop	eax

dwl_exit:
  mov	[current_index],edi
  ret

dwl_tab:
  mov	al,dl		;get column
  and	al,07h		;isolate column
  cmp	al,7h		;at tab?
  mov	al,0a0h		;preload space
  je	tab_xentry	;jmp if tab completion
  dec	esi		;move back to tab char
  jmp	tab_xentry	;continue tab expansion

