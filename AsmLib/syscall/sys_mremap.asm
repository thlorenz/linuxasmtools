;--------------------------------------------------------------
;>1 syscall
; sys_mremap - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_mremap                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_mremap:                                       
;              mov  eax,163    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_mremap
sys_mremap:
	mov	eax,163
	int	byte 80h
	or	eax,eax
	ret