;---------------------------------------------------
;>1 dcache
;dcache_read_char - read range of characters
; INPUT
;   ah=row  al=col
;   ecx=range
;   edi=storage adr
; OUTPUT
;   eax,ebx,ecx modified
;   edi points beyond last char stored.
;<
;---------------------------------------------------
  extern rowcol_to_index
  extern image

  global dcache_read_char
dcache_read_char:
  call	rowcol_to_index  ;eax=index ebx-modified
  mov	ebx,[image]
drc_loop:
  mov	ax,[ebx+ecx*2]	;get data
  and	al,7fh		;remove modified flag
  stosb
  loop	drc_loop  
  ret

