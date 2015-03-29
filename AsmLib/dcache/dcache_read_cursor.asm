;---------------------------------------------------
;>1 dcache
;dcache_read_cursor - read current cursor position for next write
; INPUT
;   none
; OUTPUT
;   ah=row al=col
;<
  extern current_index
  extern index_to_rowcol

  global dcache_read_cursor
dcache_read_cursor:
  mov	eax,[current_index]
  call	index_to_rowcol
  ret

