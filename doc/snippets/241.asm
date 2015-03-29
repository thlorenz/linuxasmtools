;example program, reports number of cores, and switches core if possible
;
;compile with:
;   nasm -felf -g jeff.asm
;   ld jeff.o  -o jeff /usr/lib/asmlib.a

  extern sys_getpid
  extern sys_exit
  extern sys_sched_setaffinity
  extern delay
  extern stdout_str

 global _start
_start:
;find number of cores
  mov	ebp,buffer
  call	is_multi_cpu	;eax=cores, ebx=processors
;report number of cores
  push	eax
  mov	edi,num_core_stuf
  call	dword_to_ascii
  mov	ecx,num_cores_msg
  call	stdout_str
  pop	eax
  cmp	eax,1
  jbe	do_exit
;find our core #
  mov	ebp,buffer
  call	our_core
  push	eax		;save core 0+
;report our core #
  call	core		;report
;change our core # (affinity)
  call	sys_getpid	;get our pid in eax
  pop	ebx		;get current core#
  xor	ebx,1	;select alternate core
  mov	ebp,buffer
  call	select_core
;report core switched
  mov	ecx,switch_msg
  call	stdout_str
;delay
  mov	eax,20000
  call	delay
;find our core #
  mov	ebp,buffer
  call	our_core
;report changed core
  call	core
;exit
do_exit:
  call	sys_exit
;-----------------------------------
core:
  mov	edi,our_core_stuf
  call	dword_to_ascii
  mov	ecx,our_core_msg
  call	stdout_str
  ret
;---------------
  [section .data]
buffer	times	800 db 0
num_cores_msg  db 0ah,'This processor has '
num_core_stuf: db '   cores',0ah,0
our_core_msg:  db 'We are running on core '
our_core_stuf: db '    ',0ah,0

switch_msg:    db 'Using sched_setaffinity to switch core',0ah,0
  [section .text]  
;--------------------------------------
;input ebp = pointer to buffer of at least 800 bytes
;output: ecx=core count (this cpu)    
;        ebx=siblings=total cpu count,includes cores
;
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
;input: ebp = buffer of at least 799 bytes
;output: eax=core number we are running on
;
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
;ebx=core# 0,1,2, etc.
;eax=pid
;ebp=buffer of at least 128 bytes
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
