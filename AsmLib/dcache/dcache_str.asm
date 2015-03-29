;---------------------------------------------------
;#1 dcache
; dcache_str - send string to display
; INPUT
;   ecx=string ptr
; OUTPUT
;   none
; NOTE
;#
;----------------------------------------------------
  extern sys_write
  extern dcache_fd
  global dcache_str
dcache_str:
  xor edx, edx
.count_again:	
  cmp [ecx + edx], byte 0x0
  je .done_count
  inc edx
  jmp .count_again
.done_count:	
  mov eax, 0x4			; system call 0x4 (write)
  mov ebx,[dcache_fd]		; file desc.
  int 0x80
  ret


