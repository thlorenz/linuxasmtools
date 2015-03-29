;---------------------------------------------------
;>1 vt
;vt_set_all_writes - set write all on next flush
; INPUT
;   none
; OUTPUT
;   none
; NOTES
;   source file: vt_set_all_writes.asm
;   Normally vt_flush only sends changed data
;   to the display, to resend all data, we need
;   to modify the changed flag within vt_image.
;<
;--------------------------------------------------
  [section .text align=1]

  extern vt_display_size
  extern vt_image

  global vt_set_all_writes
vt_set_all_writes:
  push	edi
  push	ecx
  mov	ecx,[vt_display_size]
  mov	edi,[vt_image]
dsaw_loop:
  mov	ax,[edi]	;get data
  or	ax,8000h	;set changed flags
  stosw
  loop	dsaw_loop
  pop	ecx
  pop	edi
  ret

