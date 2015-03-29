 [section .text]
 extern lib_buf
 extern move_cursor
 extern crt_write
 extern mov_color

;****f* crt/show_line *
; NAME
;>1 crt
;  show_line - display line with embedded color codes
;     and fit line into window area
; INPUTS
;    ebx = ptr to color list, each color def is dword
;    ch = starting row 1+
;    cl = starting column 1+
;    [crt_columns] = max line length, must be 1+
;    esi = ptr to data for line, each line end with 0ah, or 0
;      color codes start at 1 (first color in table)
;      color codes 1-9 are possible.
;    edi = scroll counter
; OUTPUT
;    line is built in buffer lib_buf then displayed
;    esi - points at char beyond 0ah
; NOTES
;   source file: show_line.asm
;<
; * ----------------------------------------------
;*******
  global show_line
show_line:
  mov	[cl_scroll],edi
  mov	edi,lib_buf
  xor	edx,edx		;current column
;set color for start of line
cl_color:
  mov	eax,[ebx]	;get color 1
  call	mov_color
cl_lp1:
  lodsb
  cmp	al,09h		;check if  tab
  jne	cl_check	;jmp if not tab
;process tab
  mov	al,' '
tab_lp:
  call	stuff_char
  test	dh,7
  jz	cl_lp1
  jmp	short tab_lp
cl_check:
  cmp	al,0ah
  je	cl_eol		;jmp if end of line or color
  call	stuff_char
  jz	cl_lp2		;jmp if at right edge of screen
  cmp	al,'<'		;check if possible start of link
  jne	cl_lp1		;jmp if not link
  cmp	esi,[selector_ptr]	;is this the selector?
  jne	cl_lp1		;jmp if not link
  call	link_handler
  jmp	short cl_lp1
; adjust input data ptr to end of line, for callers convience
cl_lp2:
  lodsb
  or	al,al
  jz	cl_line		;jmp if end of line found
  cmp	al,0ah
  jne	cl_lp2
  jmp	short cl_line	;jmp if at right edge of window
cl_eol:
;  mov	al,' '
;  call	stuff_char
;  jnz	cl_eol
; line is built, now display
cl_line:  
  mov	byte [edi],0	;terminate line
; move cursor
  mov	eax,ecx		;get row and column
  call	move_cursor
; display line
  mov	ecx,lib_buf
  mov	edx,edi
  sub	edx,ecx		;compute line length
  call	crt_write
  ret
;--------------------------------------------
; input edi = stuff ptr
;        al = character to buffer
;        edx = display column
;       [scroll] = scroll counter
; output: edx = new display column
;         flag = jz set if end of display
;       edi = updated stuff ptr
;
stuff_char:
  cmp	dword [cl_scroll],0
  je	sc_cont			;jmp if no scroll
  dec	dword [cl_scroll]
  or	eax,eax			;remove jz flag for exit state
  jmp	sc_exit
sc_cont:
  stosb				;store char
  inc	edx			;bump column 
  cmp	edx,[crt_columns]
sc_exit:
  ret

;------------------
  [section .data]
cl_scroll:	dd	0
  [section .text]

;------------------------------------------------------

link_handler:
  mov	eax,[ebx+4]	;get color 2
  call	mov_color
lh_loop:
  lodsb		;get next char
  cmp	al,'>'	;end of link?
  je	lh_done
  call	stuff_char
  jmp	short lh_loop
lh_done:
  dec	esi
  mov	eax,[ebx]
  call	mov_color
lh_exit:
  ret
