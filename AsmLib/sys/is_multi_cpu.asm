  [section .text align=1]
;---------------------------------------------------
;>1 sys  
;is_multi_cpu - is OS handling multi cpu's or cores
; INPUT
;   ebp = pointer to buffer of at least 800 bytes
; OUTPUT
;   ecx = core count (this cpu)
;   ebx = siblings (total cores in all cpu's)
; NOTE
;<
;---------------------------------------------------
;input ebp = pointer to buffer of at least 800 bytes
;output: ecx=core count (this cpu)    
;        ebx=siblings=total cpu count,includes cores
;
  global is_multi_cpu
is_multi_cpu:
  mov	ebx,proc_cpu	;get filename
  mov	ecx,ebp
  mov	edx,799		;buffer size
  call	read_all
; find siblings
  mov	eax,'sibl'
  mov	esi,ebp
  mov	edi,ebp
  add	edi,799
imc_lp1:
  inc	esi
  cmp	esi,edi		;buffer+799
  je	imc_error
  cmp	eax,[esi]	;match?
  jne	imc_lp1
  add	esi,4
  cmp	[esi],dword 'ings'
  jne	imc_lp1		;jmp if not found yet
;we have found 'siblings'
  add	esi,byte 7	;move past tab
  call	ascii_to_dword
  push	ecx		;save value
; find cores
  mov	eax,dword 'cpu '
  mov	esi,ebp
imc_lp2:
  inc	esi
  cmp	esi,edi		;buffer+799
  je	imc_error
  cmp	eax,[esi]	;match?
  jne	imc_lp2
  add	esi,4
  cmp	[esi],dword 'core'
  jne	imc_lp2		;jmp if not found yet
;we have found cores
  add	esi,byte 8	;move past tab
  call	ascii_to_dword  ;ecx=cores
  pop	eax		;get siblings
  clc
  jmp	short imc_exit
imc_error:
  stc
imc_exit:
  ret
  
  [section .data]
proc_cpu: db '/proc/cpuinfo',0
  [section .text]
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

