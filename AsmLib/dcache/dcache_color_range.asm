;---------------------------------------------------
;>1 dcache
;dcache_color_range - set range of colors
; INPUT
;   ah=row  al=col
;   ch=color cl=length of range
; OUTPUT
;   none
; NOTE
;   color format.
;   aafffbbb  aa-attr fff-foreground  bbb-background
;    0-blk 1-red 2-grn 3-brwn 4-blu 5-purple 6-cyan 7-gry
;    attributes 0-normal 1-bold 4-underscore 7-inverse
;<
;-----------------------------------------------------

  extern rowcol_to_index
  extern image

  global dcache_color_range
dcache_color_range:
  push	ecx
  call	rowcol_to_index	;retruns index in eax
  pop	ebx		;get color + len
  mov	edi,[image]
  lea	edi,[edi+eax*2]	;compute stuff adr
  xor	ecx,ecx
  mov	cl,bl		;set range in ecx
  or	bh,80h		;set changed flag on color
dcr_range:
  mov	ax,[edi]	;get image data
  mov	ah,bh		;insert color
  or	al,80h		;set changed flag on data also
  stosw			;store data back
  loop	dcr_range
  ret


