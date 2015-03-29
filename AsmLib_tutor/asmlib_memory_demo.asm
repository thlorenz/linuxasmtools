  extern m_setup
  extern m_allocate
  extern m_release
  extern m_close
  extern sys_exit

  [section .text]

 global _start
_start:
  call	m_setup			;prepare memory manager
  mov	eax,[allocation_size]
  call	m_allocate		;allocate block of memory
  or	eax,eax			;eax=allocated address
  js	test_err1
  mov	[eax],byte 11h		;store data into memory
  mov	bl,[eax]		;read it to register
  call	m_release		;release memory (eax=address)
  call	m_close			;close memory manager
test_err1:
  call	sys_exit


;----------------------
  [section .data]
allocation_size:  dd  1096

;----------------------
  [section .bss]
our_bss_data:	resb	100
managed_memory: