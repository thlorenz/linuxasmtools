; mount  - function example

;only root can mount, 

  global _start
_start:
  mov	eax,21	;function# for mount 
  mov	ebx,device
  mov	ecx,mount_point
  mov	edx,0	;mount_type
  mov	esi,0	;mount_flags
  mov	edi,extra_data
  int	80h	;kernel call, returns process id

  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
device	db 'dummy_device',0
mount_point db 'mount_dir',0
extra_data  dd 0

  [section .text]


