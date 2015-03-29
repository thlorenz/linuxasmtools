;---------------------------------------------------
;>1 dcache
;  dcache_size - compute screen size in chars
; INPUTS
;   none
; OUTPUT
;   if no carry
;    ebx = screen size
;    eax = suggested buffer size
;   if carry, can't get tty 
; NOTES
;    source file: dcache_size.asm
;<
; * ----------------------------------------------
struc wnsize_struc
.ws_row:resw 1
.ws_col:resw 1
.ws_xpixel:resw 1
.ws_ypixel:resw 1
endstruc
;wnsize_struc_size

  extern dcache_rows
  extern dcache_columns
  extern display_size
  extern read_window_size
  extern crt_rows,crt_columns

  global dcache_size 
dcache_size:
;get display size
  call	read_window_size
  mov	eax,[crt_rows]
  or	eax,eax
  jz	ds_fail
  mov	[dcache_rows],ax
  mov	eax,[crt_columns]
  mov	[dcache_columns],ax

;compute index size.
  mul	word [dcache_rows]  
  mov	ebx,eax		;move size of index
  inc	eax		;allow for ending word
  shl	eax,1		;multiply by 2
  clc
  jmp	short ds_exit
ds_fail:
  stc
ds_exit:
  mov	[display_size],ebx
  ret
;-------------
  [section .data]
;winsize:
;s_row:	dw 0
;s_col:	dw 0
;s_xpixel: dw 0
;s_ypixel: dw 0

  [section .text]

