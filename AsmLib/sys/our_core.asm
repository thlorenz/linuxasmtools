  [section .text align=1]

;----------------------------------------------
dword_to_ascii:
  push	byte 10
  pop	ecx		;set ecx=10
dta_recurse:
  xor	edx,edx
  div	ecx
  push	edx
  or	eax,eax
  jz	dta_store
  call	dta_recurse
dta_store:
  pop	eax
  or	al,'0'
  stosb
  ret
;--------------------------------------
;------------------------------------------------
ascii_to_dword:
  xor	ecx,ecx
  xor	eax,eax
  mov	bl,9
  cld
atd_lp:
  lodsb
  sub al,'0'
  js atd_exit
  cmp al,bl
  ja atd_exit
  lea ecx,[ecx+4*ecx]
  lea ecx,[2*ecx+eax]
  jmp short atd_lp
atd_exit:
  ret

;----------------------------------------
;ecx=buffer  ebx=file  edx=buf size
read_all:
  push	ecx	;save buf
  push	edx	;save buf size
  mov	eax,5	;open
  xor	ecx,ecx
  xor	edx,edx
  int	byte 80h	;open file

  pop	edx		;get size
  pop	ecx		;get buffer
  mov	ebx,eax		;get fd
  mov	eax,3		;read
  int	byte 80h

  mov	eax,6
  int	byte 80h	;close
  ret

;----------------------------------------------
;---------------------------------------------------
;>1 sys  
;our_core - what cpu core are we running on
; INPUT
;   ebp = buffer of at least 799 bytes
; OUTPUT
;   eax = core number we are running on. (0=first)
; NOTE
;<
;---------------------------------------------------
;input: ebp = buffer of at least 799 bytes
;output: eax=core number we are running on
;
  global our_core
our_core:
  mov	eax,224
  int	byte 80h	;gettid
  mov	edi,proc_stat_stuff
  call	dword_to_ascii
  mov	esi,stat_append
  mov	ecx,6
  rep	movsb

  mov	ebx,proc_stat	;get filename
  mov	ecx,ebp
  mov	edx,799		;lib_buf size
  call	read_all
;find cpu entry
  mov	ecx,38
  mov	esi,ebp		;buffer

oc_loop:
  lodsb
  cmp	al,' '	;end of entry
  jne	oc_loop
  loop	oc_loop

  call	ascii_to_dword
  mov	eax,ecx  
  ret


;-------------------
  [section .data]
proc_stat: db '/proc/self/task/'
proc_stat_stuff: db '     '
stat_append: db '/stat',0
  [section .text]

;-----------------------------------------------

