;memory_end - allocation end
;history_ptr - start of history buffer

history_setup:
  mov	eax,history_buf
  call	put_pop_string_setup
  mov	eax,dword_history_buf
  call	put_pop_dword_setup
hs_ok:
  ret



;------------------------------------
; input: eax=buffer ptr
;
put_pop_string_setup:
  mov	[string_top_ptr],eax
  mov	[string_put_ptr],eax
  ret
;-----------------------------------
; input: esi=put value
; output: esi=ptr to end of input string
put_string:
  push	edi
  mov	edi,[string_put_ptr]
  call	str_move
  inc	edi			;move past zero at end
  mov	[string_put_ptr],edi
  pop	edi
  ret
;-----------------------------------
; input: edi=storage loc for string
; output: carry set if at top already
;         edi = ptr to zero at end of string if "no carry"
pop_string:
  push	esi
  mov	esi,[string_put_ptr]
  cmp	esi,[string_top_ptr]
  je	ps_error	;exit if at top
  dec	esi		;move to zero at end of prev string
ps_lp:
  dec	esi
  cmp	esi,[string_top_ptr]
  jbe	ps_at_top
  cmp	byte [esi],0
  jne	ps_lp
  inc	esi		;move past zero
ps_at_top:
  mov	[string_put_ptr],esi
  call	str_move
  clc
  jmp	short ps_exit
ps_error:
  stc
ps_exit:
  pop	esi
  ret
;--------------
  [section .data]
string_top_ptr: dd 0
string_put_ptr: dd 0

  [section .text]
;---------------------------------------------------------------------
; input: eax=buffer ptr
;
put_pop_dword_setup:
  mov	[dword_top_ptr],eax
  mov	[dword_put_ptr],eax
  ret
;-----------------------------------
; input: eax=put value
;
put_dword:
  push	ebx
  mov	ebx,[dword_put_ptr]
  mov	[ebx],eax
  add	ebx,byte 4
  mov	[dword_put_ptr],ebx
  pop	ebx
  ret
;-----------------------------------
; output: carry set if at top already
;         eax = value if no carry
pop_dword:
  push	esi
  mov	esi,[dword_put_ptr]
  cmp	esi,[dword_top_ptr]
  je	pd_error	;exit if at top
  sub	esi,4		;move to last push
  mov	eax,[esi]	;get last push
  mov	[dword_put_ptr],esi
  clc
  jmp	short pd_exit
pd_error:
  stc
pd_exit:
  pop	esi
  ret
  

;--------------
  [section .data]
dword_top_ptr: dd 0
dword_put_ptr: dd 0

  [section .text]
;--------------