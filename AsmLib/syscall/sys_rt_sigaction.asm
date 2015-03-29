;--------------------------------------------------------------
;>1 syscall
; sys_rt_sigaction - kernel function                        
;
;    INPUTS 
;     see AsmRef function -> sys_rt_sigaction                                    
;
;    Note: functon call consists of four instructions
;          
;          sys_rt_sigaction:                                 
;              mov  eax,174    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_rt_sigaction
sys_rt_sigaction:
	mov	eax,174
	int	byte 80h
	or	eax,eax
	ret