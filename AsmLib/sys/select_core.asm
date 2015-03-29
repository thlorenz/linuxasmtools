
  [section .text align=1]

  extern sys_sched_setaffinity

;---------------------------------------------------
;>1 sys  
;select_core - select execution cpu core
; INPUT
;   eax = pid to assign a core
;   ebp = buffer of at least 128 bytes
; OUTPUT
;   output of sys_sched_afinity kernel call
; NOTE
;<
;---------------------------------------------------
;ebx=core# 0,1,2, etc.
;eax=pid
;ebp=buffer of at least 128 bytes
  global select_core
select_core:
  mov	[sc_pid],eax
;build mask
  mov	edx,1	;starting mask
  inc	ebx	;adjust ebx
sc_lp1:
  dec	ebx
  jz	sc_10	;jmp if flag built
  shr	edx,1
  jmp	short sc_lp1
sc_10:
;build mask, first clear the buffer
  mov	ecx,128
  xor	eax,eax
  mov	edi,ebp
  rep	stosb
  mov	[ebp],edx	;store mask
;setup for call
  mov	ecx,128		;length of mask
  mov	edx,ebp		;ptr to mask
;ebx=pid
  call	sys_sched_setaffinity
  ret


;-------------
  [section .data]

sc_pid	dd 0

