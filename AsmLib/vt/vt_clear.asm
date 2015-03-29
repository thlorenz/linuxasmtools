;---------------------------------------------------
;>1 vt
;vt_clear - clear screen buffer
; INPUT
;   [default_color] - set by vt_setup
; OUTPUT
;   
; NOTE
;   clear only sets display buffer, the function
;   vt_flush must be called to update display
;<
;---------------------------------------------------
  [section .text align=1]

  extern default_color
  extern vt_image
  extern vt_display_size
  extern vt_image_end

  global vt_clear
vt_clear:
  mov	ecx,[vt_display_size]
  mov	edi,[vt_image]
  mov	ah,[default_color]			;move color to ah
  or	ah,80h
  mov	al,' '	;space
  rep	stosw
  mov	[vt_image_end],edi
  xor	eax,eax
  stosw				;terminate buffer
  ret

