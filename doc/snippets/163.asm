; mremap example:


  global _start
_start:
  mov	ebx,mmap_parm
  mov	eax,90		;mmap, allocate memory
  int	80h

  mov	ebp,eax		;save memory address
  mov	[ebp],dword 12345678h ;modify memory

  mov	eax,163		;mremap
  mov	ebx,ebp		;old address
  mov	ecx,4096	;old range
  mov	edx,8128	;new range
  mov	esi,1		;flags
  mov	edi,0		;new address (0=assigned by kernel)
  int	80h

  mov	ebp,eax		;save new address
  mov	eax,[ebp]	;get 12345678
  mov	[ebp+8000],dword 12345678h
  mov	ebx,[ebp+8000]

  mov	eax,1
  int	80h

;-----------
  [section .data]
mmap_parm:
  dd	0	;start
mmap_len:
  dd	4096	;length, from stat
  dd	3	;prot (PROT_READ,PROT_WRITE)
  dd	22h	;flags (MAP_ANON) no backing file + PRIVATE
mmap_fd:
  dd	0	;fd (handle)
  dd	0	;offset

;----------
 
;------------
  [section .text]


