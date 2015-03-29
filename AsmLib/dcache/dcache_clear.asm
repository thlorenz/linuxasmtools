;---------------------------------------------------
;>1 dcache
;dcache_clear - clear screen buffer
; INPUT
;   al=color
; OUTPUT
;   
; NOTE
;   clear only sets display buffer, the function
;   dcache_flush must be called to update display
;<
;---------------------------------------------------
  extern dcache_current_color
  extern image
  extern display_size
;  extern on_screen_color
  extern image_write_color

  global dcache_clear
dcache_clear:
;write default color
  mov	[image_write_color],al
  call	dcache_current_color

  mov	ecx,[display_size]
  mov	edi,[image]
  mov	ah,[image_write_color]
  or	ah,80h
  mov	al,0a0h	;space + flag
  rep	stosw
  xor	eax,eax
  stosw				;terminate buffer
  ret

