  extern sys_exit
  extern env_stack
  extern find_env_variable
  
;----------------------------------------------------
; This program demonstrates basic AsmLib functions
; to access parameters.
;
; compile with:
;  nasm -felf -g asmlib_parameters_demo.asm
;  ld asmlib_parameters_demo.o -o asmlib_parameters_demo /usr/lib/asmlib.a
;
;----------------------------------------------------
  [section .text]

  global _start
_start:
  call	env_stack	;save stack state
  mov	esi,esp		;get stack pointer
  lodsd			;get number of parameters
  mov	ecx,eax		;save parameter count
  lodsd			;get first parameters, this is always our program name
ploop:
  lodsd
  loop	ploop		;loop till all parameters read

  mov	ecx,term
  mov	edx,results
  call	find_env_variable
;look at memory variable "results" to find terminal name

  call	sys_exit	;all done
  
;--------------------------------------------------
  [section .data]
term	dd 'TERM',0
results times 20 db 0
;