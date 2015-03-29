; mmap example:


  global _start
_start:
  mov	ebx,filename
  xor	ecx, ecx
  xor	edx,edx
  mov	eax,5
  int	80h		;open file
  mov	ebx,eax		;get fd
  mov	ecx,fstat_buf	;get buffer
  mov	eax,108		;fstat
  int	80h
; An mmap structure is filled out and handed off to the system call,
; and the function returns.
;sys_mmap 0,dword [ecx + 20],PROT_READ,MAP_SHARED,ebx,0

  mov	[mmap_fd],ebx		;save fd (handle)
  mov	ecx,[ecx + 20]		;get length
  push	ecx
  mov	[mmap_len],ecx
  mov	ebx,mmap_parm
  mov	eax,90
  int	80h

  mov	eax,1
  int	80h

;-----------
  [section .data]
mmap_parm:
  dd	0	;start
mmap_len:
  dd	0	;length, from stat
  dd	1	;prot (PROT_READ)
  dd	1	;flags (MAP_SHARED)
mmap_fd:
  dd	0	;fd (handle)
  dd	0	;offset

;----------
 
filename: db 'test.asm',0
fstat_buf: times 200 db 0
;------------
  [section .text]


