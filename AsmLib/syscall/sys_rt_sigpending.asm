;--------------------------------------------------------------
;>1 syscall
; sys_rt_sigpending - kernel function                       
;
;    INPUTS 
;     see AsmRef function -> sys_rt_sigpending                                   
;
;    Note: functon call consists of four instructions
;          
;          sys_rt_sigpending:                                
;              mov  eax,176    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_rt_sigpending
sys_rt_sigpending:
	mov	eax,176
	int	byte 80h
	or	eax,eax
	ret