;---------------------------------------------------
;>1 vt
;rowcol_to_image - compute location in screen buffer
; INPUT
;   bh = row     1+
;   bl = colulmn 1+
; OUTPUT
;   ebp = ptr to screen buffer
;     ;the screen buffer contains:
;                  (word) bit 15 = color/data changed flag
;                  14-8 = color code
;                  7-0  = char
;     if accessed as bytes, data1,color1,data2,color2
;
; NOTE
;   source file: vt_rowcol.asm
;<
;---------------------------------------------------
  [section .text align=1]

  extern vt_columns
  extern vt_image
;-------------------------------
; input: bl=stuff col
;        bh=stuff row
; output: ebp=stuff ptr
  global rowcol_to_image
rowcol_to_image:
  xor	eax,eax
  mov	al,bh	;get row
  dec	al		;make zero based
  mov	ah,[vt_columns] ;rows*columns_per_row
  mul	ah		;rows*columns_per_row
  add	al,bl   	;add in columns
  adc	ah,0		;add in columns
  dec	eax		;adjust to zero based
  shl	eax,1	;row*col*2
  add	eax,[vt_image]
  mov	ebp,eax
  ret

