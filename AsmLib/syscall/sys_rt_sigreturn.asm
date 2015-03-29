;--------------------------------------------------------------
;>1 syscall
; sys_rt_sigreturn - kernel function                        
;
;    INPUTS 
;     see AsmRef function -> sys_rt_sigreturn                                    
;
;    Note: functon call consists of four instructions
;          
;          sys_rt_sigreturn:                                 
;              mov  eax,173    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_rt_sigreturn
sys_rt_sigreturn:
	mov	eax,173
	int	byte 80h
	or	eax,eax
	ret