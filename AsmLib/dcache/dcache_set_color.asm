;---------------------------------------------------
;>1 dcache
; dcache_set_color - set color for image write functons
; INPUT
;   al=color
; OUTPUT
;   all register unchanged
; NOTE
;   color format.
;   aafffbbb  aa-attr fff-foreground  bbb-background
;    0-blk 1-red 2-grn 3-brwn 4-blu 5-purple 6-cyan 7-gry
;    attributes 0-normal 1-bold 4-underscore 7-inverse
;<
;----------------------------------------------------
  extern image_write_color
  global dcache_set_color
dcache_set_color:
  mov	[image_write_color],al
  ret

