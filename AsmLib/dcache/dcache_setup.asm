  [section .text align=1]

;---------------------------------------------------
;>1 dcache
;  dcache_setup - setup for cached display
; INPUTS
;   ;eax = size of buffer, the display size
;          must be obtained from dcache_size. A
;          larger size allows for resized windows
;   ;ebx = buffer pointer for tables
;   ;dl = blank screen color code
;   ;dh = fd 0=use /dev/tty 1=stdout 2=stderr
;    [display_size]
;    [dcache_rows]
;    [dcache_columns]
; OUTPUT
;   ;js if error (buffer too small by neg about in eax)    
; NOTES
;    source file: dcache_setup.asm
;
;    The dcache keeps a image of display data and
;    only updates the display when dcache_flush is
;    called.  It is best to only use dcahe routines
;    for display handling, or avoid all dcache functions.
;
;    Typically the dcache is used as follows:
;    1. call dcache_size to get suggested buffer size
;    2. call dcache_setup with allocated buffer
;    3. build windowed display using write calls
;    4. after display is built, call dcache_flush.
;    5. If display is resized (winch signal) start
;       again at step 1.
;
;    Using dcache provides very fast displays and
;    provides a easy format to minipulate data.
;    Dcache does not work well for non-windowed
;    displays (text scrolling)
;<
; * ----------------------------------------------
;*******

  extern sys_open
  extern dcache_size
  extern open_tty
  extern dcache_clear
  extern dcache_screen_cursor
  extern dcache_str

;termio_struc_size:
  global dcache_setup
dcache_setup:
  mov	[image],ebx	;start of buffers
  mov	[current_index],ebx	;start pointer
  mov	[image_write_color],dl
  mov	[dcache_fd],dh
  or	dh,dh
  jnz	ds_size
  call	open_tty
  mov	[dcache_fd],ebx	;set new fd
ds_size:
;get display size
;  call	dcache_size		;get display -> ebx
;  mov	[display_size],ebx	;save size
;set terminal to wrap mode
wrap_setup:
  mov	ecx,wrap_string
  call	dcache_str
;fill buffers
  mov	al,[image_write_color]
  call	dcache_clear
;write default cursor position, out buffer ptrs
  xor	eax,eax
  mov	[current_index],eax	;restart index
  call	index_to_rowcol
  call	dcache_screen_cursor
  cmp	al,al			;clear sign flag
dcache_setup_exit:
  ret
;-------------------
  [section .data]
wrap_string: db 1bh,'[?7h',0	;wrap mode
  [section .text]
;-----------------------------------------------------
;---------------------------------------------------
;input: al=col 1+ ah=row 1+
  global rowcol_to_index
rowcol_to_index:
  movzx eax,ax
  dec	al
  dec	ah
  push	eax
  mov	al,ah
  mul	byte [dcache_columns]	;ax = row * col
  pop	ebx
  xchg	eax,ebx
  movzx eax,al		;isolate column
  add	eax,ebx		;add rows*width+column
  ret
;---------------------------------------------------
; input: eax = index
; output: al=col 1+  ah=row 1+
  global index_to_rowcol
index_to_rowcol:
  xor	edx,edx
  cmp	eax,[dcache_columns]
  jae	itr_1
  xchg	eax,edx
  jmp	short itr_2
itr_1:
  div	dword [dcache_columns]
itr_2:
  inc	eax
  inc	edx
  mov	ah,al	;move rows to ah
  mov	al,dl	;move columns to al
  ret
;---------------------------------------------------
; input: ah=color byte aafffbbb aa=atr fff=fore bbb=back
; output: eax=ptr to color string, length=13
  global color_byte_expand
color_byte_expand:
  push	eax
  and	ah,7
  or	ah,30h
  mov	[vcs1],ah
  pop	eax

  shr	ah,3
  push	eax
  and	ah,7
  or	ah,30h
  mov	[vcs2],ah
  pop	eax

  shr	ah,3
;  and	ah,1
  or	ah,30h
  mov	[vcs_atr],ah
  mov	eax,vt100_color_str
  ret
;----------------
  [section .data]

vt100_color_str:
  db	1bh,'['
vcs_atr:
  db	0,'m'
  db	1bh,'[4'
vcs1:			;background
  db	0		;ascii color number
  db	'm'
  db	1bh,'[3'
vcs2:			;foreground
  db	0		;ascii color number
  db	'm'
  db	0
  
 [section .text]
;---------------
;---------------------------------------------------
;---------------------------------------------------
;color format.
;   aafffbbb  aa-attr fff-foreground  bbb-background
;    0-blk 1-red 2-grn 3-brwn 4-blu 5-purple 6-cyan 7-gry
;    attributes 0-normal 1-bold 4-underscore 7-inverse
;-----------------------------------------------------
  [section .data]
  global dcache_rows,dcache_columns
dcache_rows: dd 0
dcache_columns: dd 0

  global display_size
display_size:    dd 0	;size in characters

;image buffer ends with "0"
;format (word) bit 15 = color changed flag
;                  14-8 = color code
;                  7  = data changed flag
;                  6-0 = char
  global image
image:  dd 0 ;ptr to image table

;the following use buffer cursor, actual screen cursor
;can be set with dcache_screen_cursor;
  global current_index
current_index: dd 0 ;ptr for writes to buffers
;  global on_screen_cursor_index
;on_screen_cursor_index: dd 0 ;actual screen cursor location
;  global on_screen_color
;on_screen_color: db 0 ;aafffbbb a=atr f=fore b=back
  global image_write_color
image_write_color: db 0
  global fill_flag
fill_flag	db 0	;0=no fill 1=fill
  global dcache_fd
dcache_fd:	dd 0
  [section .text]

