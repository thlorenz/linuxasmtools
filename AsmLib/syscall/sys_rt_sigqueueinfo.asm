;--------------------------------------------------------------
;>1 syscall
; sys_rt_sigqueueinfo - kernel function                     
;
;    INPUTS 
;     see AsmRef function -> sys_rt_sigqueueinfo                                 
;
;    Note: functon call consists of four instructions
;          
;          sys_rt_sigqueueinfo:                              
;              mov  eax,178    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_rt_sigqueueinfo
sys_rt_sigqueueinfo:
	mov	eax,178
	int	byte 80h
	or	eax,eax
	ret