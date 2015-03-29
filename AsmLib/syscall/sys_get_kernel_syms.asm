;--------------------------------------------------------------
;>1 syscall
; sys_get_kernel_syms - kernel function                     
;
;    INPUTS 
;     see AsmRef function -> sys_get_kernel_syms                                 
;
;    Note: functon call consists of four instructions
;          
;          sys_get_kernel_syms:                              
;              mov  eax,130    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_get_kernel_syms
sys_get_kernel_syms:
	mov	eax,130
	int	byte 80h
	or	eax,eax
	ret