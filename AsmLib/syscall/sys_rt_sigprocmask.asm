;--------------------------------------------------------------
;>1 syscall
; sys_rt_sigprocmask - kernel function                      
;
;    INPUTS 
;     see AsmRef function -> sys_rt_sigprocmask                                  
;
;    Note: functon call consists of four instructions
;          
;          sys_rt_sigprocmask:                               
;              mov  eax,175    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_rt_sigprocmask
sys_rt_sigprocmask:
	mov	eax,175
	int	byte 80h
	or	eax,eax
	ret