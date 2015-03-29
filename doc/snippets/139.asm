; setfsuid/setfsgid  - function example

  global _start
_start:
  mov	eax,24		;getuid
  int	80h
  mov	ebx,eax

  mov	eax,138		;setfsuid function
  int	80h

  mov	eax,47		;getgid
  int	80h
  mov	ebx,eax

  mov	eax,139		;setfsgid function
  int	80h

  mov	eax,1
  int	80h

;---
  [section .data]
  [section .text]


