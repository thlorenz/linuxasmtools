; umount  - function example

;only root can umount, 

  global _start
_start:
  mov	eax,22	;function# for umount 
  mov	ebx,mount_point
  mov	ecx,0   ;umount flags
  int	80h	;kernel call, returns process id

  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
mount_point db 'mount_dir',0

  [section .text]


