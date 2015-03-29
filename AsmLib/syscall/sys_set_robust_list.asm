;--------------------------------------------------------------
;>1 syscall
; sys_set_robust_list - kernel function                     
;
;    INPUTS 
;     see AsmRef function -> sys_set_robust_list                                 
;
;    Note: functon call consists of four instructions
;          
;          sys_set_robust_list:                              
;              mov  eax,311    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_set_robust_list
sys_set_robust_list:
	mov	eax,311
	int	byte 80h
	or	eax,eax
	ret