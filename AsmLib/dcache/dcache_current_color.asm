;---------------------------------------------------
; !!! users never need this !!! don't document
;send current color to display
; input: al = color byte
;color format.
;   aafffbbb  aa-attr fff-foreground  bbb-background
;    0-blk 1-red 2-grn 3-brwn 4-blu 5-purple 6-cyan 7-gry
;    attributes 0-normal 1-bold 4-underscore 7-inverse
;  extern on_screen_color
  extern image_write_color
  extern color_byte_expand
  extern dcache_str

  global dcache_current_color
dcache_current_color:
  mov	ah,al
  mov	[image_write_color],ah
;  mov	[on_screen_color],ah
  call	color_byte_expand	;out eax=screen string
  mov	ecx,eax		;msg to ecx
  call	dcache_str
  ret

