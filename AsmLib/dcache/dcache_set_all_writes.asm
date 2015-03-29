;---------------------------------------------------
;>1 dcache
;dcache_set_all_writes - set write all on next flush
; INPUT
;   none
; OUTPUT
;   none
;<
;--------------------------------------------------

  extern display_size
  extern image

  global dcache_set_all_writes
dcache_set_all_writes:
  mov	ecx,[display_size]
  mov	edi,[image]
dsaw_loop:
  mov	ax,[edi+ecx*2]	;get data
  or	ax,8080h	;set changed flags
  stosw
  loop	dsaw_loop
  ret

