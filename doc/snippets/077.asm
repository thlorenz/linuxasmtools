; getrusage - function example

  global _start
_start:
  mov	eax,77	;getrusage function#
  mov	ebx,0	;self function
  mov	ecx,ut_sec
  int	80h

_exit:
  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]
ut_sec      dd 0 ; seconds
ut_usec     dd 0 ; microseconds
st_sec      dd 0 ; seconds
st_usec     dd 0 ; microseconds
ru_maxrss   dd 0 ; maximum resident set size
ru_ixrss    dd 0 ; integral shared memory size
ru_idrss    dd 0 ; integral unshared data size
ru_isrss    dd 0 ; integral unshared stack size
ru_minflt   dd 0 ; page reclaims
ru_majflt   dd 0 ; page faults
ru_nswap    dd 0 ; swaps
ru_inblock  dd 0 ; block input operations
ru_oublock  dd 0 ; block output operations
ru_msgsnd   dd 0 ; messages sent
ru_msgrcv   dd 0 ; messages received
ru_nsignals dd 0 ; signals received
ru_nvcsw    dd 0 ; voluntary context switches
ru_nivcsw   dd 0 ; involuntary context switches
  [section .text]


