;--------------------------------------------------------------
;>1 syscall
; sys_rt_sigtimedwait - kernel function                     
;
;    INPUTS 
;     see AsmRef function -> sys_rt_sigtimedwait                                 
;
;    Note: functon call consists of four instructions
;          
;          sys_rt_sigtimedwait:                              
;              mov  eax,177    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_rt_sigtimedwait
sys_rt_sigtimedwait:
	mov	eax,177
	int	byte 80h
	or	eax,eax
	ret