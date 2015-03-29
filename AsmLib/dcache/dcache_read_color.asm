;---------------------------------------------------
;>1 dcache
;dcache_read_color - read color at location
; INPUT
;   ah=row  al=col
;   ecx=range
;   edi=storage adr
; OUTPUT
;   eax,ebx,ecx,edi modified
;   edi points beyond last color char.
; NOTE
;   color format.
;   aafffbbb  aa-attr fff-foreground  bbb-background
;    0-blk 1-red 2-grn 3-brwn 4-blu 5-purple 6-cyan 7-gry
;    attributes 0-normal 1-bold 4-underscore 7-inverse
;<
  extern rowcol_to_index
  extern image
  global dcache_read_color
         
dcache_read_color:
  call	rowcol_to_index  ;eax=index ebx-modified
  mov	ebx,[image]
drx_loop:
  mov	ax,[ebx+ecx*2]	;get data
  and	ah,7fh		;remove modified flag
  mov	al,ah
  stosb
  loop	drx_loop  
  ret

