
  global _start
_start:
  xor	ebx,ebx		;get code for stdin
  mov	ecx,5413h
  mov edx,rw_rows
  mov	eax,54
  int	80h

  mov	eax,1	;exit function#
  int	80h	;exit
  ret

;-------------------------------------------------------
  [section .data]
rw_rows: dw 0
rw_cols: dw 0;
	 dw 0,0
  [section .text]


;---


