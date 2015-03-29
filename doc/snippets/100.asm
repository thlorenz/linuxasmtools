; fstatfs example:


  global _start
_start:
  mov	eax,05		;open
  mov	ebx,path
  mov	ecx,0
  mov	edx,0
  int	80h
  mov	ebx,eax		;get fd

  mov	eax,100		;fstatfs kernel call
  mov	ecx,buffer
  int	80h		;statfs

  mov	eax,1
  int	80h
;----------
  [section .data] 
path	db '/',0

buffer:
f_type     dd 0 ;type of filesystem (see below) */
f_bsize    dd 0 ;optimal transfer block size */
f_blocks   dd 0 ;total data blocks in file system */
f_bfree    dd 0 ;free blocks in fs */
f_bavail   dd 0 ;free blocks avail to non-superuser */
f_files    dd 0 ;total file nodes in file system */
f_ffree    dd 0 ; free file nodes in fs */
f_fsid     dd 0 ; file system id */
f_namelen  dd 0 ; maximum length of filenames */

  [section .text]

