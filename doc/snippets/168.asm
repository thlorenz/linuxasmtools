; poll example:

;wait for key press

  global _start
_start:
  mov	eax,168		;poll function#
  mov	ebx,ufds_array	;ptr to array
  mov	ecx,1		;number of array elements
  mov	edx,3000	;timeout in milli seconds
  int	80h

  mov	eax,1
  int	80h

;-----------
  [section .data]
ufds_array:
  dd	0	;fd
  dw	1	;requested event
  dw	-1	;returned event
 
;------------
  [section .text]


