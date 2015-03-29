;--------------------------------------------------------------
;>1 syscall
; sys_get_robust_list - kernel function                     
;
;    INPUTS 
;     see AsmRef function -> sys_get_robust_list                                 
;
;    Note: functon call consists of four instructions
;          
;          sys_get_robust_list:                              
;              mov  eax,312    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_get_robust_list
sys_get_robust_list:
	mov	eax,312
	int	byte 80h
	or	eax,eax
	ret